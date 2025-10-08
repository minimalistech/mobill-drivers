//
//  DateTime.h
//  CoolLED1248
//
//  Created by go on 9/20/24.
//  Copyright © 2024 Haley. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DateTime : NSObject<NSCoding>

//设置节目内容-日期组件数据格式

// 该内容显示的时候，和其他层级的内容的混合方式
@property (nonatomic, assign)int coverTypeDateTime;
// 日期组件标志
@property (nonatomic, assign)int dateFlagDateTime;
// 显示时长
@property (nonatomic, assign)int showTimeDateTime;

// 每个数字的高度
@property (nonatomic, assign)int numHeightDateTime;
// 每个数字的宽度
@property (nonatomic, assign)int numWidthDateTime;
// 数字数据长度
@property (nonatomic, assign)int numDataLenDateTime;
// 数字（0~9）对应的文字的显示内容。
@property (nonatomic, copy)NSString *numDataDateTime;
// 年份数字的高度
@property (nonatomic, assign)int yearNumHeightDateTime;
// 年份数字的宽度
@property (nonatomic, assign)int yearNumWidthDateTime;
// 年份数字数据长度
@property (nonatomic, assign)int yearNumDataLenDateTime;
// 年份数字（0~9）对应的文字的显示内容。
@property (nonatomic, copy)NSString *yearNumDataDateTime;

// 年份显示颜色
@property (nonatomic, assign)int yearColorDateTime;
// 年份显示起始列，相当于 X 坐标
@property (nonatomic, assign)int yearStartColumnDateTime;
// 年份显示起始行，相当于 Y 坐标
@property (nonatomic, assign)int yearStartRowDateTime;
// 年份显示宽度
@property (nonatomic, assign)int yearWidthDateTime;
// 年份显示高度
@property (nonatomic, assign)int yearHeightDateTime;


// 分隔符颜色
@property (nonatomic, assign)int spaceyColorDateTime;
// 分割 符显 示起 始列，相当于 X 坐标
@property (nonatomic, assign)int spaceyStartColumnDateTime;
// 分割 符显 示起 始行，相当于 Y 坐标
@property (nonatomic, assign)int spaceyStartRowDateTime;
// 分隔符显示宽度
@property (nonatomic, assign)int spaceyWidthDateTime;
// 分隔符显示高度
@property (nonatomic, assign)int spaceyHeightDateTime;
// 分隔符显示数据长度
@property (nonatomic, assign)int spaceyDataLenDateTime;
// 分割符的显示数据
@property (nonatomic, copy)NSString *spaceyDataDateTime;


// 月显示颜色
@property (nonatomic, assign)int monColorDateTime;
// 月显示起始列，相当于 X 坐标
@property (nonatomic, assign)int monStartColumnDateTime;
// 月显示起始行，相当于 Y 坐标
@property (nonatomic, assign)int monStartRowDateTime;
// 月显示宽度
@property (nonatomic, assign)int monWidthateTime;
// 月显示高度
@property (nonatomic, assign)int monHeightDateTime;
// 月份简写显示数据长度
@property (nonatomic, assign)int monDataLenDateTime;
// 月份 简写 显示 数据，1 月到 12 月的显示数据，顺序排列
@property (nonatomic, copy)NSString *monDataDateTime;

// 分隔符颜色
@property (nonatomic, assign)int spacemColorDateTime;
// 分割 符显 示起 始列，相当于 X 坐标
@property (nonatomic, assign)int spacemStartColumnDateTime;
// 分割 符显 示起 始行，相当于 Y 坐标
@property (nonatomic, assign)int spacemStartRowDateTime;
// 分隔符显示宽度
@property (nonatomic, assign)int spacemWidthDateTime;
// 分隔符显示高度
@property (nonatomic, assign)int spacemHeightDateTime;
// 分割符显示数据长度
@property (nonatomic, assign)int spacemDataLenDateTime;
// 分割符的显示数据
@property (nonatomic, copy)NSString *spacemDataDateTime;

// 天显示颜色
@property (nonatomic, assign)int dayColorDateTime;
// 天显示起始列，相当于 X 坐标
@property (nonatomic, assign)int dayStartColumnDateTime;
// 天显示起始行，相当于 Y 坐标
@property (nonatomic, assign)int dayStartRowDateTime;
// 天显示宽度
@property (nonatomic, assign)int dayWidthDateTime;
// 天显示高度
@property (nonatomic, assign)int dayHeightDateTime;

// 分隔符颜色
@property (nonatomic, assign)int spacedColorDateTime;
// 分割 符显 示起 始列，相当于 X 坐标
@property (nonatomic, assign)int spacedStartColumnDateTime;
// 分割 符显 示起 始行，相当于 Y 坐标
@property (nonatomic, assign)int spacedStartRowDateTime;
// 分隔符显示宽度
@property (nonatomic, assign)int spacedWidthDateTime;
// 分隔符显示高度
@property (nonatomic, assign)int spacedHeightDateTime;
// 分割符显示数据长度
@property (nonatomic, assign)int spacedDataLenDateTime;
// 分割符的显示数据
@property (nonatomic, copy)NSString *spacedDataDateTime;

// 星期显示颜色
@property (nonatomic, assign)int weekColorDateTime;
// 星期显示起始行
@property (nonatomic, assign)int weekStartRowDateTime;
// 星期显示起始列
@property (nonatomic, assign)int weekStartColumnDateTime;
// 星期显示宽度
@property (nonatomic, assign)int weekWidthDateTime;
// 星期显示高度
@property (nonatomic, assign)int weekHeightDateTime;
// 星期显示数据长度
@property (nonatomic, assign)int weekDataLenDateTime;
// 星期一到星期日的显示数据，顺序排列
@property (nonatomic, copy)NSString *weekDataDateTime;

@end

NS_ASSUME_NONNULL_END
