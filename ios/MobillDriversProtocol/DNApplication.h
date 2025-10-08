//
//  DNApplication.h
//  MainViewDemo
//
//  Created by liusiyuan on 16/1/25.
//  Copyright © 2016年 liusiyuan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define applicationSelf [DNApplication application]
#define scaleXL [DNApplication application].screenScale
#define scaleYH [DNApplication application].screenHeightScale
#define screenH [UIScreen mainScreen].bounds.size.height
#define UIColorFromHex(s)  [UIColor colorWithRed:(((s & 0xFF0000) >> 16))/255.0 green:(((s &0xFF00) >>8))/255.0 blue:((s &0xFF))/255.0 alpha:1.0]
#define KEY_Size 10

#define finishItem @"finishItem"
#define getClockFromDevice @"getClockFromDevice"
#define startFirmwareUpgradeOn @"startFirmwareUpgradeOn"
#define connectCoolLEDUDevice @"connectCoolLEDUDevice"
#define GetScoreboard @"GetScoreboard"
#define GetCountdown @"GetCountdown"
#define GetStopwatch @"GetStopwatch"

#define importShareData @"importShareData"
#define importShareIconData @"importShareIconData"


#define getDynamicStaticData @"getDynamicStaticData"

//设备类型分为CoolLEDM与CoolLEDU，以协议划分
#define CurrentDeviceType  [[ThemManager sharedInstance] currentDeviceType]

#define CurrentShareDeviceType  [[ThemManager sharedInstance] currentShareDeviceType]

//设备类型具体的分辨率类型
#define DeviceType  [ThemManager sharedInstance].deviceType

#define currentColNum [ThemManager sharedInstance].colNum
#define currentRowNum  [ThemManager sharedInstance].rowNum
#define DeviceCol [[ThemManager sharedInstance].colNum intValue]
#define DeviceRow  [[ThemManager sharedInstance].rowNum intValue]
#define ItemDeviceIdentify  [ThemManager sharedInstance].itemDeviceIdentify

#define EyeDateIdentifyKey [NSString stringWithFormat:@"Eye%@",ItemDeviceIdentify]

//标记是否行驶内容界面进入
#define IsTabVC  [ThemManager sharedInstance].isTabVC

//标记是否恶魔眼界面进入
#define IsEyeVC  [ThemManager sharedInstance].isEyeVC

#define Graffiti12  @"IconGraffiti1212"
#define Animation12  @"IconAnimation1212"

#define Graffiti16  @"IconGraffiti1616"
#define Animation16  @"IconAnimation1616"

#define Graffiti20  @"IconGraffiti2020"
#define Animation20  @"IconAnimation2020"

#define Graffiti24  @"IconGraffiti2424"
#define Animation24  @"IconAnimation2424"

#define Graffiti32  @"IconGraffiti3232"
#define Animation32  @"IconAnimation3232"

#define CoolLEDUGraffiti16  @"CoolLEDUIconGraffiti1616"
#define CoolLEDUAnimation16  @"CoolLEDUIconAnimation1616"

#define CoolLEDUGraffiti20  @"CoolLEDUIconGraffiti2020"
#define CoolLEDUAnimation20  @"CoolLEDUIconAnimation2020"

#define CoolLEDUGraffiti24  @"CoolLEDUIconGraffiti2424"
#define CoolLEDUAnimation24  @"CoolLEDUIconAnimation2424"

#define CoolLEDUGraffiti32  @"CoolLEDUIconGraffiti3232"
#define CoolLEDUAnimation32  @"CoolLEDUIconAnimation3232"

#define colorExchange  15.9375
#define hardwareVersionStandard  4

typedef NS_ENUM(NSUInteger, NotificationKey) {
    NotificationKeyDefault,
    NotificationKeyMasterplateEdit,
    NotificationKeyItemDetailView16,
    NotificationKeyGraffiti16,
    NotificationKeyAnimationSetView16,
    NotificationKeyMaterialView16,
    NotificationKeySetView32,
    NotificationKeyClockTime,
    NotificationKeyScoreboard,
    NotificationKeyCountdown,
    NotificationKeyStopwatch,
    NotificationKeyAddDevilEye,
};

@interface DNApplication : NSObject
//屏幕的宽度
@property (nonatomic, assign) CGFloat viewWidth;
//屏幕的高度
@property (nonatomic, assign) CGFloat viewHeight;
//当前系统版本
@property (nonatomic, assign) CGFloat iOS_version;
//系统版本>=ios7
@property (nonatomic, assign) CGFloat iOS7;
//视图的缩放比例
@property (nonatomic, assign) CGFloat screenScale;
//视图的缩放比例
@property (nonatomic, assign) CGFloat screenHeightScale;
//顶部Bar的高度
@property (nonatomic, assign) CGFloat topBarHeight;

@property (nonatomic, assign)NotificationKey notificationKey;

+ (DNApplication *)application;

@end
