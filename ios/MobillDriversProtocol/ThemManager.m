//
//  ThemManager.m
//  CoolLED1248
//
//  Created by Harvey on 2019/3/22.
//  Copyright © 2019 Haley. All rights reserved.
//

#import "ThemManager.h"

static ThemManager *instance = nil;

@interface ThemManager ()
{
    NSInteger sendState;
    NSString *_overrideDeviceType;
}
@end

@implementation ThemManager

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [super allocWithZone:zone];
    });
    return instance;
}

- (BTPeripheralType)deviceType
{
    if (_deviceType == BTPeripheralTypeNone) {
        return BTPeripheralTypeCoolLEDX1664;
    }
    return _deviceType;
}

- (NSString *)currentDeviceType
{
    // Use override if set
    if (_overrideDeviceType) {
        return _overrideDeviceType;
    }

    if ([ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDM16 || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDMX16 || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDM32) {
        return @"CoolLEDM";
    }

    if ([ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDU16 || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDUX16 || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDU32 || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDUiLedBike12 || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDU24 || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDU20 || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDHeightAdaption) {
        return @"CoolLEDU";
    }

    if ([ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDC48) {
        return @"CoolLEDC";
    }

    return @"other";
}

- (void)setCurrentDeviceType:(NSString *)deviceType
{
    _overrideDeviceType = deviceType;
}

- (NSString *)currentShareDeviceType
{
    if ([ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDM16 || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDMX16 || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDM32) {
        return @"CoolLEDM";
    }
    
    if ([ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDU16 || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDUX16 || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDU32 || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDU24 || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDU20 || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDHeightAdaption) {
        return @"CoolLEDU";
    }
    
    if ([ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDUiLedBike12) {
        return @"iLedBike";
    }
    
    if ([ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDC48) {
        return @"CoolLEDC";
    }
    
    return @"other";
}

#pragma mark - tool method

- (NSString *)turn10to2:(int)orginNumber
{
    int num = orginNumber;
    
    NSMutableString * result = [[NSMutableString alloc]init];
    while (num > 0) {
        NSString * reminder = [NSString stringWithFormat:@"%d",num % 2];
        [result insertString:reminder atIndex:0];
        num = num / 2;
    }
    return result;
}

- (void)saveFilePathWithKey:(NSString *)path data:(NSArray *)data{
    [ThemManager sharedInstance].colorItemModel32Data = data;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSString *filePath = [JTCommon filePathWithKey:path];
        [self saveObject:data toFile:filePath];
    });
}

- (void)saveEyeDataArrayFilePathWithKey:(NSString *)path eyeDataArray:(NSArray *)eyeDataArray{
    [ThemManager sharedInstance].eyeDataArray = eyeDataArray;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSString *filePath = [JTCommon filePathWithKey:path];
        [self saveObject:eyeDataArray toFile:filePath];
    });
}

-(void)saveObject:eyeDataArray toFile:filePath{
    NSInteger maxAttempts = 5;
    NSInteger attempt = 0;
    BOOL success = NO;

    while (attempt < maxAttempts && !success) {
        success = [NSKeyedArchiver archiveRootObject:eyeDataArray toFile:filePath];
        if (success) {
            NSLog(@"第 %ld 次归档成功", (long)(attempt + 1));
        } else {
            NSLog(@"第 %ld 次归档失败，正在重试...", (long)(attempt + 1));
            attempt++;
            // 可选：可以加上一个小的延迟，避免快速重试
            [NSThread sleepForTimeInterval:1.0]; // 延迟1秒
        }
    }

    if (!success) {
        NSLog(@"所有尝试均失败，请检查文件路径或对象的可归档性。");
    }
}

////点击发送按钮，做一个超时处理state为1：点击发送按钮，2，收到了设备回应
-(void)sendCommandState:(NSInteger)state{
    switch (state) {
        case 0:
            break;
        case 1:
        {
            sendState = 1;
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [HLUtils showPromptItemRank:0];
                
            });
            
            [self performSelector:@selector(sendButtonOpen) withObject:nil afterDelay:10.0f];
        }
            break;
        case 2:
            sendState = state;
            break;
        case 3:
        {
            sendState = 3;
            [HLHUDHelper showLoadingWithTitle:[NSString stringWithFormat:@"%@",showText(@"发送")] detailText:@"0%"];
            
            [self performSelector:@selector(sendButtonOpen) withObject:nil afterDelay:10.0f];
        }
            break;
        default:
            break;
    }
}

-(void)sendButtonOpen{
    switch (sendState) {
        case 0:
            break;
        case 1:
        {
            [HLHUDHelper hideHud];
            sendState = 0;
        }
            break;
        case 2:
            sendState = 0;
            break;
        case 3:
        {
            [HLHUDHelper hideHud];
            sendState = 0;
        }
            break;
        default:
            break;
    }
    
}

@end
