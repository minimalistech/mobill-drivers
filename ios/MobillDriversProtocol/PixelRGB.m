//
//  PixelRGB.m
//  CoolLED1248
//
//  Created by go on 9/30/24.
//  Copyright © 2024 Haley. All rights reserved.
//

#import "PixelRGB.h"

@interface PixelRGB ()

@property (nonatomic, strong) HLPackageSendModel *packageModel;
@property (nonatomic, copy) SendCompletion sendCompletion;

@property (nonatomic, copy) SendCompletion subCompletion;

@property (nonatomic, assign) BOOL updatingIsColor;
@end

@implementation PixelRGB

- (instancetype)init {
    if (self = [super init]) {
        self.rgbArr = @[@0, @0, @0];
        self.isColor = 0;
        self.updatingIsColor = NO; // 初始化标志
    }
    return self;
}

- (void)setRgbArr:(NSArray *)rgbArr {
    _rgbArr = rgbArr;

    // 仅在未更新isColor时检查
    if (!self.updatingIsColor) {
        self.updatingIsColor = YES; // 设置标志以防止递归调用
        self.isColor = 0;
        for (NSNumber *item in rgbArr) {
            if ([item floatValue] != 0) {
                self.isColor = 1;
                break;
            }
        }
        self.updatingIsColor = NO; // 重置标志
    }
}

- (void)setIsColor:(int)isColor {
    _isColor = isColor;
    if (isColor == 0) {
        self.rgbArr = @[@0, @0, @0]; // 这将调用setRgbArr:
    }
}

@end
