//
//  FATHelper.h
//  FAT
//
//  Created by 杨涛 on 2018/7/14.
//  Copyright © 2018年 finogeeks. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "HLHUD.h"

@interface HLHUDHelper : NSObject

#pragma mark - old apis
+ (void)showLoadingWithTitle:(NSString *)title;

+ (void)showLoadingWithTitle:(NSString *)title detailText:(NSString *)detailText;

+ (void)showSuccessWithTitle:(NSString *)title;

+ (void)showErrorWithTitle:(NSString *)title;

+ (void)hideHud;

+ (HLHUD *)currentHud;

#pragma mark - hud
+ (void)showLoadingForView:(UIView *)view title:(NSString *)title mask:(BOOL)mask;

+ (void)showToastForView:(UIView *)view title:(NSString *)title icon:(NSString *)icon;

/**
 image非空时需要传appId
 */
+ (void)showToastForView:(UIView *)view
                   title:(NSString *)title
                   image:(NSString *)imagePath
                   appId:(NSString *)appId
                    icon:(NSString *)icon
                duration:(int)duration
                    mask:(BOOL)mask;

+ (void)hideHudForView:(UIView *)view;

@end
