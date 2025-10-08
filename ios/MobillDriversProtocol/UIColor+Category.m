//
//  UIColor+Category.m
//  CowmanVideo
//
//  Created by Harvey on 2018/6/14.
//  Copyright © 2018年 Haley. All rights reserved.
//

#import "UIColor+Category.h"

@implementation UIColor (Category)

+ (UIColor *)colorWithHexString:(NSString *)hexString
{
    NSString *cString = [[hexString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    
    // String should be 6 or 8 characters
    if ([cString length] < 6) {
        return [UIColor clearColor];
    }
    
    // strip 0X if it appears
    if ([cString hasPrefix:@"0X"])
        cString = [cString substringFromIndex:2];
    if ([cString hasPrefix:@"#"])
        cString = [cString substringFromIndex:1];
    if ([cString length] != 6)
        return [UIColor clearColor];
    
    // Separate into r, g, b substrings
    NSRange range;
    range.location = 0;
    range.length = 2;
    
    //r
    NSString *rString = [cString substringWithRange:range];
    
    //g
    range.location = 2;
    NSString *gString = [cString substringWithRange:range];
    
    //b
    range.location = 4;
    NSString *bString = [cString substringWithRange:range];
    
    // Scan values
    unsigned int r, g, b;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    
    return [UIColor colorWithRed:((float) r / 255.0f) green:((float) g / 255.0f) blue:((float) b / 255.0f) alpha:1.0f];
}

+ (UIColor *)colorWithHexFloatArr:(NSArray *)arr
{
    return [UIColor colorWithRed:([arr[0] floatValue]) green:([arr[1] floatValue]) blue:([arr[2] floatValue]) alpha:1.0f];
}

+ (UIColor *)colorWithHex255Arr:(NSArray *)arr
{
    return [UIColor colorWithRed:([arr[0] floatValue] / 255.0f) green:([arr[1] floatValue] / 255.0f) blue:([arr[2] floatValue] / 255.0f) alpha:1.0f];
}

@end
