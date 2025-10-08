//
//  UpgradePromptV.m
//  CoolLED1248
//
//  Created by go on 11/14/23.
//  Copyright © 2023 Haley. All rights reserved.
//

#import "UpgradePromptV.h"
#import "UIView+Extension.h"
#import "UIColor+Category.h"

#import <AudioToolbox/AudioToolbox.h>

@interface UpgradePromptV ()<UIGestureRecognizerDelegate>


@property (nonatomic, copy) UpgradePromptVSureBlock block;

@end

@implementation UpgradePromptV

- (instancetype)initWithSureBlock:(UpgradePromptVSureBlock)block type:(NSInteger)type
{
    self = [super initWithFrame:[UIScreen mainScreen].bounds];
    if (self) {
       _block = block;
       
       [self initSubView];
       
//       [self initData];
        if (type == 1) {
            self.titleLabel.text = showText(@"硬件升级");
            self.contentLabel.text = showText(@"当前硬件可以升级，是否立即升级？");
            self.cancelBtn.hidden = NO;
        }
        if (type == 2){
            self.titleLabel.text = showText(@"硬件升级");
            self.contentLabel.text = showText(@"当前设备需要升级才能使用！");
            self.sureBtn.frame = CGRectMake(31*scaleXL, 255*scaleXL, 252*scaleXL, 44*scaleXL);
            self.cancelBtn.hidden = YES;
        }
        if (type == 3){
            self.titleLabel.text = showText(@"温馨提示");
            self.contentLabel.text = showText(@"升级失败，请重新连接设备，进行升级！");
            self.sureBtn.frame = CGRectMake(31*scaleXL, 255*scaleXL, 252*scaleXL, 44*scaleXL);
            self.cancelBtn.hidden = YES;
        }
    }
    return self;
}

- (void)initSubView
{
    UIView *coverView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    coverView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4];
    [self addSubview:coverView];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(bgClick)];
    tapGesture.delegate = self;
    [coverView addGestureRecognizer:tapGesture];
    
    UIView *containView = [[UIView alloc] initWithFrame:CGRectMake(30*scaleXL, 270*scaleXL, 315*scaleXL, 339*scaleXL)];
    containView.backgroundColor = [UIColor whiteColor];
    containView.layer.cornerRadius = 5;
    [coverView addSubview:containView];
    containView.center = coverView.center;
    
    UIImageView *image=[[UIImageView alloc]initWithFrame:CGRectMake(0,0, 315*scaleXL, 130*scaleXL)];
    image.contentMode=UIViewContentModeScaleAspectFill;
    image.layer.cornerRadius=5;
    image.clipsToBounds=YES;
    image.image=[UIImage imageNamed:@"Mask group"];
    [containView addSubview:image];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(44*scaleXL, 27*scaleXL, 200*scaleXL, 31*scaleXL)];
    self.titleLabel = titleLabel;
    titleLabel.textColor = UIColorFromHex(0xFFFFFF);
    titleLabel.font = [UIFont boldSystemFontOfSize:22*scaleXL];
    [containView addSubview:titleLabel];
    
    UILabel *contentLabel = [[UILabel alloc] initWithFrame:CGRectMake(16*scaleXL, 146*scaleXL, 282*scaleXL, 41*scaleXL)];
    contentLabel.textColor = UIColorFromHex(0x333333);
    contentLabel.font = [UIFont systemFontOfSize:14*scaleXL];
    contentLabel.textAlignment = NSTextAlignmentCenter;
    contentLabel.numberOfLines = 2;
    contentLabel.adjustsFontSizeToFitWidth = YES;
    [containView addSubview:contentLabel];
    self.contentLabel = contentLabel;
    

    UIButton *cancelBtn = [[UIButton alloc] initWithFrame:CGRectMake(31*scaleXL, 271*scaleXL, 252*scaleXL, 44*scaleXL)];
    cancelBtn.backgroundColor = [UIColor whiteColor];
    cancelBtn.layer.cornerRadius =  22*scaleXL;
    cancelBtn.layer.borderWidth = 1.0;
    cancelBtn.layer.borderColor = UIColorFromHex(0x7A6AEE).CGColor;
    [cancelBtn setTitle:showText(@"取消") forState:UIControlStateNormal];
    [cancelBtn setTitleColor:[UIColor colorWithHexString:@"#bfbfbf"] forState:UIControlStateNormal];
    [cancelBtn addTarget:self action:@selector(hide) forControlEvents:UIControlEventTouchUpInside];
    [containView addSubview:cancelBtn];
    self.cancelBtn = cancelBtn;
    
    UIButton *sureBtn = [[UIButton alloc] initWithFrame:CGRectMake(31*scaleXL, 211*scaleXL, 252*scaleXL, 44*scaleXL)];
    sureBtn.backgroundColor = UIColorFromHex(0x7A6AEE);
    sureBtn.layer.cornerRadius = 22*scaleXL;
    [sureBtn setTitle:showText(@"确定") forState:UIControlStateNormal];
    [sureBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [sureBtn addTarget:self action:@selector(sureClick) forControlEvents:UIControlEventTouchUpInside];
    [containView addSubview:sureBtn];
    self.sureBtn = sureBtn;
}

#pragma mark - btn click events
- (void)bgClick
{
    [self endEditing:YES];
}

- (void)sureClick
{
    if (self.block) {
        self.block();
    }
    [self hide];
}

- (void)show
{
    [[UIApplication sharedApplication].keyWindow addSubview:self];
}

- (void)hide
{
    [self removeFromSuperview];
}
@end
