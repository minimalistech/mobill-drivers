//
//  ColorTextModel32.h
//  CoolLED1248
//
//  Created by 君同 on 2023/3/11.
//  Copyright © 2023 Haley. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ColorTextModel32 : NSObject<NSCoding>{
    int _speedData;
}

#pragma mark - 节目对象（内容、颜色、边框组合部分）

//当前节目对象使用了字体，字体对应屏幕的分辨率的高度度，0为高度32，1为高度16，2为高度12，3为高度24，4为高度20，5为高度48
@property (nonatomic, assign)int masterplateWordType;

//该对象为内容、颜色、边框组合

// 原始文字
@property (nonatomic, copy) NSString *originText;
// 单个文字item数组
@property (nonatomic, strong) NSArray *textItems;
// 是否加粗
@property (nonatomic, assign) BOOL bold;
// 旋转的度数
//0、0度，1、90度，2、180度，3、270度，
@property (nonatomic, assign) int degree;

// 字号
//取值范围12、14、16、24、36（字号为0时，字体自适应）
@property (nonatomic, assign) int font;
//自适应时的自动fontDefaultFit的值的字体大小
@property (nonatomic, assign) int fontDefaultFit;

// 间距
//取值范围1~8
@property (nonatomic, assign) int fontSpace;

// 是否镜像
@property (nonatomic, assign) BOOL isMirror;

//自定义颜色与炫彩色起始行、起试列取值、宽度、高度和文字内容数据中的起始行一样
//A.设置节目内容-文字内容数据格式-自定义文字效果

// 该内容显示的时候，和其他层级的内容的混合方式
@property (nonatomic, assign)int coverType ;
// 该内容显示起始行
@property (nonatomic, assign)int startRow;
// 该内容显示起始列
@property (nonatomic, assign)int startCol;
// 该内容显示宽度
@property (nonatomic, assign)int widthData;
// 该内容显示高度
@property (nonatomic, assign)int heightData;
// 显示模式
@property (nonatomic, assign)int showModel;
// 显示速度（显示模式的对应速度）
@property (nonatomic, assign)int speedData;
// 把文字速度调整范围设为1-50，兼容之前的1-8的范围
@property (nonatomic, assign)int isTrueSpeedData;
//停留时间（一屏显示完成后的停留时间）
@property (nonatomic, assign)int stayTime;
//移动间隔
@property (nonatomic, assign)int movespace;

//C.设置节目内容-炫彩文字效果

// 文字颜色效果
@property (nonatomic, assign)int dazzleShowModel;
// 文字颜色效果变化速度
@property (nonatomic, assign)int dazzleSpeedData;
// 文字颜色效果显示方向
@property (nonatomic, assign)int dazzleShowModelDirection;
// 边框编号
@property (nonatomic, assign)int dazzleIndexSelect;
// 颜色数据
@property (nonatomic, copy)NSString *dazzleType;
// 颜色数据长度
@property (nonatomic, assign)int dazzleTypeLength;

//D.设置节目内容-边框内容数据格式

// 该内容显示的时候，和其他层级的内容的混合方式
@property (nonatomic, assign)int coverTypeEdge;
// 该内容显示起始行
@property (nonatomic, assign)int startRowEdge;
// 该内容显示起始列
@property (nonatomic, assign)int startColEdge;
// 该内容显示宽度
@property (nonatomic, assign)int widthDataEdge;
// 该内容显示高度
@property (nonatomic, assign)int heightDataEdge;
// 边框显示效果
@property (nonatomic, assign)int showModelEdge;
// 边框变化速度
@property (nonatomic, assign)int speedDataEdge;
// 边框内容高度
@property (nonatomic, assign)int heightEdge;
// 边框编号
@property (nonatomic, assign)int edgingIndexSelect;
// 边框显示数据
@property (nonatomic, copy)NSString *edgeContent;
// 边框数据的总长度
@property (nonatomic, assign)int edgelenght;

// 该内容、颜色、边框包含了多少个
@property (nonatomic, assign)int itemContentCount;


//判断是否自定义文字效果、是否有炫彩文字效果、是否边框内容数据格式
// 0、无文字效果，1、自定义文字效果，2、炫彩文字效果
@property (nonatomic, assign) int colorShowType;
// 是否边框内容数据格式
@property (nonatomic, assign) BOOL isEdge;

//判断是否只有边框部分
-(BOOL)isOnlyEdge;

@end

NS_ASSUME_NONNULL_END
