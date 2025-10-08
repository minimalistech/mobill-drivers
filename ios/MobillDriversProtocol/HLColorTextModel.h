//
//  HLColorTextModel.h
//  CoolLED1248
//
//  Created by Harvey on 2020/11/3.
//  Copyright © 2020 Haley. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HLColorTextModel : NSObject<NSCoding,NSCopying,NSMutableCopying>

// 原始文字
@property (nonatomic, copy) NSString *originText;
// 单个文字item数组
@property (nonatomic, strong) NSArray *textItems;
// 是否加粗
@property (nonatomic, assign) BOOL bold;
// 旋转的度数
@property (nonatomic, assign) int degree;
// 是否镜像
@property (nonatomic, assign) BOOL isMirror;
// 模式 (1静态、2向左、3向右、4向上、5向下、6雪花、7画卷、8镭射)
@property (nonatomic, assign) int modeType;

@end
