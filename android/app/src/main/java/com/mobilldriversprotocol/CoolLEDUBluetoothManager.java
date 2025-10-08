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
import android.content.Context;
import android.os.Handler;
import android.util.Log;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * CoolLEDU Bluetooth Manager
 * Extracted and simplified from CoolLED1248 Android BLE implementation
 * Copyright © JTKJ LED1248. All rights reserved.
 */
public class CoolLEDUBluetoothManager {
    private static final String TAG = "CoolLEDUBT";
    
    // CoolLEDU BLE Service and Characteristic UUIDs (based on protocol analysis)
    private static final String SERVICE_UUID = "0000fff0-0000-1000-8000-00805f9b34fb";
    private static final String CHARACTERISTIC_WRITE_UUID = "0000fff1-0000-1000-8000-00805f9b34fb";
    private static final String CHARACTERISTIC_NOTIFY_UUID = "0000fff2-0000-1000-8000-00805f9b34fb";
    
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
    
    private List<BluetoothDevice> discoveredDevices = new ArrayList<>();
    private CoolLEDUManagerCallback callback;
    
    public interface CoolLEDUManagerCallback {
        void onDeviceDiscovered(BluetoothDevice device, int rssi);
        void onDeviceConnected(BluetoothDevice device);
        void onDeviceDisconnected(BluetoothDevice device);
        void onDataReceived(byte[] data);
        void onError(String error);
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
        if (isConnected) {
            disconnect();
        }
        
        Log.d(TAG, "Connecting to device: " + device.getName());
        bluetoothGatt = device.connectGatt(context, false, gattCallback);
    }
    
    public void disconnect() {
        if (bluetoothGatt != null) {
            bluetoothGatt.disconnect();
            bluetoothGatt.close();
            bluetoothGatt = null;
        }
        isConnected = false;
        writeCharacteristic = null;
        notifyCharacteristic = null;
    }
    
    public boolean writeData(byte[] data) {
        if (!isConnected || writeCharacteristic == null) {
            Log.e(TAG, "Not connected or write characteristic not available");
            return false;
        }
        
        writeCharacteristic.setValue(data);
        boolean result = bluetoothGatt.writeCharacteristic(writeCharacteristic);
        Log.d(TAG, "Write data result: " + result + ", length: " + data.length);
        return result;
    }
    
    public boolean writeCommand(String hexCommand) {
        if (hexCommand == null || hexCommand.length() % 2 != 0) {
            Log.e(TAG, "Invalid hex command: " + hexCommand);
            return false;
        }
        
        byte[] data = hexStringToByteArray(hexCommand);
        return writeData(data);
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
            if (newState == BluetoothProfile.STATE_CONNECTED) {
                Log.d(TAG, "Connected to GATT server");
                isConnected = true;
                gatt.discoverServices();
                callback.onDeviceConnected(gatt.getDevice());
            } else if (newState == BluetoothProfile.STATE_DISCONNECTED) {
                Log.d(TAG, "Disconnected from GATT server");
                isConnected = false;
                callback.onDeviceDisconnected(gatt.getDevice());
            }
        }
        
        @Override
        public void onServicesDiscovered(BluetoothGatt gatt, int status) {
            if (status == BluetoothGatt.GATT_SUCCESS) {
                BluetoothGattService service = gatt.getService(UUID.fromString(SERVICE_UUID));
                if (service != null) {
                    writeCharacteristic = service.getCharacteristic(UUID.fromString(CHARACTERISTIC_WRITE_UUID));
                    notifyCharacteristic = service.getCharacteristic(UUID.fromString(CHARACTERISTIC_NOTIFY_UUID));
                    
                    if (notifyCharacteristic != null) {
                        gatt.setCharacteristicNotification(notifyCharacteristic, true);
                        Log.d(TAG, "Enabled notifications");
                    }
                    
                    Log.d(TAG, "CoolLEDU service characteristics ready");
                } else {
                    callback.onError("CoolLEDU service not found");
                }
            }
        }
        
        @Override
        public void onCharacteristicChanged(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic) {
            byte[] data = characteristic.getValue();
            callback.onDataReceived(data);
        }
        
        @Override
        public void onCharacteristicWrite(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic, int status) {
            if (status == BluetoothGatt.GATT_SUCCESS) {
                Log.d(TAG, "Characteristic write successful");
            } else {
                Log.e(TAG, "Characteristic write failed with status: " + status);
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
    
    public void cleanup() {
        stopScan();
        disconnect();
    }
}