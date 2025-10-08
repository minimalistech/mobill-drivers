//
//  HLPackageSendModel.h
//  CoolLED1248
//
//  Created by Harvey on 2018/9/5.
//  Copyright © 2018年 Haley. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HLOnePackageModel.h"

@interface HLPackageSendModel : NSObject


/// 要发送的分包内容对象数组
@property (nonatomic, copy) NSArray<HLOnePackageModel *> *packageContentModels;

/// 当前发送的包id
@property (nonatomic, assign) NSInteger currentPackageId;

/// 重发次数
@property (nonatomic, assign) NSInteger tryTimes;

/// 对象唯一标识
@property (nonatomic, copy) NSString *identifier;

- (instancetype)initWithPackageCommands:(NSArray *)packageCommands;

/// 重置所有分包的发送次数
- (void)resetAllPackage;

@end
