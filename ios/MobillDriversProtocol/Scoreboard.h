//
//  Scoreboard.h
//  CoolLED1248
//
//  Created by go on 10/15/24.
//  Copyright © 2024 Haley. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Scoreboard : NSObject<NSCoding>

//设置节目内容-计分板组件数据格式

// 该内容显示的时候，和其他层级的内容的混合方式
@property (nonatomic, assign)int coverTypeScoreboard;

// 小节比分每个数字的高度
@property (nonatomic, assign)int secnumHeightScoreboard;
// 小节比分每个数字的宽度
@property (nonatomic, assign)int secnumWidthScoreboard;
// 小节比分数字数据长度
@property (nonatomic, assign)int secnumDataLenScoreboard;
// 小 节 比 分 数 字（0~9）对应的文字的显示内容。
@property (nonatomic, copy)NSString *secnumDataScoreboard;

// 主队分数显示颜色
@property (nonatomic, assign)int hsColorScoreboard;
// 主队分数显示起始列，相当于X 坐标
@property (nonatomic, assign)int hsStartColumnScoreboard;
// 主队分数显示起始行，相当于Y 坐标
@property (nonatomic, assign)int hsStartRowScoreboard;
// 主队分数显示宽度
@property (nonatomic, assign)int hsWidthScoreboard;
// 主队分数显示高度
@property (nonatomic, assign)int hsHeightScoreboard;

// 客队分数显示颜色
@property (nonatomic, assign)int vsColorScoreboard;
// 客队分数显示起始列，相当于X 坐标
@property (nonatomic, assign)int vsStartColumnScoreboard;
// 客队分数显示起始行，相当于Y 坐标
@property (nonatomic, assign)int vsStartRowScoreboard;
// 客队分数显示宽度
@property (nonatomic, assign)int vsWidthScoreboard;
// 客队分数显示高度
@property (nonatomic, assign)int vsHeightScoreboard;

// 总比分每个数字的高度
@property (nonatomic, assign)int totalnumHeightScoreboard;
// 总比分每个数字的宽度
@property (nonatomic, assign)int totalnumWidthScoreboard;
// 总比分数字数据长度
@property (nonatomic, assign)int totalnumDataLenScoreboard;
// 总比分数字（0~9）对应的文字的显示内容。
@property (nonatomic, copy)NSString *totalnumDataScoreboard;

// 主队总分数显示颜色
@property (nonatomic, assign)int htsColorScoreboard;
// 主队总分数显示起始列，相当于 X 坐标
@property (nonatomic, assign)int htsStartColumnScoreboard;
// 主队总分数显示起始行，相当于Y 坐标
@property (nonatomic, assign)int htsStartRowScoreboard;
// 主队总分数显示宽度
@property (nonatomic, assign)int htsWidthScoreboard;
// 主队总分数显示高度
@property (nonatomic, assign)int htsHeightScoreboard;

// 客队总分数显示颜色
@property (nonatomic, assign)int vtsColorScoreboard;
// 客队总分数显示起始列，相当于 X 坐标
@property (nonatomic, assign)int vtsStartColumnScoreboard;
// 客队总分数显示起始行，相当于Y 坐标
@property (nonatomic, assign)int vtsStartRowScoreboard;
// 客队总分数显示宽度
@property (nonatomic, assign)int vtsWidthScoreboard;
// 客队总分数显示高度
@property (nonatomic, assign)int vtsHeightScoreboard;

// 时间每个数字的高度
@property (nonatomic, assign)int timenumHeightScoreboard;
// 时间每个数字的宽度
@property (nonatomic, assign)int timenumWidthScoreboard;
// 时间数字数据长度
@property (nonatomic, assign)int timenumDataLenScoreboard;
// 时间数字（0~9）对应的文字的显示内容。
@property (nonatomic, copy)NSString *timenumDataScoreboard;

// 分钟显示颜色
@property (nonatomic, assign)int minColorScoreboard;
// 分钟显示起始列，相当于 X 坐标
@property (nonatomic, assign)int minStartColumnScoreboard;
// 分钟显示起始行，相当于 Y 坐标
@property (nonatomic, assign)int minStartRowScoreboard;
// 分钟显示宽度
@property (nonatomic, assign)int minWidthScoreboard;
// 分钟显示高度
@property (nonatomic, assign)int minHeightScoreboard;

// 分隔符颜色
@property (nonatomic, assign)int spacemColorScoreboard;
// 分割 符显 示起 始列，相当于 X 坐标
@property (nonatomic, assign)int spacemStartColumnScoreboard;
// 分割 符显 示起 始行，相当于 Y 坐标
@property (nonatomic, assign)int spacemStartRowScoreboard;
// 分隔符显示宽度
@property (nonatomic, assign)int spacemWidthScoreboard;
// 分隔符显示高度
@property (nonatomic, assign)int spacemHeightScoreboard;
// 分割符显示数据长度
@property (nonatomic, assign)int spacemDataLenScoreboard;
// 分割符的显示数据
@property (nonatomic, copy)NSString *spacemDataScoreboard;

// 秒显示颜色
@property (nonatomic, assign)int secColorScoreboard;
// 秒显示起始列，相当于 X 坐标
@property (nonatomic, assign)int secStartColumnScoreboard;
// 秒显示起始行，相当于 Y 坐标
@property (nonatomic, assign)int secStartRowScoreboard;
// 秒显示宽度
@property (nonatomic, assign)int secWidthScoreboard;
// 秒显示高度
@property (nonatomic, assign)int secHeightScoreboard;

@end

NS_ASSUME_NONNULL_END
