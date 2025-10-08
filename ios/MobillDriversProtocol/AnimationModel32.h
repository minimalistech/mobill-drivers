//
//  AnimationModel32.h
//  CoolLED1248
//
//  Created by 君同 on 2023/4/25.
//  Copyright © 2023 Haley. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AnimationModel32 : NSObject<NSCoding>

#pragma mark - 动画内容数据格式

//设置节目内容-动画内容数据格式

//动画内容数据二维数组
@property (nonatomic, strong) NSArray *dataAnimation;

//每帧的独立显示时间集合
@property (nonatomic, strong) NSArray *frameEveInterval;

// 该内容显示的时候，和其他层级的内容的混合方式
@property (nonatomic, assign)int coverTypeAnimation;
// 该内容显示起始行
@property (nonatomic, assign)int startRowAnimation;
// 该内容显示起始列
@property (nonatomic, assign)int startColAnimation;
// 该内容显示宽度
@property (nonatomic, assign)int widthDataAnimation;
// 该内容显示高度
@property (nonatomic, assign)int heightDataAnimation;
// 每个帧之间的显示间隔时间，间隔时间越长，显示越慢
@property (nonatomic, assign)int timeIntervalAnimation;

@end

NS_ASSUME_NONNULL_END
