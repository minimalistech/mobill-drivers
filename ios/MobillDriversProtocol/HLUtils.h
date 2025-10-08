//
//  HLUtils.h
//  CoolLED1248
//
//  Created by Harvey on 2022/4/3.
//  Copyright © 2022 Haley. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FLAnimatedImage.h"
#import "ColorItemModel32.h"
#import "ColorTextModel32.h"
#import "HLColorTextItem.h"
#import "PixelRGB.h"
#import "AnimationModel32.h"

@class JTCommon;

NS_ASSUME_NONNULL_BEGIN

@interface HLUtils : NSObject

+ (NSString *)documentPath;

+ (UIViewController *)topVC;

+ (void)sendEmailToUs;

+ (UIEdgeInsets)safeEdgeInset;

/// 从 7开始，状态栏高度包含状态栏
+ (CGFloat)navigateHeight;

+ (CGFloat)statusHeight;

+ (BOOL)isLiuHaiScreen;

// 涂鸦页面(横屏页面)的导航栏高度
+ (CGFloat)graffNavigateHeight;

/// 将点阵数据转换为二进制数据
+ (NSData *)dataWithLatticeArray:(NSArray *)latticeArray;

/// 将文字的二进制数据转换位点阵数据
+ (NSArray *)arrayWithOriginData:(NSData *)originData;

// 32屏幕将文字的二进制数据转换位点阵数据
+ (NSArray *)arrayWithOriginData:(NSData *)originData wordShowHeight:(NSInteger)wordShowHeight;

/// 文字的二进制数据转换为点阵数据，旋转后，再次转换二进制数据
+ (NSData *)dataWithOriginData:(NSData *)originData degree:(int)degree;
/// 将图案的数据数组转换为点阵图，旋转后，再次转换为数据数组
+ (NSArray *)arrayWithOriginArray:(NSArray *)originArray degree:(int)degree;

//字节数组转化为二维数组
+ (NSArray *)showArrayWithData:(NSArray *)showData font:(NSInteger)font;

+ (NSData *)rotateArrayData:(NSData *)originData font:(NSInteger)font degree:(int)degree;

/// 旋转点阵数据
/// - Parameters:
///   - array: 点阵数据数组
///   - degree: 旋转的角度
+ (NSArray *)rotateArray:(NSArray *)array degree:(int)degree;

/// 居中优化点阵数据
+ (NSArray *)centerOptArrayWithLatticeArray:(NSArray *)latticeArray;

/// 优化点阵数据
+ (NSArray *)optArrayWithLatticeArray:(NSArray *)latticeArray;

+ (NSArray *)optArrayWithLatticeArray:(NSArray *)latticeArray wordShowHeight:(NSInteger)wordShowHeight;

/// 优化点阵数据
+ (NSArray *)optArrayWithLatticeArray:(NSArray *)latticeArray fontSpace:(int)fontSpace fontSize:(int)fontSize;

+ (NSArray *)optArrayWithLatticeArray:(NSArray *)latticeArray wordShowHeight:(NSInteger)wordShowHeight  fontSpace:(int)fontSpace fontSize:(int)fontSize;

/// 将点阵数据转换为 颜色点阵数据
+ (NSArray *)colorArrayWithLatticeArray:(NSArray *)latticeArray rgbArray:(NSArray *)rgbArray;
+ (NSArray *)colorArrayWithLatticeNumArray:(NSArray *)latticeArray rgbArray:(NSArray *)rgbArray;
/// 将数组数据转换为点阵数据数组
+ (NSArray *)showArrayWithData:(NSArray *)showData;

+ (NSArray *)showArrayWithData:(NSArray *)showData wordShowHeight:(NSInteger)wordShowHeight;

/// 添加空列
/// - Parameters:
///   - element: 元素
///   - rows: 行数
+ (NSArray *)emptyColArrayWith:(NSObject *)element rows:(int)rows;

+ (NSString *)turn10to2:(int)orginNumber;

//因为OC直接对字节操作不方便，所以字节放到Data里进行储存，对Data里的字节进行操作，需要将Data转化为字符串，再对字符串进行操作

//字节类型长字符串转换Data类型
+(NSData *)stringToData:(NSString *)originString;

//2个长度字符串，转换为一个Byte字节，并转化为Data输出
+ (NSData *)stringToByte:(NSString*)string;

//将data转换成一个长字符串进行存储
+ (NSString *)dataToString:(NSData*)data;

//将NSArray转换成一个长字符串进行存储
+ (NSString *)arrToString:(NSArray*)arr;

/// 将文字的二进制数据向下移位
+ (NSData *)iArrayRightShift:(NSData *)originData colBytes:(int)colBytes;

/// 将colBytes个字节向下移动space位
+ (NSData *)iArrayRightShift:(NSData *)originData originColBytes:(int)originColBytes space:(NSInteger)space targetRow:(int)targetRow;

//二维数组上下增加space数据
+ (NSArray *)iArrayRightShift:(NSArray *)originArr space:(NSInteger)space;

+ (NSData *)arrayToByte:(NSArray *)intArray;
+ (NSArray *)byteToArray:(NSData *)data;

+(void)setFLAnimatedImageView:(FLAnimatedImageView *)gif name:(NSString *)name;

+(UIImage *)getNewImage:(UIImage *)image color:(UIColor *)newColor;

+ (NSMutableAttributedString *)attributedStringWith:(ColorItemModel32 *) textModel;

+ (int)colorExchangeFloat:(float)colorValue;

+(NSString *)getIconGraffitikey;

+(NSString *)getIconAnimationkey;

+ (BOOL)isThaiCompositeCharacter:(NSString *)character;

+ (BOOL)isHindiCompositeCharacter:(NSString *)character;

+ (BOOL)isArabicCompositeCharacter:(NSString *)character;

+(NSArray *)generateDataFromImageFont:(int )row text:(NSString *)text fontSize:(int)fontSize languageType:(int)languageTyp isBold:(int)isBold;

/**
 *  把输入文字的数据转换为指定大小的文字数据进行输出
 * @param input 输入文字的显示数据
 * @param srcSize 输入文字的大小
 * @param dstSize 输出文字的大小
 * @return 转换后的文字显示数据
 */
+ (NSData *)transferFontData:(NSData *)input srcSize:(NSInteger)srcSize dstSize:(NSInteger)dstSize;

+(NSString *)getTimeTag;

+(int)getUcolor:(NSArray *)rgbData;

+(NSArray *)getEmojiDataWith:(NSString *)gifName;

+(NSMutableArray *)getPixelRGBArr:(NSArray *)emojiArr;

+(NSMutableArray *)getPixelArr:(NSArray *)emojiArr;

+(AnimationModel32 *)getBgDataWith:(NSString *)gifNameDefault;

+(NSDictionary *)getDicDetailWithFileName:(NSString *)fileName;

+ (uint8_t)combineBits:(BOOL[8])bits;

+ (NSArray *)horizontalMirror:(NSArray *)matrix;

+ (NSArray *)verticalMirror:(NSArray *)matrix;

+ (NSArray *)generateNumbersUpTo:(NSInteger)max withMultiple:(NSInteger)m;

//promptItemType用于标识发送节目提示0、默认，1、同步状态，2、发送 
+(void)showPromptItemRank:(int)itemRank;

+(NSString *)reverseAndSwapPairs:(NSString *)input;

+(NSString *)reverseStringByFourCharacters:(NSString *)input;

+ (NSArray *)emptyColArrayWith:(NSObject *)element rows:(int)rows;
@end

NS_ASSUME_NONNULL_END
