//
//  DNApplication.m
//  MainViewDemo
//
//  Created by liusiyuan on 16/1/25.
//  Copyright © 2016年 liusiyuan. All rights reserved.
//

#import "DNApplication.h"

@implementation DNApplication

+ (DNApplication *)application
{
    static DNApplication *application;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        application = [[self alloc] init];
    });
    return application;
}

- (instancetype)init
{
    if (self = [super init]) {
        //当前系统版本
        _iOS_version = [[[UIDevice currentDevice] systemVersion] floatValue];
        //系统版本>=ios7
        _iOS7 = (_iOS_version >= 7.0)?(YES):(NO);
        
        if ([UIScreen mainScreen].bounds.size.width < [UIScreen mainScreen].bounds.size.height) {
            //屏幕的宽度
            _viewWidth = [UIScreen mainScreen].bounds.size.width;
            //屏幕的高度
            _viewHeight = [UIScreen mainScreen].bounds.size.height;
        }else{
            //屏幕的宽度
            _viewWidth = [UIScreen mainScreen].bounds.size.height;
            //屏幕的高度
            _viewHeight = [UIScreen mainScreen].bounds.size.width;
        }
        
        //视图的缩放比例
        _screenScale = _viewWidth/375;
        
        //视图的缩放比例
        _screenHeightScale = _viewHeight/812;
        
        //顶部Bar的高度
        _topBarHeight = 44;
        if (_iOS7) {
            _topBarHeight = 64;
        }
    }
    return self;
}

@end
