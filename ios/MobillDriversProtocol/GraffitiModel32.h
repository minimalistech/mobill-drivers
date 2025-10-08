              //
//  GraffitiModel32.h
//  CoolLED1248
//
//  Created by 君同 on 2023/4/25.
//  Copyright © 2023 Haley. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface GraffitiModel32 : NSObject<NSCoding>

#pragma mark - 涂鸦内容数据格式

//设置节目内容-涂鸦内容数据格式

//涂鸦点阵数据二维数组
@property (nonatomic, strong) NSArray *dataGraffiti;

// 该内容显示的时候，和其他层级的内容的混合方式
@property (nonatomic, assign)int coverTypeGraffiti;
// 该内容显示起始行
@property (nonatomic, assign)int startRowGraffiti;
// 该内容显示起始列
@property (nonatomic, assign)int startColGraffiti;
// 该内容显示宽度
@property (nonatomic, assign)int widthDataGraffiti;
// 该内容显示高度
@property (nonatomic, assign)int heightDataGraffiti;
// 涂鸦显示模式
@property (nonatomic, assign)int showModelGraffiti;
// 涂鸦显示速度（显示模式的对应速度）
@property (nonatomic, assign)int speedDataGraffiti;
// 涂鸦停留时间（一屏显示完成后的停留时间）
@property (nonatomic, assign)int stayTimeGraffiti;

@end

NS_ASSUME_NONNULL_END
