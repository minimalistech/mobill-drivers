//
//  ColorItemModel32.h
//  CoolLED1248
//
//  Created by 君同 on 2023/3/13.
//  Copyright © 2023 Haley. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ColorItemModel32 : NSObject<NSCoding>

// 时间戳，需要时作为id使用
@property (nonatomic, assign)NSInteger timestampInMilliseconds;

//设备类型，以及宽高分辨率作为标识符
@property (nonatomic, copy) NSString *itemDeviceIdentify;

// 该节目包含了多少个内容
@property (nonatomic, assign)int itemContentCount;

// 在有多个节目的情况下，显示多少次后切换到下一个节目
@property (nonatomic, assign)int itemShowTime;

// 是否被选中，节目界面对应的标记
@property (nonatomic, assign) BOOL isSelected;

// 选中时显示编号
@property (nonatomic, assign)int selectIndex;

// 行驶状态选中时标记
@property (nonatomic, assign)BOOL isSelectedState;

@property (nonatomic, copy) NSString *itemName;

//模板类型
//屏幕高度32时，1、为1行文字，2、为2行文字，3、左图片右1行文字，4、左图片右2行文字，5、左1行文字右图片，6、左2行文字右图片，7、为一帧静态涂鸦，8、为动画
//屏幕高度16时，1、为1行文字，2、为一帧静态涂鸦，3、为动画，4、左图片右1行文字，5、左1行文字右图片，
//屏幕高度48时，1、为1行文字，2、为2行文字各24行文字，3、为2行文字上16文字下32文字，4、为2行文字上32文字下16文字，5、为3行16文字
@property (nonatomic, assign)int masterplateCaseType;

//对应的ColorTextModel32数组 文字
@property (nonatomic, strong) NSArray *colorTextModel32Arr;

//当为全彩CoolLEDU、CoolLEDUiLedBike时，出现屏幕分辨率过大，image图片的形式保存,否则内存过大崩溃
@property (nonatomic, copy) NSArray *graffitiImageName32Arr;

//对应的GraffitiModel32数组 涂鸦
@property (nonatomic, strong) NSArray *graffitiModel32Arr;

//当为全彩CoolLEDU、CoolLEDUiLedBike时，出现屏幕分辨率过大，动画帧数过多，需要以gif图片的形式保存,否则内存过大崩溃
@property (nonatomic, copy) NSArray *animationGIFName32Arr;

//对应的AnimationModel32数组 动画
@property (nonatomic, strong) NSArray *animationModel32Arr;

//对应的ClockTime数组  时间组件-数字结构时间
@property (nonatomic, strong) NSArray *clockTimeModelArr;

//对应的DateTime数组 日期组件
@property (nonatomic, strong) NSArray *dateTimeModelArr;

//对应的Scoreboard数组 计分板组件
@property (nonatomic, strong) NSArray *scoreboardModelArr;

//对应的Countdown数组 计时器组件
@property (nonatomic, strong) NSArray *countdownModelArr;

@end

NS_ASSUME_NONNULL_END
