//
//  HLPasswordView.m
//  StatusScreens
//
//  Created by Harvey on 2022/8/20.
//  Copyright © 2022 Haley. All rights reserved.
//

#import "HLPasswordView.h"
#import "HLHUDHelper.h"

#import <AudioToolbox/AudioToolbox.h>

@interface HLPasswordView ()<UITextFieldDelegate>

@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, copy) HLVerifyBlock verifyBlock;

@end

@implementation HLPasswordView

- (instancetype)initWithBlock:(HLVerifyBlock)verifyBlock
{
    self = [super initWithFrame:[UIScreen mainScreen].bounds];
    if (self) {
        _verifyBlock = verifyBlock;
        [self p_initSubViews];
    }
    return self;
}

- (void)p_initSubViews
{
    UIView *coverView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    coverView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4];
    [self addSubview:coverView];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(bgClick)];
    [coverView addGestureRecognizer:tapGesture];
    
    UIView *containView = [[UIView alloc] initWithFrame:CGRectMake(30*scaleXL, 200*scaleXL, 315*scaleXL, 247*scaleXL)];
    containView.backgroundColor = [UIColor whiteColor];
    containView.layer.cornerRadius = 5;
    [coverView addSubview:containView];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 16*scaleXL, 315*scaleXL, 25*scaleXL)];
    titleLabel.textColor = UIColorFromHex(0x333333);
    titleLabel.text = showText(@"密码");
    titleLabel.font = [UIFont systemFontOfSize:18*scaleXL];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [containView addSubview:titleLabel];
    
    UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(31*scaleXL, 55*scaleXL, 253*scaleXL, 40)];
    textField.placeholder = showText(@"请输入6位数字密码");
    textField.font = HLRegularFont(16);
    textField.borderStyle = UITextBorderStyleNone;
    textField.textColor = [UIColor blackColor];
    textField.keyboardType = UIKeyboardTypeNumberPad;
    textField.delegate = self;
    [textField addTarget:self action:@selector(textDidChange:) forControlEvents:UIControlEventEditingChanged];
    self.textField = textField;
    [containView addSubview:textField];
    
    UIView *lineV = [[UIView alloc] initWithFrame:CGRectMake(31*scaleXL, 55*scaleXL + 40, 253*scaleXL, 1)];
    lineV.backgroundColor = UIColorFromHex(0x828282);
    [containView addSubview:lineV];
    
    UIButton *cancelBtn = [[UIButton alloc] initWithFrame:CGRectMake(31*scaleXL, 179*scaleXL, 252*scaleXL, 44*scaleXL)];
    cancelBtn.backgroundColor = [UIColor whiteColor];
    cancelBtn.layer.cornerRadius = 22*scaleXL;
    cancelBtn.layer.borderWidth = 1.0;
    cancelBtn.layer.borderColor = UIColorFromHex(0x7A6AEE).CGColor;
    [cancelBtn setTitle:showText(@"取消") forState:UIControlStateNormal];
    [cancelBtn setTitleColor:[UIColor colorWithHexString:@"#bfbfbf"] forState:UIControlStateNormal];
    [cancelBtn addTarget:self action:@selector(cancelClick) forControlEvents:UIControlEventTouchUpInside];
    [containView addSubview:cancelBtn];
    
    UIButton *sureBtn = [[UIButton alloc] initWithFrame:CGRectMake(31*scaleXL, 119*scaleXL, 252*scaleXL, 44*scaleXL)];
    sureBtn.backgroundColor = UIColorFromHex(0x7A6AEE);
    sureBtn.layer.cornerRadius = 22*scaleXL;
    [sureBtn setTitle:showText(@"确定") forState:UIControlStateNormal];
    [sureBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [sureBtn addTarget:self action:@selector(sureClick) forControlEvents:UIControlEventTouchUpInside];
    [containView addSubview:sureBtn];
}

- (void)textDidChange:(UITextField *)textField
{
    NSString *text = textField.text;
    if (text.length > 6) {
        text = [text substringToIndex:6];
        textField.text = text;
    }
}

#pragma mark - btn click events
- (void)bgClick
{
    [self endEditing:YES];
}

- (void)cancelClick
{
    if (self.verifyBlock) {
        self.verifyBlock(YES, nil);
    }
    [self hide];
}

- (void)sureClick
{
    NSString *text = self.textField.text;
    if (text.length != 6) {
        [HLHUDHelper showErrorWithTitle:showText(@"请输入6位数字密码")];
        return;
    }
    
    if (![NSString isNumber:text]) {
        [HLHUDHelper showErrorWithTitle:showText(@"请输入6位数字密码")];
        return;
    }
    
    if (self.verifyBlock) {
        self.verifyBlock(NO, text);
    }
    
    [self hide];
}

- (void)show
{
    [[UIApplication sharedApplication].keyWindow addSubview:self];
    
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}

- (void)hide
{
    [self removeFromSuperview];
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self endEditing:YES];
    
    return YES;
}

@end
