package com.mobilldriversprotocol;

import android.bluetooth.BluetoothDevice;
import com.facebook.react.bridge.*;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.facebook.react.bridge.ReactApplicationContext;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.HashMap;

public class MobillDriversBridgeModule extends ReactContextBaseJavaModule implements CoolLEDUBluetoothManager.CoolLEDUManagerCallback {
    
    private static final String REACT_CLASS = "MobillDrivers";
    private ReactApplicationContext reactContext;
    private CoolLEDUBluetoothManager bluetoothManager;
    
    public MobillDriversBridgeModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.reactContext = reactContext;
        this.bluetoothManager = new CoolLEDUBluetoothManager(reactContext, this);
    }
    
    @Override
    public String getName() {
        return REACT_CLASS;
    }
    
    @Override
    public Map<String, Object> getConstants() {
        final Map<String, Object> constants = new HashMap<>();
        constants.put("SUPPORTED_EVENTS", new String[]{
            "onDeviceDiscovered", "onDeviceConnected", "onDeviceDisconnected", "onDataReceived"
        });
        return constants;
    }
    
    @ReactMethod
    public void startScan(Promise promise) {
        try {
            if (!bluetoothManager.isBluetoothEnabled()) {
                promise.reject("BLUETOOTH_DISABLED", "Bluetooth is not enabled");
                return;
            }
            bluetoothManager.startScan();
            promise.resolve(true);
        } catch (Exception e) {
            promise.reject("SCAN_ERROR", e.getMessage());
        }
    }
    
    @ReactMethod
    public void connectToDevice(String deviceAddress, Promise promise) {
        try {
            // Get Bluetooth adapter through manager
            android.bluetooth.BluetoothManager btManager = 
                (android.bluetooth.BluetoothManager) reactContext.getSystemService(reactContext.BLUETOOTH_SERVICE);
            android.bluetooth.BluetoothAdapter btAdapter = btManager.getAdapter();
            
            BluetoothDevice device = btAdapter.getRemoteDevice(deviceAddress);
            if (device != null) {
                bluetoothManager.connectToDevice(device);
                promise.resolve(true);
            } else {
                promise.reject("DEVICE_NOT_FOUND", "Device not found");
            }
        } catch (Exception e) {
            promise.reject("CONNECT_ERROR", e.getMessage());
        }
    }
    
    @ReactMethod
    public void disconnectDevice(String deviceAddress, Promise promise) {
        try {
            bluetoothManager.disconnect();
            promise.resolve(true);
        } catch (Exception e) {
            promise.reject("DISCONNECT_ERROR", e.getMessage());
        }
    }
    
    @ReactMethod
    public void sendGraffitiData(ReadableArray pixelData, int width, int height, Promise promise) {
        try {
            // Create graffiti model
            GraffitiModel graffiti = new GraffitiModel(width, height);
            
            // Convert pixelData to format needed by protocol
            List<String> hexData = new ArrayList<>();
            for (int i = 0; i < pixelData.size(); i++) {
                int value = pixelData.getInt(i);
                hexData.add(String.format("%02x", value & 0xFF));
            }
            
            // Create protocol packets using extracted utilities
            List<List<String>> packets = ProtocolUtils.getPackageCommandsWithDataString(hexData, 0x03);
            
            // Send each packet
            for (List<String> packet : packets) {
                String command = ProtocolUtils.joinHexList(packet);
                boolean success = bluetoothManager.writeCommand(command);
                if (!success) {
                    promise.reject("SEND_ERROR", "Failed to send packet");
                    return;
                }
            }
            
            promise.resolve(true);
            
        } catch (Exception e) {
            promise.reject("SEND_ERROR", e.getMessage());
        }
    }
    
    @ReactMethod
    public void compressData(ReadableArray data, Promise promise) {
        try {
            // Convert ReadableArray to List<String>
            List<String> inputData = new ArrayList<>();
            for (int i = 0; i < data.size(); i++) {
                int value = data.getInt(i);
                inputData.add(String.format("%02x", value & 0xFF));
            }
            
            // Apply LZSS compression
            List<String> compressedData = LzssAlgorithm.getLzssCompressData(inputData);
            
            // Convert back to WritableArray
            WritableArray result = Arguments.createArray();
            for (String hex : compressedData) {
                result.pushInt(Integer.parseInt(hex, 16));
            }
            
            promise.resolve(result);
            
        } catch (Exception e) {
            promise.reject("COMPRESS_ERROR", e.getMessage());
        }
    }
    
    @ReactMethod
    public void calculateChecksum(ReadableArray data, Promise promise) {
        try {
            // Convert ReadableArray to byte array
            byte[] inputData = new byte[data.size()];
            for (int i = 0; i < data.size(); i++) {
                inputData[i] = (byte) data.getInt(i);
            }
            
            // Calculate CRC32 checksum
            int checksum = Crc32Algorithm.getCrc32CheckCode(inputData);
            promise.resolve(checksum);
            
        } catch (Exception e) {
            promise.reject("CHECKSUM_ERROR", e.getMessage());
        }
    }
    
    // CoolLEDUManagerCallback implementations
    @Override
    public void onDeviceDiscovered(BluetoothDevice device, int rssi) {
        String deviceName = device.getName();
        // Filter for "mobill" devices as specified in requirements
        if (deviceName != null && (deviceName.toLowerCase().contains("mobill") ||
                                  deviceName.toLowerCase().contains("led"))) {
            
            WritableMap deviceInfo = Arguments.createMap();
            deviceInfo.putString("id", device.getAddress());
            deviceInfo.putString("name", deviceName != null ? deviceName : "Unknown");
            deviceInfo.putInt("rssi", rssi);
            
            WritableMap event = Arguments.createMap();
            WritableArray devices = Arguments.createArray();
            devices.pushMap(deviceInfo);
            event.putArray("devices", devices);
            
            sendEvent("onDeviceDiscovered", event);
        }
    }
    
    @Override
    public void onDeviceConnected(BluetoothDevice device) {
        WritableMap deviceInfo = Arguments.createMap();
        deviceInfo.putString("id", device.getAddress());
        deviceInfo.putString("name", device.getName() != null ? device.getName() : "Unknown");
        
        sendEvent("onDeviceConnected", deviceInfo);
    }
    
    @Override
    public void onDeviceDisconnected(BluetoothDevice device) {
        WritableMap deviceInfo = Arguments.createMap();
        deviceInfo.putString("id", device.getAddress());
        deviceInfo.putString("name", device.getName() != null ? device.getName() : "Unknown");
        deviceInfo.putString("error", "");
        
        sendEvent("onDeviceDisconnected", deviceInfo);
    }
    
    @Override
    public void onDataReceived(byte[] data) {
        WritableArray dataArray = Arguments.createArray();
        for (byte b : data) {
            dataArray.pushInt(b & 0xFF);
        }
        
        WritableMap event = Arguments.createMap();
        event.putArray("data", dataArray);
        
        sendEvent("onDataReceived", event);
    }
    
    @Override
    public void onError(String error) {
        WritableMap event = Arguments.createMap();
        event.putString("error", error);
        
        sendEvent("onError", event);
    }
    
    private void sendEvent(String eventName, WritableMap params) {
        reactContext
            .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
            .emit(eventName, params);
    }
}