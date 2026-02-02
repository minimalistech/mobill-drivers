//
//  Const_Header.h
//  CoolLED1248
//
//  Created by 王华磊 on 2017/10/3.
//  Copyright © 2017年 Haley. All rights reserved.
//

#ifndef Const_Header_h
#define Const_Header_h

#pragma mark - common
#ifdef DEBUG
#define GWLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#define GWLog(fmt, ...) nil
#endif

#define kWidth [UIScreen mainScreen].bounds.size.width //获取设备的物理宽度
#define kHeight [UIScreen mainScreen].bounds.size.height //获取设备的物理高度

#define kDeviceHeight ((kWidth > kHeight) ? kWidth : kHeight)

#define kIsPlus (kDeviceHeight == 736.0) ? YES : NO

#define kBottomSafeHeight ([HLUtils safeEdgeInset].bottom)

// 设备系统版本号
#define DeviceVersion  [[[UIDevice currentDevice] systemVersion] floatValue]

/****************************** 颜色 ********************************/
#define RGBColor(r,g,b,a) ([UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a])

#pragma mark - 字体
#define HLRegularFont(fontSize) [UIFont fontWithName:@"PingFang-SC-Regular" size:fontSize]

#pragma mark 自定义通知
/****************************** 自定义通知 ********************************/
#define kConnectedDeviceListChange      @"kConnectedDeviceListChange"           //已连接的设备列表发生变化
#define kAppLanguageChangedNotification @"kAppLanguageChangedNotification"      //语言切换
#define kMusicShouldStopNotification    @"kMusicShouldStopNotification"         // 音乐应该停止播放的通知
#define kConnectedPeriphTypeDidChangeNotification   @"kConnectedPeriphTypeDidChangeNotification" //连接的设备类型变更

#define kChangePasswordNotification   @"kChangePasswordNotification" //修改密码的通知

#pragma mark UserDefaultKey
/***************************** UserDefaultKey *************************/
#define kAutoOpenAfterConnect       @"kAutoOpenAfterConnect"            // 连接成功后，自动开灯
#define kAutoCloseAfterDisconnect   @"kAutoCloseAfterDisconnect"        // 连接成功后，自动关灯
#define kShakeColorType             @"kShakeColorType"                  // 摇一摇 颜色类型
#define kCallTip                    @"kCallTip"                         // 来电提醒
#define kChosenLanguage             @"kChosenLanguage"                  // 语言选择
#define kRhythmMode                 @"kRhythmMode"                      // 律动模式

#define kShowedFirstLanguage        @"kShowedFirstLanguage"               // 是否在安装后已显示过语言选择框
#define kAppLanguage                @"kAppLanguage"                     //语言
#define kEnterTextEditPage          @"kEnterTextEditPage"      // 是否首次进入文字编辑页面

#define kStartRecord                @"kStartRecord"                     // 开始录音

#define kGraffDataListKey           @"kGraffDataListKey"    // 涂鸦列表存在userdefault中的key

#define kTextDataListKey            @"kTextDataListKey"     // 文本列表存在userdefault中的key

#define kAnimationDataListKey       @"kAnimationDataListKey"    // 动画列表存在userdefault中的key

#define kLastConnectedPeripheral    @"kLastConnectedPeripheral"

#define kLastConnectedDeviceName    @"kLastConnectedDeviceName"

#define kLastConnectedDeviceType    @"kLastConnectedDeviceType" // 最后一次连接的设备类型

#define kLastConnectedRowNum        @"kLastConnectedRowNum" // 最后一次连接的设备显示屏列数

#define kLastConnectedColNum        @"kLastConnectedColNum" // 最后一次连接的设备显示屏列数

#define kLastConnectedItemDeviceIdentify    @"kLastConnectedItemDeviceIdentify" // 最后一次连接的设备类型标识符

#define kLastConnectedPeripheralName        @"kLastConnectedPeripheralName" // 最后一次连接的设备类型标识符

#define kDevicePasswordDictionary    @"kDevicePasswordDictionary" // 设备-密码字典

#define kRenameListKey               @"kRenameListKey"           // 重命名的设备列表的Key

#define kTypeSelectKey               @"kTypeSelectKey"           

#define kTypeEditKey                 @"kTypeEditKey"

#define kTypeLongPressKey            @"kTypeLongPressKey"

