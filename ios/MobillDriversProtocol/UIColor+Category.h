//
//  UIColor+Category.h
//  CowmanVideo
//
//  Created by Harvey on 2018/6/14.
//  Copyright © 2018年 Haley. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (Category)

+ (UIColor *)colorWithHexString:(NSString *)hexString;

+ (UIColor *)colorWithHexFloatArr:(NSArray *)arr;

+ (UIColor *)colorWithHex255Arr:(NSArray *)arr;

@end
