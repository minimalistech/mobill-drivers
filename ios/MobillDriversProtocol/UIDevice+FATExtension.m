//
//  UIDevice+FATExtension.m
//  FinApplet
//
//  Created by Haley on 2019/12/20.
//  Copyright © 2019 finogeeks. All rights reserved.
//

#import "UIDevice+FATExtension.h"

#import <sys/utsname.h>

@implementation UIDevice (FATExtension)

- (CGSize)actualSize
{
    CGFloat scale = [UIScreen mainScreen].scale;
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    CGSize actualSize = CGSizeMake(screenSize.width * scale, screenSize.height * scale);
    return actualSize;
}

static NSString *deviceMode = nil;
- (NSString *)deviceMode
{
    if (!deviceMode) {
        deviceMode = [self modeName];
    }
    return deviceMode;
}

static NSString *mode = nil;
- (NSString *)mode
{
    if (!mode) {
        struct utsname systemInfo;
        uname(&systemInfo);
        NSString *platform = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
        mode = platform;
    }
    return mode;
}

- (NSString *)modeName
{
    NSString *platform = [self mode];
    if (!platform) {
        return [UIDevice currentDevice].model;
    }
    
    if ([platform isEqualToString:@"i386"] || [platform isEqualToString:@"x86_64"]) {
        return @"iPhone simulator";
    }
    
    if ([platform isEqualToString:@"iPhone12,5"])        return @"iPhone 11 Pro Max";
    
    if ([platform isEqualToString:@"iPhone12,3"])        return @"iPhone 11 Pro";
    
    if ([platform isEqualToString:@"iPhone12,1"])        return @"iPhone 11";
    
    if ([platform isEqualToString:@"iPhone11,8"])        return @"iPhone XR";
    
    NSArray *iPhoneXSMax = @[@"iPhone11,4", @"iPhone11,6"];
    if ([iPhoneXSMax containsObject:platform])              return @"iPhone XS Max";
    
    if ([platform isEqualToString:@"iPhone11,2"])        return @"iPhone XS";
    
    NSArray *iPhoneX = @[@"iPhone10,3", @"iPhone10,6"];
    if ([iPhoneX containsObject:platform])              return @"iPhone X";
    
    NSArray *iPhone8Plus = @[@"iPhone10,2", @"iPhone10,5"];
    if ([iPhone8Plus containsObject:platform])          return @"iPhone 8 Plus";
    
    NSArray *iPhone8 = @[@"iPhone10,1", @"iPhone10,4"];
    if ([iPhone8 containsObject:platform])              return @"iPhone 8";
    
    NSArray *iPhone7Plus = @[@"iPhone9,2", @"iPhone9,4"];
    if ([iPhone7Plus containsObject:platform])          return @"iPhone 7 Plus";
    
    NSArray *iPhone7 = @[@"iPhone9,1", @"iPhone9,3"];
    if ([iPhone7 containsObject:platform])              return @"iPhone 7";
    
    if ([platform isEqualToString:@"iPhone8,4"])        return @"iPhone SE";
    
    if ([platform isEqualToString:@"iPhone8,2"])        return @"iPhone 6s Plus";
    
    if ([platform isEqualToString:@"iPhone8,1"])        return @"iPhone 6s";
    
    if ([platform isEqualToString:@"iPhone7,2"])        return @"iPhone 6";
    
    if ([platform isEqualToString:@"iPhone7,1"])        return @"iPhone 6 Plus";
    
    NSArray *iPhone5s = @[@"iPhone6,1",@"iPhone6,2"];
    if ([iPhone5s containsObject:platform])             return @"iPhone 5s";
    
    NSArray *iPhone5C = @[@"iPhone5,3",@"iPhone5,4"];
    if ([iPhone5C containsObject:platform])             return @"iPhone 5c";
    
    NSArray *iPhone5 = @[@"iPhone5,1",@"iPhone5,2"];
    if ([iPhone5 containsObject:platform])              return @"iPhone 5";
    
    if ([platform isEqualToString:@"iPhone4,1"])        return @"iPhone 4S";
    
    NSArray *iPhone4 = @[@"iPhone3,1",@"iPhone3,2",@"iPhone3,3"];
    if ([iPhone4 containsObject:platform])              return @"iPhone 4";
    
    if ([platform isEqualToString:@"iPhone2,1"])        return @"iPhone 3GS";
    
    if ([platform isEqualToString:@"iPhone1,2"])        return @"iPhone 3G";
    if ([platform isEqualToString:@"iPhone1,1"])        return @"iPhone 1G";
    
    // 其他类型
    return [UIDevice currentDevice].model;
}

@end