#define kTypeMaterialEditKey         @"kTypeMaterialEditKey"

#define kTypeShareGraffitiKey        @"kTypeShareGraffitiKey"

#define kTypeShareAnimationKey       @"kTypeShareAnimationKey"

#define kTypeShareFunctionKey        @"kTypeShareFunctionKey"

#define kTypePromptAlbumVKey         @"kTypePromptAlbumVKey"

#define isOpenCoolLEDX               @"isOpenCoolLEDX"

#define kCategoryList                @"kCategoryList"

#define kCategoryIconList            @"kCategoryIconList"

#define kCategoryAppLanguage         @"kCategoryAppLanguage"

#define kDefaultPaletteColors        @"kDefaultPaletteColors"

#define kDefaultPaletteWordColors    @"kDefaultPaletteWordColors"

#define kLightingCustomColors        @"kLightingCustomColors"

#define KIsFirstEnterSpeedShow       @"KIsFirstEnterSpeedShow"
#define KIsSpeedShow                 @"KIsSpeedShow"

#define KSpeedUnit                   @"KSpeedUnit"

#define kEnterForeground             @"kEnterForeground"

// 取多语言的宏
// Simplified version - localization files don't exist in native iOS code, so just return the key
// This prevents NSBundle errors and (null) alerts when kAppLanguage is not set
#define showText(key) key
//#define showText(key)  [NSString stringWithFormat:@"%@", [[NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%@",[[NSUserDefaults standardUserDefaults] objectForKey:kAppLanguage] ?: @"en"] ofType:@"lproj"]] localizedStringForKey:(key) value:(key) table:@"InfoPlist"]]

#pragma mark - CoolLED
// 导航栏背景色
#define kNavigationBarColor RGBColor(32,32,32,1)
// Tabbar背景色
#define kTabBarColor kNavigationBarColor
// 视图背景色
#define kViewBgColor RGBColor(32,32,32,1)
// 涂鸦颜色
#define kGraffitiColor RGBColor(103,77,241,1)
// 主题色 （即Tabbar选中、选中框等颜色）
#define kThemeColor RGBColor(103,77,241,1)

#define kGraffiCols 48
#define kGraffiRows 12

#define kMaxTextLength 80

#pragma mark - Kangaroos

#define kKRGraffiCols 36
#define kKRGraffiRows 5

#define kKRGraffDataListKey           @"kKRGraffDataListKey" // 涂鸦列表存在userdefault中的key

#define kKRTextDataListKey             @"kKRTextDataListKey" // 文本列表存在userdefault中的key

/******************* Kangaroos ************************/
#define kKRGraffitiColor RGBColor(251, 0, 195, 1)
#define kKRThemeColor RGBColor(56, 255, 255, 1)

#define kKRBorderColor RGBColor(26, 178, 10, 1)

#pragma mark - BVBucket
/******************* BVBucket ************************/
#define kBVBGraffDataListKey            @"kBVBGraffDataListKey" //涂鸦列表存在userDefault中的key

#define kBVBTextDataListKey           @"kBVBTextDataListKey" // 文本列表存在userdefault中的key

#pragma mark - CoolLEDX
#define kCLXGraffDataListKey            @"kCLXGraffDataListKey" //涂鸦列表存在userDefault中的key
#define kCLXTextDataListKey           @"kCLXTextDataListKey" // 文本列表存在userdefault中的key
#define kCLXAnimationDataListKey      @"kCLXAnimationDataListKey"    // 动画列表存在userdefault中的key

#define kCLXStaticPatternFileKey        @"kCLXStaticPatternFileKey"   // 从服务器端请求的静态图案的文件key
#define kCLXDynamicPatternFileKey       @"kCLXDynamicPatternFileKey"  // 从服务器端请求的动态图案的文件key
#define kCLXStaticPatternFileKey        @"kCLUStaticPatternFileKey"   // 从服务器端请求的静态图案的文件key
#define kCLXDynamicPatternFileKey       @"kCLUDynamicPatternFileKey"  // 从服务器端请求的动态图案的文件key

#define kCLXStaticDataUpdateTimeKey        @"kCLXStaticDataUpdateTimeKey"   // 从服务器端请求的静态图案的时间key
#define kCLXDynamicDataUpdateTimeKey       @"kCLXDynamicDataUpdateTimeKey"  // 从服务器端请求的动态图案的时间key
#define kCLXStaticDataUpdateTimeKey        @"kCLUStaticDataUpdateTimeKey"   // 从服务器端请求的静态图案的时间key
#define kCLXDynamicDataUpdateTimeKey       @"kCLUDynamicDataUpdateTimeKey"  // 从服务器端请求的动态图案的时间key

