# Android DisplayManager Implementation Status

**Last Updated:** February 5, 2026
**iOS Status:** Working in production
**Android Status:** Working - Full functionality achieved

---

## Current State Summary

The Android implementation is now **fully functional** and matches the iOS behavior. All content types (images, text, animations) display correctly on the CoolLEDU hardware.

---

## Issues Fixed

### 1. BLE Characteristic Mismatch (Critical)
- **Problem:** Android was using FFF2 for notifications, but the device only has FFF1
- **Fix:** Changed `CHARACTERISTIC_NOTIFY_UUID` to use FFF1 (same as write characteristic)
- **File:** `CoolLEDUBluetoothManager.java`

### 2. LZSS Compression Not Implemented
- **Problem:** `LzssAlgorithm.java` was returning uncompressed data
- **Fix:** Ported complete LZSS algorithm from manufacturer's `CoolledUUtils.java`
- **File:** `LzssAlgorithm.java`

### 3. Protocol Packet Framing Bug
- **Problem:** Length bytes were not being escaped together with data
- **Fix:** Combined length + data before escaping in `getSendDataWithInfo()`
- **File:** `CoolledUProtocol.java`
- **Details:** Manufacturer's code: `tempResult.addAll(getDataStringLength(data)); tempResult.addAll(data); result.addAll(convertData(tempResult, 0));` - escapes length+data together

### 4. Device Response 0201 Handling
- **Problem:** Android was treating 0201 response as failure
- **Fix:** Updated to treat type 2 (0201) as success, matching iOS behavior
- **File:** `DisplayManagerBridge.java`

### 5. Turn Off Display UI Not Updating
- **Problem:** `onDeviceDisconnected` event wasn't being emitted when `gatt.close()` called
- **Fix:** Manually emit `onDeviceDisconnected` event in `disconnectDevice()` method
- **File:** `DisplayManagerBridge.java`

### 6. Animation Speed Too Slow
- **Problem:** `timeIntervalAnimation` was set to 1500ms (1.5 seconds between frames)
- **Fix:** Changed to 200ms to match iOS (5fps)
- **File:** `DisplayManagerBridge.java`

### 7. Ad Timing / Ads Interrupting Each Other
- **Problem:** New ads would arrive and interrupt content being displayed
- **Fix:** Implemented pause/resume ad fetching mechanism in shared JavaScript code
- **Files:** `src/services/AdService.ts`, `src/screens/HomeScreen.tsx`
- **Details:** Pauses the 15-second ad fetch timer while content is being processed/displayed, preventing unnecessary ad requests that would be skipped (and charged to advertisers)

---

## Architecture

### Files Structure

```
android/app/src/main/java/com/mobilldriversprotocol/
├── CoolledUProtocol.java          - Protocol packet generation (LZSS, CRC32, framing)
├── DisplayManagerBridge.java      - React Native bridge (connection, display, events)
├── DisplayManagerPackage.java     - Module registration
├── CoolLEDUBluetoothManager.java  - BLE communication (scan, connect, write, notify)
├── ProtocolUtils.java             - Protocol utilities
├── Crc32Algorithm.java            - CRC32 checksum calculation
├── LzssAlgorithm.java             - LZSS compression algorithm
├── GraffitiModel.java             - Basic graffiti model
└── models/
    ├── ColorItemModel32.java      - Program container model
    ├── GraffitiModel32.java       - Image content model
    ├── AnimationModel32.java      - Animation content model
    ├── ColorTextModel32.java      - Text content model
    └── HLColorTextItem.java       - Text character model
```

### Protocol Flow

1. **Begin Phase:**
   - Create content model (GraffitiModel32, AnimationModel32, etc.)
   - Wrap in ColorItemModel32 container
   - Send begin packet with `startItemContentCommand()`
   - Device responds with `0200` (success) notification

2. **Data Phase:**
   - On `0200` notification, send actual content data
   - Call `setItemContentCommand()` to transmit data packets
   - Each packet is acknowledged by device
   - Uses LZSS compression for efficiency

3. **Completion:**
   - Device sends final notification when display is updated
   - Promise resolved, UI updated

### BLE Configuration

- **Service UUID:** `0000FFF0-0000-1000-8000-00805F9B34FB`
- **Write Characteristic:** `0000FFF1-0000-1000-8000-00805F9B34FB`
- **Notify Characteristic:** `0000FFF1-0000-1000-8000-00805F9B34FB` (same as write)
- **Chunk Size:** 180 bytes with 10ms delay

---

## Shared JavaScript Changes

### AdService.ts
Added `pauseAdFetching()` and `resumeAdFetching()` methods:
- `pauseAdFetching()`: Clears the 15-second BackgroundTimer interval
- `resumeAdFetching()`: Restarts the 15-second timer

### HomeScreen.tsx
Updated `displayAd()` function:
- Calls `AdService.pauseAdFetching()` before sending content
- Calls `AdService.resumeAdFetching()` after content is sent (in finally block)

This prevents new ad requests while content is being processed, avoiding:
1. Skipped ads that still charge advertisers
2. Content interruption during display

---

## Build Instructions

```bash
# Navigate to android directory
cd android

# Clean build (optional)
./gradlew clean

# Build debug APK
./gradlew assembleDebug

# Install on connected device
adb install -r app/build/outputs/apk/debug/app-debug.apk

# Or use React Native CLI
npx react-native run-android
```

---

## Debugging

```bash
# View Android logs
adb logcat | grep -E "(DisplayManager|CoolledU|CoolLEDU|Protocol|BLE)"

# Save logs to file
adb logcat > androidstudio-logs.output
```

---

## Reference Files

### iOS Implementation (Working Reference)
- `/ios/MobillDriversProtocol/DisplayManagerBridge.m` - Main bridge
- `/ios/MobillDriversProtocol/JTTool.m` - Protocol utilities
- `/ios/MobillDriversProtocol/HLBluetoothManager.m` - BLE management

### Manufacturer SDK
- `/Users/juan/tmp/mobill-drivers-rn/CoolLED1248_Android/app/src/main/java/com/jtkj/led1248/light/utils/CoolledUUtils.java`
