//
//  HLBluetoothManager.h
//  蓝牙
//
//  Created by 赵鹏宇 on 16/1/25.
//  Copyright © 2016年 赵鹏宇. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

#import "GWPeripheral.h"

@protocol HLBluetoothManagerDelegate <NSObject>

@required
- (void)didUpdatePeripheralsArray:(NSArray *)array;
- (void)didConnectedPeripheral:(GWPeripheral *)model;
@optional
- (void)didDisconnectPeripheral:(GWPeripheral *)model error:(NSError *)error;
- (void)didFailToConnectPeripheral:(GWPeripheral *)model;
- (void)didVerifyPasswordSuccess:(GWPeripheral *)model;

@end

@interface HLBluetoothManager : NSObject

@property (nonatomic,strong) CBCentralManager *manager;

@property (nonatomic,weak) id<HLBluetoothManagerDelegate> delegate;

/// 保存当前已搜索出来的蓝牙设备对象<GWPeripheral>
@property (nonatomic,strong) NSMutableArray *scanedModelsArray;
/// 保存当前已搜索出来的蓝牙设备<CBPeripheral>
@property (nonatomic,strong) NSMutableSet *scanedPeripheralSet;
/// 保存当前已经连接的蓝牙设备对象<GWPeripheral>
@property (nonatomic, strong) NSMutableArray *connectedModelsArray;

@property (nonatomic, strong) NSMutableArray *selectModelsArray;

@property (nonatomic,copy) void(^lampStateBlock)(BOOL isON);//灯的开关状态
@property (nonatomic,copy) void(^ConnectedPeripheralBlock)(BOOL isConnected);//连接到蓝牙的回调

@property (nonatomic, assign) BTPeripheralType peripheralType;

@property (nonatomic, strong) NSDate *lastSendDate;

+ (instancetype)standardManager;

- (void)startDiscoverPeripheral;

- (void)startConnectDevice:(GWPeripheral *)peripheralModel;
- (void)cancelDevice:(GWPeripheral *)peripheralModel;

- (void)writCommad:(NSString *)commad;

- (void)writCommadWithSelectModels:(NSString *)commad;

- (void)writeCommand:(NSString *)command onDevice:(GWPeripheral *)peripheralModel;

- (BOOL)canSendCommand:(int)interval;

@end
