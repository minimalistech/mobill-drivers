//
//  JTTool.h
//  CoolLED1248
//
//  Created by 君同 on 2023/3/13.
//  Copyright © 2023 Haley. All rights reserved.
//

#import "ColorItemModel32.h"
#import "ColorTextModel32.h"
#import "HLColorTextItem.h"
#import "ClockTime.h"
#import "DateTime.h"
#import "Countdown.h"
#import "Scoreboard.h"

#import "LzssAlgorithm.h"
#import "Crc32Algorithm.h"
#import "HLUtils.h"
#import "ThemManager.h"
#import "NSString+QCExtension.h"
#import "DNApplication.h"

NS_ASSUME_NONNULL_BEGIN

@interface JTTool : NSObject

@property (nonatomic, assign) CGFloat topBarHeight;

//开始设置节目内容
+(void)startItemContentCommand:(ColorItemModel32 *)colorItemModel32 itemRank:(int)itemRank itemTotalCount:(int)itemTotalCount onDevice:(GWPeripheral *)peripheralModel;

//开始设置行驶内容
+(void)startDriveItemContentCommand:(ColorItemModel32 *)colorItemModel32 state:(int)state  onDevice:(GWPeripheral *)peripheralModel;

//设置节目内容
+(void)setItemContentCommand:(ColorItemModel32 *)colorItemModel32 itemRank:(int)itemRank VCType:(int)VCType onDevice:(GWPeripheral *)peripheralModel;

//OTA 开始升级
+(void)StartFirmwareUpgrade:(NSData *)sendItemData lenght:(int)lenght  onDevice:(GWPeripheral *)peripheralModel;

//OTA 传输数据
+(void)firmwareUpgrade:(NSData *)sendItemData itemRank:(int)itemRank VCType:(int)VCType onDevice:(GWPeripheral *)peripheralModel;

//本地存储gif图
+(void)saveGifFromServer:(NSString *)gifName fileName:(NSString *)fileName data:(NSData *)gifData;

//获取节目总内容数据 (generates the complete content structure for animations)
+(NSString *)getItemTotalContent:(ColorItemModel32 *)colorItemModel32;

@end

NS_ASSUME_NONNULL_END
