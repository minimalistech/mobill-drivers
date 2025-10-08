//
//  UpgradePromptV.h
//  CoolLED1248
//
//  Created by go on 11/14/23.
//  Copyright © 2023 Haley. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Const_Header.h"
#import "DNApplication.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^UpgradePromptVSureBlock)(void);

@interface UpgradePromptV : UIView

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *contentLabel;
@property (nonatomic, strong)  UIButton *cancelBtn;
@property (nonatomic, strong)  UIButton *sureBtn;

- (instancetype)initWithSureBlock:(UpgradePromptVSureBlock)block type:(NSInteger)type;

- (void)show;

- (void)hide;

@end

NS_ASSUME_NONNULL_END