#pragma mark - CoolLEDS
#define kCLSGraffDataListKey            @"kCLSGraffDataListKey" //涂鸦列表存在userDefault中的key
#define kCLSTextDataListKey           @"kCLSTextDataListKey" // 文本列表存在userdefault中的key
#define kCLSTextDataListKey32         @"kCLSTextDataListKey32" // 32设备文本列表存在userdefault中的key
#define kCLSAnimationDataListKey      @"kCLSAnimationDataListKey"    // 动画列表存在userdefault中的key

#define kCLSStaticPatternFileKey        @"kCLSStaticPatternFileKey"   // 从服务器端请求的静态图案的文件key
#define kCLSDynamicPatternFileKey       @"kCLSDynamicPatternFileKey"  // 从服务器端请求的动态图案的文件key

#define kCLSStaticDataUpdateTimeKey        @"kCLSStaticDataUpdateTimeKey"   // 从服务器端请求的静态图案的时间key
#define kCLSDynamicDataUpdateTimeKey       @"kCLSDynamicDataUpdateTimeKey"  // 从服务器端请求的动态图案的时间key


#define kCLXTextKey         @"kCLXTextKey"  //文本key
#define kCLXRGBKey          @"kCLXRGBKey"   //RGBkey

#define kCLXPatternCols 32
#define kCLXPatternRows 16


typedef NS_ENUM(NSUInteger, HLEditType) {
    HLEditTypeNone,
    HLEditTypeNormal,
    HLEditTypeAll,
};

#define kEditBtnWidth  48

#define kEditIconWidth 30

#define kCommonBottomH 124
#define kLEDXSBottomH 84

#define JTScreen32Switch @"JTScreen32Switch"
#define JTScreen32Bright @"JTScreen32Bright"
#define JTScreen32Mirror @"JTScreen32Mirror"
#define JTScreen32SupportLocalMicFlag @"JTScreen32SupportLocalMicFlag"
#define JTScreen32Localmics @"JTScreen32Localmics"
#define JTScreen32Localmicmode @"JTScreen32Localmicmode"
#define JTScreen32Showid @"JTScreen32Showid"
#define JTScreen32Promaxnum @"JTScreen32Promaxnum"
#define JTScreen32Remotestatus @"JTScreen32Remotestatus"
#define GetOriginDeviceData @"GetOriginDeviceData"
#define JTScreenfileNameStrOTA @"JTScreenfileNameStrOTA"
#define JTScreenOTADic @"JTScreenOTADic"
#define JTScreenAllSetSwitch @"JTScreenAllSetSwitch"
#define JTScreenAscendingDevice @"JTScreenAscendingDevice"
#define JTScreenAscendingPrompt @"JTScreenAscendingPrompt"
#define JTScreenAddItemPrompt @"JTScreenAddItemPrompt"

#define JTScreenSpeedLight @"JTScreenSpeedLight"

#define CurrentDeviceDriveState @"CurrentDeviceDriveState"
#define GetCurrentDeviceDriveState @"GetCurrentDeviceDriveState"

#define kSetHour @"kSetHour"
#define kSetMin @"kSetMin"
#define kSetSec @"kSetSec"

#define kSetMinScore @"kSetMinScore"
#define kSetSecScore @"kSetSecScore"

static NSString *kEmail = @"coolled1248@163.com";
static NSString *kRecipientEmail = @"coolled1248@gmail.com";

static int kMaxAnimateFrames_1248 = 30;
static int kMaxAnimateFrames_1632 = 50;
static int kMaxAnimateFrames_1664 = 79;
static int kMaxAnimateFrames_1696 = 53;

static int kMaxTextLength_BVB = 80;
static int kMaxTextLength_536 = 80;
static int kMaxTextLength_1248 = 123;
static int kMaxTextLength_1632 = 105;
static int kMaxTextLength_1664 = 318;
static int kMaxTextLength_1696 = 318;
static int kMaxTextLength_1664Other = 318;

static int kMaxTextLength_32 = 150;

#endif /* Const_Header_h */
