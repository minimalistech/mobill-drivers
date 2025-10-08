//
//  ThemManager.h
//  CoolLED1248
//
//  Created by Harvey on 2019/3/22.
//  Copyright © 2019 Haley. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HLBluetoothManager.h"
#import "JTCommon.h"
#import "HLUtils.h"
#import "HLHUDHelper.h"
#import "Const_Header.h"

@interface ThemManager : NSObject

@property (nonatomic, assign) BTPeripheralType deviceType;

@property (nonatomic, strong) NSNumber *rowNum;

@property (nonatomic, strong) NSNumber *colNum;

@property (nonatomic, strong) NSString *itemDeviceIdentify;

@property (nonatomic, strong) NSString *peripheralName;

@property (nonatomic, strong) NSArray *colorItemModel32Data;

@property (nonatomic, assign) BOOL isReloadData;

@property (nonatomic, strong) NSArray *eyeDataArray;

@property (nonatomic, assign) BOOL isTabVC;

@property (nonatomic, assign) BOOL isEyeVC;

@property (nonatomic, assign) NSInteger bikeType;

@property (weak, nonatomic)NSTimer *speedTimer;

@property (nonatomic, assign) BOOL isShowPromptAlbum;

//用于标识发送节目提示0、默认，1、同步状态，2、发送
@property (nonatomic, assign) int promptItemType;


+ (instancetype)sharedInstance;

- (NSString *)currentDeviceType;
- (void)setCurrentDeviceType:(NSString *)deviceType;

- (NSString *)currentShareDeviceType;

- (void)saveFilePathWithKey:(NSString *)path data:(NSArray *)data;

- (void)saveEyeDataArrayFilePathWithKey:(NSString *)path eyeDataArray:(NSArray *)eyeDataArray;

//点击发送按钮，做一个超时处理state为1：点击发送按钮，2，收到了设备回应
-(void)sendCommandState:(NSInteger)state;
@end

