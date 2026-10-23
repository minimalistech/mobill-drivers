package com.mobilldriversprotocol;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCallback;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattDescriptor;
import android.bluetooth.BluetoothGattService;
import android.bluetooth.BluetoothManager;
import android.bluetooth.BluetoothProfile;
import android.bluetooth.le.BluetoothLeScanner;
import android.bluetooth.le.ScanCallback;
import android.bluetooth.le.ScanResult;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.SharedPreferences;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;

/**
 * CoolLEDU Bluetooth Manager
 * Extracted and simplified from CoolLED1248 Android BLE implementation
 * Copyright © JTKJ LED1248. All rights reserved.
 */
public class CoolLEDUBluetoothManager {
    private static final String TAG = "CoolLEDUBT";
    
    // CoolLEDU BLE Service and Characteristic UUIDs
    // IMPORTANT: iOS uses FFF1 for BOTH write AND notify (single bidirectional characteristic)
    // This matches the device's actual characteristic layout
    private static final String SERVICE_UUID = "0000fff0-0000-1000-8000-00805f9b34fb";
    private static final String CHARACTERISTIC_UUID = "0000fff1-0000-1000-8000-00805f9b34fb"; // Used for both write and notify
    private static final String CCCD_UUID = "00002902-0000-1000-8000-00805f9b34fb";

    // SharedPreferences keys for auto-reconnection (matching iOS kLastConnectedPeripheral)
    private static final String PREFS_NAME = "CoolLEDUBluetoothPrefs";
    private static final String PREF_LAST_CONNECTED_DEVICES = "lastConnectedDevices";

    // Auto-reconnection settings. The first attempt is a fast direct connect; after
    // that a background autoConnect request stays pending (no timeout) until the
    // display advertises again.
    private static final int FIRST_RECONNECT_DELAY_MS = 1000;
    private static final int RECONNECT_DELAY_MS = 2000;
    private static final int MAX_RECONNECT_DELAY_MS = 30000;
    // Service discovery + MTU + CCCD must finish within this time after the link is up
    private static final int SETUP_TIMEOUT_MS = 15000;
    
    private BluetoothManager bluetoothManager;
    private BluetoothAdapter bluetoothAdapter;
    private BluetoothLeScanner bluetoothLeScanner;
    private BluetoothGatt bluetoothGatt;
    private BluetoothGattCharacteristic writeCharacteristic;
    private BluetoothGattCharacteristic notifyCharacteristic;
    
    private Context context;
    private Handler mainHandler;
    private boolean isScanning = false;
    private boolean isConnected = false;
    private boolean mtuChangeCompleted = false;  // Track MTU negotiation completion
    private boolean cccdWriteCompleted = false;  // Track CCCD write completion

    private List<BluetoothDevice> discoveredDevices = new ArrayList<>();
    private CoolLEDUManagerCallback callback;
    private WriteCallback pendingWriteCallback;

    // Track if a BLE write operation is currently in flight
    // Android BLE only allows one writeCharacteristic at a time
    private volatile boolean isWriteInProgress = false;

    // Track if a connection attempt is currently in progress
    // This prevents duplicate GATT connections from auto-reconnect + manual connect race
    private volatile boolean isConnectionInProgress = false;

    // Queue for pending write operations
    private static class PendingWrite {
        byte[] data;
        WriteCallback callback;
        PendingWrite(byte[] data, WriteCallback callback) {
            this.data = data;
            this.callback = callback;
        }
    }
    private final java.util.Queue<PendingWrite> writeQueue = new java.util.LinkedList<>();

    // Auto-reconnection state
    private BluetoothDevice lastConnectedDevice;
    private int reconnectAttempts = 0;
    private boolean isReconnecting = false;
    private boolean userInitiatedDisconnect = false;  // Track if disconnect was user-initiated
    // True from an unexpected drop until reconnected or the user disconnects
    private volatile boolean autoReconnectActive = false;
    // Whether the pending GATT connect was made with autoConnect=true
    private boolean pendingConnectIsBackground = false;
    private final Runnable reconnectRunnable = this::runReconnect;
    private final Runnable setupWatchdog = this::onSetupTimeout;

    public interface CoolLEDUManagerCallback {
        void onDeviceDiscovered(BluetoothDevice device, int rssi);
        void onDeviceConnected(BluetoothDevice device);
        void onDeviceDisconnected(BluetoothDevice device, int status);
        void onDataReceived(byte[] data);
        void onError(String error);
    }

    public interface WriteCallback {
        void onWriteSuccess();
        void onWriteFailure(String error);
    }
    
