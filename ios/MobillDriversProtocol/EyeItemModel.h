//
//  EyeItemModel.h
//  CoolLED1248
//
//  Created by go on 1/7/25.
//  Copyright © 2025 Haley. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ColorItemModel32.h"

NS_ASSUME_NONNULL_BEGIN

@interface EyeItemModel : NSObject

// 时间戳，需要时作为id使用
@property (nonatomic, assign)NSInteger timestampInMillisecondsEye;

//设备类型，以及宽高分辨率作为标识符
@property (nonatomic, copy) NSString *itemDeviceIdentifyEye;

// 在有多个节目的情况下，显示多少次后切换到下一个节目
@property (nonatomic, assign)int itemShowTimeEye;

// 是否被选中，节目界面对应的标记
@property (nonatomic, assign) BOOL isSelectedEye;

// 选中时显示编号
@property (nonatomic, assign)int selectIndexEye;

//对应的ColorItemModel32 左右眼节目
@property (nonatomic, strong) ColorItemModel32 *textModelEyeL;

@property (nonatomic, strong) ColorItemModel32 *textModelEyeR;

@end

NS_ASSUME_NONNULL_END
