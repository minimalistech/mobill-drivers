//
//  DisplayManagerBridge.h
//  MobillDriversProtocol
//
//  React Native Bridge for LED Display Management
//  Copyright © 2024 Mobill. All rights reserved.
//

#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>
#import <CoreLocation/CoreLocation.h>
#import "HLBluetoothManager.h"

@interface DisplayManagerBridge : RCTEventEmitter <RCTBridgeModule, HLBluetoothManagerDelegate, CLLocationManagerDelegate>

@end