    public CoolLEDUBluetoothManager(Context context, CoolLEDUManagerCallback callback) {
        this.context = context;
        this.callback = callback;
        this.mainHandler = new Handler(context.getMainLooper());
        
        bluetoothManager = (BluetoothManager) context.getSystemService(Context.BLUETOOTH_SERVICE);
        bluetoothAdapter = bluetoothManager.getAdapter();
        
        if (bluetoothAdapter != null) {
            bluetoothLeScanner = bluetoothAdapter.getBluetoothLeScanner();
        }

        IntentFilter filter = new IntentFilter(BluetoothAdapter.ACTION_STATE_CHANGED);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.registerReceiver(adapterStateReceiver, filter, Context.RECEIVER_NOT_EXPORTED);
        } else {
            context.registerReceiver(adapterStateReceiver, filter);
        }
    }

    /**
     * Bluetooth being switched off does not reliably deliver onConnectionStateChange,
     * so tear the link down here and resume reconnection when it comes back on.
     */
    private final BroadcastReceiver adapterStateReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context ctx, Intent intent) {
            int state = intent.getIntExtra(BluetoothAdapter.EXTRA_STATE, BluetoothAdapter.ERROR);
            if (state == BluetoothAdapter.STATE_TURNING_OFF || state == BluetoothAdapter.STATE_OFF) {
                mainHandler.post(() -> handleAdapterOff());
            } else if (state == BluetoothAdapter.STATE_ON) {
                mainHandler.post(() -> handleAdapterOn());
            }
        }
    };

    private void handleAdapterOff() {
        Log.w(TAG, "Bluetooth adapter turning off");
        mainHandler.removeCallbacks(reconnectRunnable);
        isScanning = false;
        boolean wasConnected = isConnected;
        BluetoothDevice device = bluetoothGatt != null ? bluetoothGatt.getDevice() : lastConnectedDevice;
        if (bluetoothGatt == null && !wasConnected) {
            return;
        }
        if (!userInitiatedDisconnect && lastConnectedDevice != null) {
            autoReconnectActive = true;
        }
        disconnectInternal();
        if (wasConnected && device != null) {
            callback.onDeviceDisconnected(device, -1);
        }
    }

    private void handleAdapterOn() {
        Log.d(TAG, "Bluetooth adapter on");
        bluetoothLeScanner = bluetoothAdapter.getBluetoothLeScanner();
        if (autoReconnectActive) {
            reconnectAttempts = 0;
            attemptReconnect();
        }
    }
    
    public boolean isBluetoothEnabled() {
        return bluetoothAdapter != null && bluetoothAdapter.isEnabled();
    }
    
    public void startScan() {
        if (!isBluetoothEnabled()) {
            callback.onError("Bluetooth not enabled");
            return;
        }
        
        if (isScanning) {
            return;
        }
        
        if (bluetoothLeScanner == null) {
            bluetoothLeScanner = bluetoothAdapter.getBluetoothLeScanner();
            if (bluetoothLeScanner == null) {
                callback.onError("BLE scanner unavailable");
                return;
            }
        }

        discoveredDevices.clear();
        isScanning = true;
        bluetoothLeScanner.startScan(scanCallback);
        Log.d(TAG, "Started BLE scan for CoolLEDU devices");
        
        // Stop scan after 10 seconds
        mainHandler.postDelayed(() -> stopScan(), 10000);
    }
    
    public void stopScan() {
        if (!isScanning) {
            return;
        }
        
        isScanning = false;
        if (bluetoothLeScanner != null) {
            bluetoothLeScanner.stopScan(scanCallback);
        }
        Log.d(TAG, "Stopped BLE scan");
    }
    
    public void connectToDevice(BluetoothDevice device) {
        connect(device, false);
    }

    /**
     * Connect to a device (internal method used by both manual and auto-connect)
     * Thread-safe - prevents duplicate GATT connections
     */
    private synchronized void connect(BluetoothDevice device, boolean background) {
        // Check if already connected to same device
        if (isConnected) {
            if (lastConnectedDevice != null && lastConnectedDevice.getAddress().equals(device.getAddress())) {
                Log.d(TAG, "Already connected to this device: " + device.getName());
                return;
            }
            // Disconnect from current device first
            disconnectInternal();
        }

        // Prevent duplicate connection attempts (race condition between auto-reconnect and manual connect)
        if (isConnectionInProgress) {
            Log.d(TAG, "⚠️ Connection already in progress, ignoring duplicate connect request to: " + device.getName());
            return;
        }

        // Mark connection as in progress
        isConnectionInProgress = true;

        // Reset state for new connection
        userInitiatedDisconnect = false;
        isReconnecting = false;

        pendingConnectIsBackground = background;
        Log.d(TAG, "Connecting to device: " + device.getName() + (background ? " (background autoConnect)" : ""));
        bluetoothGatt = device.connectGatt(context, background, gattCallback, BluetoothDevice.TRANSPORT_LE);
        if (bluetoothGatt == null) {
            Log.e(TAG, "connectGatt returned null");
            isConnectionInProgress = false;
            if (autoReconnectActive) {
                attemptReconnect();
            }
        }
    }
    
    /**
     * Disconnect from device (user-initiated)
     * This will NOT trigger auto-reconnection
     */
    public void disconnect() {
        userInitiatedDisconnect = true;
        autoReconnectActive = false;
        mainHandler.removeCallbacks(reconnectRunnable);
        disconnectInternal();
        // Remove from last connected devices when user explicitly disconnects
        if (lastConnectedDevice != null) {
            removeLastConnectedDevice(lastConnectedDevice.getAddress());
        }
    }

    /**
     * Internal disconnect method
     */
    private synchronized void disconnectInternal() {
        mainHandler.removeCallbacks(setupWatchdog);
        if (bluetoothGatt != null) {
            bluetoothGatt.disconnect();
            bluetoothGatt.close();
            bluetoothGatt = null;
        }
        isConnected = false;
        isConnectionInProgress = false;  // Reset connection in progress flag
        mtuChangeCompleted = false;
        cccdWriteCompleted = false;
        writeCharacteristic = null;
        notifyCharacteristic = null;
        // Clear write state on disconnect
        isWriteInProgress = false;
        writeQueue.clear();
        isReconnecting = false;
    }

    // ============================================================================
    // Auto-Reconnection Logic (matching iOS kLastConnectedPeripheral behavior)
    // ============================================================================

    /**
     * Save device address to last connected devices list
     * Called when connection is fully established
     */
    private void saveLastConnectedDevice(String deviceAddress) {
        SharedPreferences prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
        Set<String> devices = prefs.getStringSet(PREF_LAST_CONNECTED_DEVICES, new HashSet<>());
        Set<String> updatedDevices = new HashSet<>(devices);
        updatedDevices.add(deviceAddress);
        prefs.edit().putStringSet(PREF_LAST_CONNECTED_DEVICES, updatedDevices).apply();
        Log.d(TAG, "📝 Saved device to last connected list: " + deviceAddress);
    }

    /**
     * Remove device address from last connected devices list
     * Called when user explicitly disconnects
     */
    private void removeLastConnectedDevice(String deviceAddress) {
        SharedPreferences prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
        Set<String> devices = prefs.getStringSet(PREF_LAST_CONNECTED_DEVICES, new HashSet<>());
        Set<String> updatedDevices = new HashSet<>(devices);
        updatedDevices.remove(deviceAddress);
        prefs.edit().putStringSet(PREF_LAST_CONNECTED_DEVICES, updatedDevices).apply();
        Log.d(TAG, "📝 Removed device from last connected list: " + deviceAddress);
    }

    /**
     * Check if device is in last connected list (for auto-reconnect during scan)
     */
    private boolean isLastConnectedDevice(String deviceAddress) {
        SharedPreferences prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
        Set<String> devices = prefs.getStringSet(PREF_LAST_CONNECTED_DEVICES, new HashSet<>());
        return devices.contains(deviceAddress);
    }

    /**
     * Attempt to reconnect to the last connected device.
     * Keeps trying until reconnected or the user disconnects: the first attempt is a
     * direct connect, later ones a background autoConnect that never times out.
     */
    private void attemptReconnect() {
        if (lastConnectedDevice == null || userInitiatedDisconnect || !autoReconnectActive) {
            Log.d(TAG, "🔄 Skipping reconnect: " +
                  (lastConnectedDevice == null ? "no last device" : "user-initiated disconnect or not reconnecting"));
            return;
        }

        if (isConnected || isConnectionInProgress) {
            return;
        }

        if (!isBluetoothEnabled()) {
            // Resumed by handleAdapterOn()
            Log.d(TAG, "🔄 Bluetooth off, waiting for it to come back before reconnecting");
            return;
        }

        isReconnecting = true;
        reconnectAttempts++;

        // Back off when attempts fail immediately (e.g. repeated status 133)
        int delay = reconnectAttempts == 1
            ? FIRST_RECONNECT_DELAY_MS
            : Math.min(RECONNECT_DELAY_MS * (reconnectAttempts - 1), MAX_RECONNECT_DELAY_MS);
        Log.d(TAG, "🔄 Attempting reconnect #" + reconnectAttempts + " in " + delay + "ms to " + lastConnectedDevice.getName());

        mainHandler.removeCallbacks(reconnectRunnable);
        mainHandler.postDelayed(reconnectRunnable, delay);
    }

    private void runReconnect() {
        isReconnecting = false;
        if (!isConnected && !userInitiatedDisconnect && autoReconnectActive && lastConnectedDevice != null) {
            Log.d(TAG, "🔄 Reconnecting to: " + lastConnectedDevice.getName());
            connect(lastConnectedDevice, reconnectAttempts > 1);
        }
    }

    /**
     * The link came up but setup (services, MTU, CCCD) never completed. Without this
     * isConnectionInProgress stays true and blocks every later connect.
     */
    private void onSetupTimeout() {
        if (isConnected || bluetoothGatt == null) {
            return;
        }
        Log.w(TAG, "⏱️ Connection setup timed out, resetting GATT");
        failConnectionSetup();
    }

    private synchronized void failConnectionSetup() {
        boolean wasReconnecting = autoReconnectActive;
        disconnectInternal();
        if (wasReconnecting) {
            attemptReconnect();
        } else {
            callback.onError("Connection setup failed");
        }
    }

    /**
     * Clear all last connected devices
     * Can be called to reset auto-reconnect state
     */
    public void clearLastConnectedDevices() {
        SharedPreferences prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
        prefs.edit().remove(PREF_LAST_CONNECTED_DEVICES).apply();
        Log.d(TAG, "📝 Cleared all last connected devices");
    }

    /**
     * Check if both MTU change and CCCD write are complete, and mark device as connected
     */
    private synchronized void checkAndMarkConnected(BluetoothGatt gatt) {
        Log.d(TAG, "checkAndMarkConnected: mtuChangeCompleted=" + mtuChangeCompleted +
              ", cccdWriteCompleted=" + cccdWriteCompleted + ", isConnected=" + isConnected);
        if (mtuChangeCompleted && cccdWriteCompleted && !isConnected && writeCharacteristic != null) {
            isConnected = true;
            isConnectionInProgress = false;  // Connection complete
            isReconnecting = false;
            reconnectAttempts = 0;
            autoReconnectActive = false;
            mainHandler.removeCallbacks(setupWatchdog);
            userInitiatedDisconnect = false;  // Reset for future disconnects
            lastConnectedDevice = gatt.getDevice();

            // Save to last connected devices list (like iOS kLastConnectedPeripheral)
            saveLastConnectedDevice(gatt.getDevice().getAddress());

            Log.d(TAG, "✅ Device fully connected and ready for communication");
            callback.onDeviceConnected(gatt.getDevice());
        }
    }
    
    public boolean writeData(byte[] data) {
        if (!isConnected || writeCharacteristic == null || bluetoothGatt == null) {
            Log.e(TAG, "Not connected or write characteristic not available. isConnected=" + isConnected +
                  ", writeChar=" + (writeCharacteristic != null) + ", gatt=" + (bluetoothGatt != null));
            return false;
        }

        // Check characteristic properties and use appropriate write type
        int properties = writeCharacteristic.getProperties();
        Log.d(TAG, "Characteristic properties: " + properties + " (WRITE=" + BluetoothGattCharacteristic.PROPERTY_WRITE +
              ", WRITE_NO_RESPONSE=" + BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE + ")");

        if ((properties & BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE) != 0) {
            writeCharacteristic.setWriteType(BluetoothGattCharacteristic.WRITE_TYPE_NO_RESPONSE);
            Log.d(TAG, "Using WRITE_TYPE_NO_RESPONSE");
        } else if ((properties & BluetoothGattCharacteristic.PROPERTY_WRITE) != 0) {
            writeCharacteristic.setWriteType(BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT);
            Log.d(TAG, "Using WRITE_TYPE_DEFAULT");
        } else {
            Log.e(TAG, "Characteristic doesn't support any write type!");
            return false;
        }

        writeCharacteristic.setValue(data);
        boolean result = bluetoothGatt.writeCharacteristic(writeCharacteristic);
        Log.d(TAG, "Write data result: " + result + ", length: " + data.length);
        return result;
    }

    /**
     * Write data with callback
     * Chunks large data into BLE-compatible packets
     * iOS uses 360 hex chars = 180 bytes per chunk with 10ms delay
     */
    public void write(byte[] data, WriteCallback writeCallback) {
        // The write queue and chunk state are only touched on the main thread; callers
        // include a worker thread and Binder threads (notification handlers)
        if (Looper.myLooper() != Looper.getMainLooper()) {
            mainHandler.post(() -> write(data, writeCallback));
            return;
        }

        if (!isConnected || writeCharacteristic == null) {
            Log.e(TAG, "Not connected or write characteristic not available");
            if (writeCallback != null) {
                writeCallback.onWriteFailure("Not connected or write characteristic not available");
            }
            return;
        }

        // If a write is already in progress, queue this write for later
        if (isWriteInProgress) {
            Log.d(TAG, "⏳ Write in progress, queuing " + data.length + " bytes (queue size: " + writeQueue.size() + ")");
            writeQueue.add(new PendingWrite(data, writeCallback));
            return;
        }

        // Mark write as in progress
        isWriteInProgress = true;
        executeWrite(data, writeCallback);
    }

    /**
     * Process the next queued write if any
     */
    private void processNextQueuedWrite() {
        PendingWrite next = writeQueue.poll();
        if (next != null) {
            Log.d(TAG, "📤 Processing queued write: " + next.data.length + " bytes (remaining in queue: " + writeQueue.size() + ")");
            isWriteInProgress = true;
            executeWrite(next.data, next.callback);
        } else {
            Log.d(TAG, "✅ Write queue empty, marking write complete");
            isWriteInProgress = false;
        }
    }

    /**
     * Actually execute a write operation
     */
    private void executeWrite(byte[] data, WriteCallback writeCallback) {
        // Match iOS chunk size: 360 hex chars = 180 bytes per chunk
        // Note: If MTU negotiation fails, Android may fall back to 20-byte chunks
        final int CHUNK_SIZE = 180;

        if (data.length <= CHUNK_SIZE) {
            // Data fits in single packet - use normal write callback
            Log.d(TAG, "🔹 Single packet mode: " + data.length + " bytes");
            this.pendingWriteCallback = writeCallback;
            this.chunkingCallback = null;  // Not chunking
            this.chunks = null;

            // Check characteristic properties and use appropriate write type
            int properties = writeCharacteristic.getProperties();
            Log.d(TAG, "Characteristic properties: " + properties + " (WRITE=" + BluetoothGattCharacteristic.PROPERTY_WRITE +
                  ", WRITE_NO_RESPONSE=" + BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE + ")");

            if ((properties & BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE) != 0) {
                writeCharacteristic.setWriteType(BluetoothGattCharacteristic.WRITE_TYPE_NO_RESPONSE);
                Log.d(TAG, "Using WRITE_TYPE_NO_RESPONSE");
            } else if ((properties & BluetoothGattCharacteristic.PROPERTY_WRITE) != 0) {
                writeCharacteristic.setWriteType(BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT);
                Log.d(TAG, "Using WRITE_TYPE_DEFAULT");
            } else {
                Log.e(TAG, "Characteristic doesn't support any write type!");
                if (writeCallback != null) {
                    writeCallback.onWriteFailure("Characteristic doesn't support write operations");
                }
                isWriteInProgress = false;
                processNextQueuedWrite();
                return;
            }

            writeCharacteristic.setValue(data);
            boolean result = bluetoothGatt.writeCharacteristic(writeCharacteristic);
            Log.d(TAG, "Write data initiated: " + result + ", length: " + data.length);

            if (!result) {
                if (writeCallback != null) {
                    writeCallback.onWriteFailure("Failed to initiate write");
                }
                this.pendingWriteCallback = null;
                isWriteInProgress = false;
                processNextQueuedWrite();
            }
        } else {
            // Need to chunk data - use chunking callback
            Log.d(TAG, "📦 Chunking mode: " + data.length + " bytes into " + CHUNK_SIZE + "-byte packets");
            this.pendingWriteCallback = null;  // Clear normal callback
            this.chunkingCallback = null;  // Will be set by writeDataInChunks
            this.chunks = null;
            writeDataInChunks(data, CHUNK_SIZE, writeCallback);
        }
    }

    private int currentChunkIndex = 0;
    private byte[][] chunks;
    private WriteCallback chunkingCallback;
    private int chunkingSessionId = 0;  // Incremented for each new chunking session

    private void writeDataInChunks(final byte[] data, final int chunkSize, final WriteCallback finalCallback) {
        final int totalChunks = (int) Math.ceil((double) data.length / chunkSize);

        // Increment session ID to invalidate any pending callbacks from previous session
        chunkingSessionId++;
        final int thisSessionId = chunkingSessionId;

        Log.d(TAG, "📊 writeDataInChunks: sessionId=" + thisSessionId + " totalChunks = " + totalChunks + " (" + data.length + " bytes / " + chunkSize + " per chunk)");
        chunks = new byte[totalChunks][];

        // Split data into chunks
        for (int i = 0; i < totalChunks; i++) {
            final int start = i * chunkSize;
            final int end = Math.min(start + chunkSize, data.length);
            chunks[i] = new byte[end - start];
            System.arraycopy(data, start, chunks[i], 0, chunks[i].length);
        }
        Log.d(TAG, "📊 Chunks array created with " + chunks.length + " chunks");

        currentChunkIndex = 0;
        chunkingCallback = finalCallback;
        Log.d(TAG, "📊 Set chunkingCallback: " + (chunkingCallback != null) + ", starting write of first chunk...");

        // Start writing first chunk
        writeNextChunk();
    }

    private void writeNextChunk() {
        Log.d(TAG, "📝 writeNextChunk called - currentChunkIndex: " + currentChunkIndex +
              "/" + (chunks != null ? chunks.length : "null") +
              ", chunkingCallback: " + (chunkingCallback != null));

        if (chunks == null) {
            Log.e(TAG, "❌ writeNextChunk called but chunks is null!");
            isWriteInProgress = false;
            processNextQueuedWrite();
            return;
        }

        if (currentChunkIndex >= chunks.length) {
            // All chunks sent - this shouldn't happen as callback handles completion
            Log.w(TAG, "⚠️ writeNextChunk called after all chunks sent! currentChunkIndex: " + currentChunkIndex);
            return;
        }

        byte[] chunk = chunks[currentChunkIndex];
        Log.d(TAG, "📤 Writing chunk " + currentChunkIndex + "/" + chunks.length + ", size: " + chunk.length + " bytes");

        // Check characteristic properties and use appropriate write type
        int properties = writeCharacteristic.getProperties();
        if ((properties & BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE) != 0) {
            writeCharacteristic.setWriteType(BluetoothGattCharacteristic.WRITE_TYPE_NO_RESPONSE);
        } else if ((properties & BluetoothGattCharacteristic.PROPERTY_WRITE) != 0) {
            writeCharacteristic.setWriteType(BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT);
        }

        writeCharacteristic.setValue(chunk);
        boolean result = bluetoothGatt.writeCharacteristic(writeCharacteristic);
        Log.d(TAG, "📤 writeCharacteristic returned: " + result);

        if (!result) {
            Log.e(TAG, "❌ Failed to initiate write for chunk " + currentChunkIndex);
            if (chunkingCallback != null) {
                chunkingCallback.onWriteFailure("Failed to write chunk " + currentChunkIndex);
                chunkingCallback = null;
            }
            chunks = null;
            // Without this every later write queues behind a write that never completes
            isWriteInProgress = false;
            processNextQueuedWrite();
        }
        // onCharacteristicWrite callback will call writeNextChunk() for next chunk
    }
    
    public boolean writeCommand(String hexCommand) {
        if (hexCommand == null || hexCommand.length() % 2 != 0) {
            Log.e(TAG, "Invalid hex command: " + hexCommand);
            return false;
        }
        
        if (!isConnected || writeCharacteristic == null) {
            return false;
        }

        // Go through the write queue so commands never interleave with a chunked transfer
        byte[] data = hexStringToByteArray(hexCommand);
        write(data, new WriteCallback() {
            @Override
            public void onWriteSuccess() {
            }

            @Override
            public void onWriteFailure(String error) {
                Log.e(TAG, "Command write failed: " + error);
            }
        });
        return true;
    }
    
    private final ScanCallback scanCallback = new ScanCallback() {
        @Override
        public void onScanResult(int callbackType, ScanResult result) {
            BluetoothDevice device = result.getDevice();
            String deviceName = device.getName();

            // Filter for mobill/CoolLEDU devices
            if (deviceName != null && (deviceName.toLowerCase().contains("mobill") ||
                                     deviceName.toLowerCase().contains("coollled") ||
                                     deviceName.toLowerCase().contains("led"))) {

                if (!discoveredDevices.contains(device)) {
                    discoveredDevices.add(device);
                    callback.onDeviceDiscovered(device, result.getRssi());
                    Log.d(TAG, "Discovered device: " + deviceName + " RSSI: " + result.getRssi());

                    // Auto-connect to previously connected devices (like iOS kLastConnectedPeripheral)
                    // This matches iOS behavior in centralManager:didDiscoverPeripheral:
                    // A background autoConnect can be slow to fire; once a scan sees the
                    // display, replace it with a direct connect
                    if (!isConnected && autoReconnectActive && isConnectionInProgress && pendingConnectIsBackground
                            && lastConnectedDevice != null && lastConnectedDevice.getAddress().equals(device.getAddress())) {
                        Log.d(TAG, "🔄 Saw " + deviceName + " during background reconnect, switching to direct connect");
                        mainHandler.post(() -> {
                            if (!isConnected && pendingConnectIsBackground) {
                                disconnectInternal();
                                connect(device, false);
                            }
                        });
                        return;
                    }
                    if (!isConnected && !isReconnecting && !isConnectionInProgress && isLastConnectedDevice(device.getAddress())) {
                        Log.d(TAG, "🔄 Auto-connecting to previously connected device: " + deviceName);
                        mainHandler.post(new Runnable() {
                            @Override
                            public void run() {
                                // connect() is now synchronized and will check isConnectionInProgress
                                connect(device, false);
                            }
                        });
                    }
                }
            }
        }

        @Override
        public void onScanFailed(int errorCode) {
            callback.onError("Scan failed with error: " + errorCode);
            isScanning = false;
        }
    };
    
    private final BluetoothGattCallback gattCallback = new BluetoothGattCallback() {
        @Override
        public void onConnectionStateChange(BluetoothGatt gatt, int status, int newState) {
            if (gatt != bluetoothGatt) {
                // Callback from a GATT client we already closed
                Log.d(TAG, "Ignoring state change from stale GATT (newState=" + newState + ", status=" + status + ")");
                gatt.close();
                return;
            }
            if (newState == BluetoothProfile.STATE_CONNECTED) {
                Log.d(TAG, "Connected to GATT server, discovering services...");
                mainHandler.removeCallbacks(setupWatchdog);
                mainHandler.postDelayed(setupWatchdog, SETUP_TIMEOUT_MS);
                // Don't set isConnected or notify callback yet - wait for service discovery
                gatt.discoverServices();
            } else if (newState == BluetoothProfile.STATE_DISCONNECTED) {
                BluetoothDevice device = gatt.getDevice();
                boolean wasConnected = isConnected;
                boolean wasConnectionInProgress = isConnectionInProgress;
                Log.d(TAG, "Disconnected from GATT server (wasConnected=" + wasConnected +
                      ", wasConnectionInProgress=" + wasConnectionInProgress +
                      ", userInitiated=" + userInitiatedDisconnect + ", status=" + status + ")");

                // Reset connection state
                mainHandler.removeCallbacks(setupWatchdog);
                isConnected = false;
                isConnectionInProgress = false;  // Reset connection in progress flag
                mtuChangeCompleted = false;
                cccdWriteCompleted = false;
                writeCharacteristic = null;
                notifyCharacteristic = null;
                isWriteInProgress = false;
                writeQueue.clear();

                // Close the GATT connection
                gatt.close();
                bluetoothGatt = null;

                // Only notify callback if we were actually connected (not during failed connection attempt)
                if (wasConnected) {
                    callback.onDeviceDisconnected(device, status);
                }

                // Attempt auto-reconnect after an unexpected drop, and keep retrying
                // when a reconnect attempt itself fails (status 133, timeout)
                if (!userInitiatedDisconnect && (wasConnected || autoReconnectActive)) {
                    Log.d(TAG, "🔄 Unexpected disconnect detected, will attempt auto-reconnect");
                    if (wasConnected) {
                        lastConnectedDevice = device;
                        reconnectAttempts = 0;
                    }
                    autoReconnectActive = true;
                    attemptReconnect();
                }
            }
        }
        
        @Override
        public void onServicesDiscovered(BluetoothGatt gatt, int status) {
            if (status == BluetoothGatt.GATT_SUCCESS) {
                BluetoothGattService service = gatt.getService(UUID.fromString(SERVICE_UUID));
                if (service != null) {
                    // Use FFF1 for BOTH write AND notify (matching iOS implementation)
                    // CoolLEDU devices use a single bidirectional characteristic
                    BluetoothGattCharacteristic characteristic = service.getCharacteristic(UUID.fromString(CHARACTERISTIC_UUID));

                    if (characteristic != null) {
                        writeCharacteristic = characteristic;
                        notifyCharacteristic = characteristic;  // Same characteristic for both

                        Log.d(TAG, "✅ Using FFF1 for both write and notify (matching iOS)");

                        // Enable local notifications first (this is local-only, doesn't require BLE operation)
                        boolean localNotifySuccess = gatt.setCharacteristicNotification(notifyCharacteristic, true);
                        Log.d(TAG, "Local notifications enabled on FFF1: " + localNotifySuccess);

                        // IMPORTANT: Android BLE requires sequential operations
                        // Step 1: Request MTU (onMtuChanged will be called when done)
                        // Step 2: Write CCCD (will be done in onMtuChanged)
                        // Step 3: Mark connected (will be done in onDescriptorWrite)
                        Log.d(TAG, "🔄 Requesting MTU 185...");
                        gatt.requestMtu(185);
                    } else {
                        Log.e(TAG, "FFF1 characteristic not found!");
                        callback.onError("CoolLEDU characteristic not found");
                        mainHandler.post(() -> failConnectionSetup());
                    }

                    Log.d(TAG, "CoolLEDU service characteristics ready");
                } else {
                    callback.onError("CoolLEDU service not found");
                    mainHandler.post(() -> failConnectionSetup());
                }
            } else {
                Log.e(TAG, "Service discovery failed with status: " + status);
                mainHandler.post(() -> failConnectionSetup());
            }
        }

        @Override
        public void onMtuChanged(BluetoothGatt gatt, int mtu, int status) {
            if (status == BluetoothGatt.GATT_SUCCESS) {
                Log.d(TAG, "✅ MTU changed to: " + mtu);
            } else {
                Log.w(TAG, "MTU change failed, using default MTU");
            }
            mtuChangeCompleted = true;

            // Step 2: Now that MTU is done, write to CCCD
            if (notifyCharacteristic != null) {
                BluetoothGattDescriptor descriptor = notifyCharacteristic.getDescriptor(
                    UUID.fromString(CCCD_UUID)
                );
                Log.d(TAG, "CCCD descriptor found: " + (descriptor != null));
                if (descriptor != null) {
                    descriptor.setValue(BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE);
                    boolean success = gatt.writeDescriptor(descriptor);
                    Log.d(TAG, "🔄 CCCD write initiated: " + success);

                    // Some devices don't trigger onDescriptorWrite callback
                    // Add a fallback delay to mark as connected
                    if (success) {
                        mainHandler.postDelayed(() -> {
                            if (!cccdWriteCompleted && writeCharacteristic != null) {
                                cccdWriteCompleted = true;
                                Log.d(TAG, "✅ CCCD write completed (fallback timer)");
                                checkAndMarkConnected(gatt);
                            }
                        }, 1000); // 1 second fallback
                    } else {
                        // CCCD write failed to initiate, mark as done anyway
                        Log.w(TAG, "CCCD write failed to initiate, marking as done");
                        cccdWriteCompleted = true;
                        checkAndMarkConnected(gatt);
                    }
                } else {
                    Log.w(TAG, "CCCD descriptor not found - marking CCCD as done");
                    cccdWriteCompleted = true;
                    checkAndMarkConnected(gatt);
                }
            } else {
                Log.w(TAG, "notifyCharacteristic is null in onMtuChanged");
                cccdWriteCompleted = true;
                checkAndMarkConnected(gatt);
            }
        }
        
        @Override
        public void onCharacteristicChanged(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic) {
            byte[] data = characteristic.getValue();
            Log.d(TAG, "Notification received: " + bytesToHex(data));
            callback.onDataReceived(data);
        }

        @Override
        public void onDescriptorWrite(BluetoothGatt gatt, BluetoothGattDescriptor descriptor, int status) {
            if (status == BluetoothGatt.GATT_SUCCESS) {
                Log.d(TAG, "CCCD descriptor write successful - notifications enabled");
            } else {
                Log.e(TAG, "CCCD descriptor write failed with status: " + status);
            }
            // CCCD write is complete (whether success or failure)
            cccdWriteCompleted = true;
            checkAndMarkConnected(gatt);
        }
        
        @Override
        public void onCharacteristicWrite(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic, int status) {
            // Delivered on a Binder thread; handle on main with the rest of the write state
            if (Looper.myLooper() != Looper.getMainLooper()) {
                mainHandler.post(() -> onCharacteristicWrite(gatt, characteristic, status));
                return;
            }
            // Capture session ID at callback time to detect stale callbacks
            final int callbackSessionId = chunkingSessionId;

            if (status == BluetoothGatt.GATT_SUCCESS) {
                Log.d(TAG, "✅ Characteristic write successful - sessionId: " + callbackSessionId +
                      ", chunks: " + (chunks != null) +
                      ", currentChunkIndex: " + currentChunkIndex +
                      ", total chunks: " + (chunks != null ? chunks.length : 0) +
                      ", pendingWriteCallback: " + (pendingWriteCallback != null) +
                      ", chunkingCallback: " + (chunkingCallback != null));

                // Check if we're in chunking mode AND this callback belongs to current session
                if (chunks != null && chunkingCallback != null && callbackSessionId == chunkingSessionId) {
                    currentChunkIndex++;
                    Log.d(TAG, "📦 Incremented chunk index to " + currentChunkIndex + "/" + chunks.length);

                    if (currentChunkIndex < chunks.length) {
                        // More chunks to write - use 10ms delay to match iOS
                        Log.d(TAG, "⏰ Scheduling next chunk write with 10ms delay (matching iOS)");
                        mainHandler.postDelayed(new Runnable() {
                            @Override
                            public void run() {
                                // Double-check session ID before writing next chunk
                                if (callbackSessionId == chunkingSessionId) {
                                    Log.d(TAG, "⏰ Handler fired, calling writeNextChunk()");
                                    writeNextChunk();
                                } else {
                                    Log.w(TAG, "⚠️ Stale handler callback, session changed: " + callbackSessionId + " -> " + chunkingSessionId);
                                }
                            }
                        }, 10);
                    } else {
                        // All chunks completed for this session
                        Log.d(TAG, "🎉 All chunks sent for session " + callbackSessionId + " (current session: " + chunkingSessionId + ")");
                        // Clear the session before calling back so a later write
                        // completion can't re-enter this branch and fire it again
                        WriteCallback completedCallback = chunkingCallback;
                        chunkingCallback = null;
                        chunks = null;
                        if (completedCallback != null) {
                            completedCallback.onWriteSuccess();
                            Log.d(TAG, "✅ Called chunkingCallback.onWriteSuccess() for session " + callbackSessionId);
                        }
                        // Process next queued write
                        isWriteInProgress = false;
                        processNextQueuedWrite();
                    }
                } else if (pendingWriteCallback != null && chunks == null) {
                    // Single packet write completed
                    Log.d(TAG, "✅ Single write completed, calling pendingWriteCallback.onWriteSuccess()");
                    pendingWriteCallback.onWriteSuccess();
                    pendingWriteCallback = null;
                    // Process next queued write
                    isWriteInProgress = false;
                    processNextQueuedWrite();
                } else {
                    if (callbackSessionId != chunkingSessionId) {
                        Log.w(TAG, "⚠️ Stale callback from old session: " + callbackSessionId + " (current: " + chunkingSessionId + ")");
                    } else {
                        Log.w(TAG, "⚠️ Write successful but no callback to call! chunks: " + (chunks != null) +
                              ", currentChunkIndex: " + currentChunkIndex);
                    }
                }
            } else {
                Log.e(TAG, "❌ Characteristic write failed with status: " + status);
                if (chunks != null && chunkingCallback != null && callbackSessionId == chunkingSessionId) {
                    // Chunking failed for current session
                    chunkingCallback.onWriteFailure("Write failed with status: " + status);
                    chunkingCallback = null;
                    chunks = null;
                    // Process next queued write on failure too
                    isWriteInProgress = false;
                    processNextQueuedWrite();
                } else if (pendingWriteCallback != null) {
                    pendingWriteCallback.onWriteFailure("Write failed with status: " + status);
                    pendingWriteCallback = null;
                    // Process next queued write on failure too
                    isWriteInProgress = false;
                    processNextQueuedWrite();
                }
            }
        }
    };
    
    private byte[] hexStringToByteArray(String hex) {
        int len = hex.length();
        byte[] data = new byte[len / 2];
        for (int i = 0; i < len; i += 2) {
            data[i / 2] = (byte) ((Character.digit(hex.charAt(i), 16) << 4)
                                 + Character.digit(hex.charAt(i+1), 16));
        }
        return data;
    }

    private String bytesToHex(byte[] bytes) {
        StringBuilder sb = new StringBuilder();
        for (byte b : bytes) {
            sb.append(String.format("%02X", b));
        }
        return sb.toString();
    }
    
    public void cleanup() {
        stopScan();
        disconnect();
        unregisterAdapterReceiver();
    }

    /**
     * Close the GATT client without forgetting the saved device, so a new
     * instance (e.g. after a React Native reload) can auto-reconnect to it.
     */
    public void release() {
        stopScan();
        userInitiatedDisconnect = true;
        autoReconnectActive = false;
        mainHandler.removeCallbacks(reconnectRunnable);
        disconnectInternal();
        unregisterAdapterReceiver();
    }

    private void unregisterAdapterReceiver() {
        try {
            context.unregisterReceiver(adapterStateReceiver);
        } catch (IllegalArgumentException e) {
            // Already unregistered
        }
    }
}