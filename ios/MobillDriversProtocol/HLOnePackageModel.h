//
//  HLOnePackageModel.h
//  CoolLED1248
//
//  Created by Harvey on 2022/6/3.
//  Copyright © 2022 Haley. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, PackageCommandFlag) {
    PackageCommandFlagReady,
    PackageCommandFlagSent,
    PackageCommandFlagSentSuccess,
    PackageCommandFlagSentFail
};

NS_ASSUME_NONNULL_BEGIN

@interface HLOnePackageModel : NSObject

// 要发送的分包信息内容
@property (nonatomic, copy) NSString *packageContent;

// 分包id
@property (nonatomic, assign) NSInteger packageId;

// 分包发送状态
@property (nonatomic, assign) PackageCommandFlag state;

// 当前发送的次数
@property (nonatomic, assign) NSInteger sendIndex;

- (instancetype)initWithPackageContent:(NSString *)packageContent packageId:(NSInteger)packageId;

@end

NS_ASSUME_NONNULL_END
