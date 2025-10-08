//
//  Countdown.h
//  CoolLED1248
//
//  Created by go on 10/24/24.
//  Copyright © 2024 Haley. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Countdown : NSObject

//设置节目内容-计时器组件数据格式

// 该内容显示的时候，和其他层级的内容的混合方式
@property (nonatomic, assign)int coverTypeCountdown;
// 计时器模式
@property (nonatomic, assign)int modeCountdown;

// 每个数字的高度
@property (nonatomic, assign)int numHeightCountdown;
// 每个数字的宽度
@property (nonatomic, assign)int numWidthCountdown;
// 数字数据长度
@property (nonatomic, assign)int numDataLenCountdown;
// 时间数字（0~9）对应的文字的显示内容。
@property (nonatomic, copy)NSString *numDataCountdown;

// 小时显示颜色
@property (nonatomic, assign)int hourColorCountdown;
// 小时显示起始列，相当于 X 坐标
@property (nonatomic, assign)int hourStartColumnCountdown;
// 小时显示起始行，相当于 Y 坐标
@property (nonatomic, assign)int hourStartRowCountdown;
// 小时显示宽度
@property (nonatomic, assign)int hourWidthCountdown;
// 小时显示高度
@property (nonatomic, assign)int hourHeightCountdown;

// 分隔符颜色
@property (nonatomic, assign)int spacehColorCountdown;
// 分割符显示起始列，相当于 X 坐标
@property (nonatomic, assign)int spacehStartColumnCountdown;
// 分割 符显示起始行，相当于 Y 坐标
@property (nonatomic, assign)int spacehStartRowCountdown;
// 分隔符显示宽度
@property (nonatomic, assign)int spacehWidthCountdown;
// 分隔符显示高度
@property (nonatomic, assign)int spacehHeightCountdown;
// 分隔符显示数据长度
@property (nonatomic, assign)int spacehDataLenCountdown;
// 分割符的显示数据
@property (nonatomic, copy)NSString *spacehDataCountdown;

// 分钟显示颜色
@property (nonatomic, assign)int minColorCountdown;
// 分钟显示起始列，相当于 X 坐标
@property (nonatomic, assign)int minStartColumnCountdown;
// 分钟显示起始行，相当于 Y 坐标
@property (nonatomic, assign)int minStartRowCountdown;
// 分钟显示宽度
@property (nonatomic, assign)int minWidthCountdown;
// 分钟显示高度
@property (nonatomic, assign)int minHeightCountdown;

// 分隔符颜色
@property (nonatomic, assign)int spacemColorCountdown;
// 分割 符显 示起 始列，相当于 X 坐标
@property (nonatomic, assign)int spacemStartColumnCountdown;
// 分割 符显 示起 始行，相当于 Y 坐标
@property (nonatomic, assign)int spacemStartRowCountdown;
// 分隔符显示宽度
@property (nonatomic, assign)int spacemWidthCountdown;
// 分隔符显示高度
@property (nonatomic, assign)int spacemHeightCountdown;
// 分割符显示数据长度
@property (nonatomic, assign)int spacemDataLenCountdown;
// 分割符的显示数据
@property (nonatomic, copy)NSString *spacemDataCountdown;

// 秒显示颜色
@property (nonatomic, assign)int secColorCountdown;
// 秒显示起始列，相当于 X 坐标
@property (nonatomic, assign)int secStartColumnCountdown;
// 秒显示起始行，相当于 Y 坐标
@property (nonatomic, assign)int secStartRowCountdown;
// 秒显示宽度
@property (nonatomic, assign)int secWidthCountdown;
// 秒显示高度
@property (nonatomic, assign)int secHeightCountdown;

@end

NS_ASSUME_NONNULL_END
