//
//  GWPeripheral.h
//  CoolLED1248
//
//  Created by Harvey on 2017/10/7.
//  Copyright © 2017年 Haley. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

#import "HLPackageSendModel.h"

typedef NS_ENUM(NSUInteger, GWPeripheralState) {
    GWPeripheralStateDefault,
    GWPeripheralStateConnecting,
    GWPeripheralStateDisConnecting,
    GWPeripheralStateConnected,
    GWPeripheralStateDefaultVerify,
    GWPeripheralStateUserVerify,
    GWPeripheralStateVerifySuccess,
    GWPeripheralStateFail
};

typedef NS_ENUM(NSUInteger, BTPeripheralType) {
    BTPeripheralTypeNone,
    BTPeripheralTypeCoolLED1248,
    BTPeripheralTypeCoolLED536,
    BTPeripheralTypeBVBucket,
    BTPeripheralTypeCoolLEDX1632,
    BTPeripheralTypeCoolLEDX1664,
    BTPeripheralTypeCoolLEDX1696,
    BTPeripheralTypeCoolLEDX16192,
    BTPeripheralTypeCoolLEDS1632,
    BTPeripheralTypeCoolLEDS1664,
    BTPeripheralTypeCoolLEDS1696,
    BTPeripheralTypeCoolLEDS16192,
    //CoolLEDM系列设备，目前2种，16行与32行 12、13
    BTPeripheralTypeCoolLEDM16,
    BTPeripheralTypeCoolLEDM32,
    //CoolLEDU系列设备，16行与32行 14、15
    BTPeripheralTypeCoolLEDU16,
    BTPeripheralTypeCoolLEDU32,
    //iLedBike系列设备，目前1种，12*36 16
    BTPeripheralTypeCoolLEDUiLedBike12,
    //CoolLEDU系列设备，24行 17
    BTPeripheralTypeCoolLEDU24,
    //CoolLEDU系列设备，n行,该类型对行进行扩展 18
    BTPeripheralTypeCoolLEDHeightAdaption,
    //CoolLEDU系列设备，20行 19
    BTPeripheralTypeCoolLEDU20,
    //CoolLEDC系列设备，48行 20
    BTPeripheralTypeCoolLEDC48,
    //CoolLEDMX系列设备，16行 21
    BTPeripheralTypeCoolLEDMX16,
    //CoolLEDUX系列设备，16行 22
    BTPeripheralTypeCoolLEDUX16,
};

typedef void(^OneParamBlock)(BOOL result);
typedef void(^WriteBlock)(NSArray *decodeArray);
typedef void(^SendCompletion)(BOOL success, NSString *msg);

@interface GWPeripheral : NSObject

/** 外设名称 */
@property (nonatomic,copy) NSString *name;

/// 用户重命名设置的名称
@property (nonatomic, copy) NSString *rename;

@property (copy, nonatomic) NSString    *UUIDString;

@property (nonatomic, assign) GWPeripheralState state;

/** 信号强度 */
@property (nonatomic,strong) NSNumber *RSSI;

@property (nonatomic,assign) BOOL is_select;

@property (nonatomic,strong) CBPeripheral *peripheral;

@property (nonatomic, copy) NSString *actulMacAddress;

@property (nonatomic, copy) NSString *deviceId;

@property (nonatomic, assign) BTPeripheralType deviceType;

@property (nonatomic, strong) NSNumber *firmwarIndex;

/// 显示屏行数
@property (nonatomic, strong) NSNumber *rowNum;
/// 显示屏列数
@property (nonatomic, strong) NSNumber *colNum;
/// 显示屏类型 0x00:单色；0x01:七彩；0x02:全彩
@property (nonatomic, strong) NSNumber *ledxType;

/// 将要设置的密码
@property (nonatomic, copy) NSString *willSetPassword;

/// 是否开启了密码保护。修改了密码，且密码非000000才算开始密码保护
@property (nonatomic, assign) BOOL passwordProtected;

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, copy) OneParamBlock connectCompletion;

@property (nonatomic, copy) OneParamBlock disconnectCompletion;

@property (nonatomic, copy) WriteBlock writeCompeltion;

#pragma mark - public methods
+ (BTPeripheralType)deviceTypeWithName:(NSString *)name colNum:(NSNumber *)colNum rowNum:(NSNumber *)rowNum;

+ (NSString *)deviceTypeNameWithDeviceType:(BTPeripheralType)deviceType;

+ (NSString *)imageNameWithRSSI:(NSNumber *)number;

+ (void)sendPackageCommands:(NSArray *)packageCommands;

+ (void)sendPackageCommands:(NSArray *)packageCommands itemRank:(int)itemRank VCType:(int)VCType onDevice:(GWPeripheral *)peripheralModel; 

#pragma mark - private methods
- (void)connect;

- (void)disconnect;

- (void)clearTimer;

- (void)writeCommandModel:(HLPackageSendModel *)packageModel completion:(SendCompletion)completion;

@end
