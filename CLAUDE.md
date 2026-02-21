# MobillDrivers - Claude Code Context

This document provides context for AI assistants working on this codebase.

## Project Overview

MobillDrivers is a React Native app for drivers that displays advertisements on CoolLEDU LED matrix displays mounted on vehicles. The app:

1. Connects to a CoolLEDU display via Bluetooth Low Energy (BLE)
2. Fetches ads from the Mobill backend every 15 seconds
3. Processes and sends ad content (images, text, animations) to the display
4. Tracks location and BLE devices for ad targeting and impression validation

## Architecture

### Platforms
- **iOS:** Native Objective-C protocol implementation in `/ios/MobillDriversProtocol/`
- **Android:** Native Java protocol implementation in `/android/app/src/main/java/com/mobilldriversprotocol/`
- **Shared:** TypeScript/React Native code in `/src/`

### Key Components

#### Native Display Protocol (Platform-Specific)
- `DisplayManagerBridge` - React Native bridge exposing native methods
- `CoolledUProtocol` (Android) / `JTTool` (iOS) - Protocol packet generation
- `CoolLEDUBluetoothManager` (Android) / `HLBluetoothManager` (iOS) - BLE communication
- `LzssAlgorithm` - LZSS compression for data packets

#### Shared JavaScript/TypeScript
- `src/DisplayManager.ts` - TypeScript wrapper for native module
- `src/services/AdService.ts` - Ad fetching with 15-second timer
- `src/services/BackgroundLocationService.ts` - GPS tracking
- `src/screens/HomeScreen.tsx` - Main UI and ad display logic

## CoolLEDU Protocol

### BLE Configuration
- **Service UUID:** `0000FFF0-0000-1000-8000-00805F9B34FB`
- **Characteristic UUID:** `0000FFF1-0000-1000-8000-00805F9B34FB` (both write and notify)

### Packet Structure
```
[0x01][escaped(length + data)][0x03]
```
- Start byte: `0x01`
- Length: 2 bytes (little-endian)
- Data: Protocol-specific payload
- End byte: `0x03`
- Escape sequence: bytes 0x01-0x03 become `[0x02, byte^0x04]`

**Critical:** Length bytes MUST be escaped together with data, not separately.

### Protocol Flow
1. Send begin packet (`startItemContentCommand`)
2. Wait for `0200` notification (success)
3. Send data packets (`setItemContentCommand`)
4. Wait for completion notification

### Device Responses
- `0200` - Success, ready for next phase
- `0201` - Also treated as success (iOS compatibility)
- `0202` - Device error
- `0203` - Data error

## Content Types

### Image (programType: 'image')
- Static image displayed on LED matrix
- Uses `GraffitiModel32` for pixel data

### Text (programType: 'text')
- Scrolling or static text
- Uses `ColorTextModel32` with `HLColorTextItem` for each character

### Animation (programType: 'animation')
- GIF or multi-frame content
- Uses `AnimationModel32` with frame arrays
- Frame interval: 200ms (5fps)

## Ad Service Timing

The ad service fetches new ads every 15 seconds. To prevent ads from interrupting content being displayed:

1. `pauseAdFetching()` - Called when content starts being sent to display
2. `resumeAdFetching()` - Called after content is fully sent

This prevents unnecessary ad requests that would be skipped (and still charged to advertisers).

## Common Issues and Solutions

### Android-Specific

1. **Display not showing content:**
   - Check BLE notify characteristic is FFF1 (not FFF2)
   - Verify LZSS compression is working
   - Check packet framing (length bytes escaped with data)

2. **Last packet not acknowledged:**
   - Protocol framing issue - length must be escaped WITH data

3. **UI not updating on disconnect:**
   - Manually emit `onDeviceDisconnected` event

### Both Platforms

1. **Ads interrupting each other:**
   - Use pause/resume ad fetching mechanism
   - Check `isSendingToDisplayRef` guard

2. **Animation too slow:**
   - `timeIntervalAnimation` should be 200ms

## Development Commands

```bash
# iOS
cd ios && pod install
npx react-native run-ios

# Android
cd android && ./gradlew assembleDebug
npx react-native run-android

# Logs
adb logcat | grep -E "(DisplayManager|CoolledU|Protocol)"
```

## Reference Materials

### Manufacturer SDK
- Android: `/Users/juan/tmp/mobill-drivers-rn/CoolLED1248_Android/`
- Key file: `app/src/main/java/com/jtkj/led1248/light/utils/CoolledUUtils.java`

### Documentation
- `ANDROID_STATUS.md` - Android implementation status and fixes
- Plan files in `/Users/juan/.claude/plans/` may contain additional context
