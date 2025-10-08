//
//  ClockTime.h
//  CoolLED1248
//
//  Created by go on 9/20/24.
//  Copyright © 2024 Haley. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ClockTime : NSObject<NSCoding>

//设置节目内容-数字结构时间组件

// 该内容显示的时候，和其他层级的内容的混合方式
@property (nonatomic, assign)int coverTypeClockTime;
// 时间组件标志
@property (nonatomic, assign)int timeFlagClockTime;
// 显示时长
@property (nonatomic, assign)int showTimeClockTime;

// 每个数字的高度
@property (nonatomic, assign)int numHeightClockTime;
// 每个数字的宽度
@property (nonatomic, assign)int numWidthClockTime;
// 数字数据长度
@property (nonatomic, assign)int numDataLenClockTime;
// 时间数字（0~9）对应的文字的显示内容。
@property (nonatomic, copy)NSString *numDataClockTime;

// 小时显示颜色
@property (nonatomic, assign)int hourColorClockTime;
// 小时显示起始列，相当于 X 坐标
@property (nonatomic, assign)int hourStartColumnClockTime;
// 小时显示起始行，相当于 Y 坐标
@property (nonatomic, assign)int hourStartRowClockTime;
// 小时显示宽度
@property (nonatomic, assign)int hourWidthClockTime;
// 小时显示高度
@property (nonatomic, assign)int hourHeightClockTime;

// 分隔符颜色
@property (nonatomic, assign)int spacehColorClockTime;
// 分割符显示起始列，相当于 X 坐标
@property (nonatomic, assign)int spacehStartColumnClockTime;
// 分割 符显示起始行，相当于 Y 坐标
@property (nonatomic, assign)int spacehStartRowClockTime;
// 分隔符显示宽度
@property (nonatomic, assign)int spacehWidthClockTime;
// 分隔符显示高度
@property (nonatomic, assign)int spacehHeightClockTime;
// 分隔符显示数据长度
@property (nonatomic, assign)int spacehDataLenClockTime;
// 分割符的显示数据
@property (nonatomic, copy)NSString *spacehDataClockTime;

// 分钟显示颜色
@property (nonatomic, assign)int minColorClockTime;
// 分钟显示起始列，相当于 X 坐标
@property (nonatomic, assign)int minStartColumnClockTime;
// 分钟显示起始行，相当于 Y 坐标
@property (nonatomic, assign)int minStartRowClockTime;
// 分钟显示宽度
@property (nonatomic, assign)int minWidthClockTime;
// 分钟显示高度
@property (nonatomic, assign)int minHeightClockTime;

// 分隔符颜色
@property (nonatomic, assign)int spacemColorClockTime;
// 分割 符显 示起 始列，相当于 X 坐标
@property (nonatomic, assign)int spacemStartColumnClockTime;
// 分割 符显 示起 始行，相当于 Y 坐标
@property (nonatomic, assign)int spacemStartRowClockTime;
// 分隔符显示宽度
@property (nonatomic, assign)int spacemWidthClockTime;
// 分隔符显示高度
@property (nonatomic, assign)int spacemHeightClockTime;
// 分割符显示数据长度
@property (nonatomic, assign)int spacemDataLenClockTime;
// 分割符的显示数据
@property (nonatomic, copy)NSString *spacemDataClockTime;

// 秒显示颜色
@property (nonatomic, assign)int secColorClockTime;
// 秒显示起始列，相当于 X 坐标
@property (nonatomic, assign)int secStartColumnClockTime;
// 秒显示起始行，相当于 Y 坐标
@property (nonatomic, assign)int secStartRowClockTime;
// 秒显示宽度
@property (nonatomic, assign)int secWidthClockTime;
// 秒显示高度
@property (nonatomic, assign)int secHeightClockTime;

// Am 和pm 显示颜色
@property (nonatomic, assign)int ampmColorClockTime;
// Am/pm 显示起始列，相当于 X 坐标
@property (nonatomic, assign)int ampmStartColumnClockTime;
// Am/pm 显示起始行，相当于 Y 坐标
@property (nonatomic, assign)int ampmStartRowClockTime;
// Am/pm 显示宽度
@property (nonatomic, assign)int ampmWidthClockTime;
// Am/pm 显示高度
@property (nonatomic, assign)int ampmHeightClockTime;
// Am/pm 显示数据长度
@property (nonatomic, assign)int ampmDataLenClockTime;
// Am 显示数据和 pm显示数据，顺序排列
@property (nonatomic, copy)NSString *ampmDataClockTime;

@end

NS_ASSUME_NONNULL_END
