//
//  HLPackageSendModel.m
//  CoolLED1248
//
//  Created by Harvey on 2018/9/5.
//  Copyright © 2018年 Haley. All rights reserved.
//

#import "HLPackageSendModel.h"

@implementation HLPackageSendModel

- (instancetype)initWithPackageCommands:(NSArray *)packageCommands
{
    self = [super init];
    if (self) {
        self.identifier = [[NSUUID UUID] UUIDString];
        self.tryTimes = 0;
        [self p_initData:packageCommands];
    }
    return self;
}

- (void)p_initData:(NSArray *)packageCommands
{
    NSMutableArray *modelsM = [NSMutableArray array];
    for (int i = 0; i < packageCommands.count; i++) {
        NSString *command = packageCommands[i];
        HLOnePackageModel *model = [[HLOnePackageModel alloc] initWithPackageContent:command packageId:i];
        [modelsM addObject:model];
    }
    self.packageContentModels = [modelsM copy];
}

/// 重置所有分包的发送次数
- (void)resetAllPackage
{
    for (HLOnePackageModel *model in self.packageContentModels) {
        model.sendIndex = 0;
        model.state = PackageCommandFlagReady;
    }
    _currentPackageId = 0;
}

@end
