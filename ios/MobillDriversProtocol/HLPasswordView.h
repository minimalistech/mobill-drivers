//
//  HLPasswordView.h
//  StatusScreens
//
//  Created by Harvey on 2022/8/20.
//  Copyright © 2022 Haley. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Const_Header.h"
#import "UIColor+Category.h"
#import "DNApplication.h"
#import "NSString+QCExtension.h"

typedef void(^HLVerifyBlock)(BOOL isCancel, NSString *password);

@interface HLPasswordView : UIView

@property (nonatomic, copy) NSString *deviceUUIDString;

- (instancetype)initWithBlock:(HLVerifyBlock)verifyBlock;

- (void)show;

- (void)hide;

@end

