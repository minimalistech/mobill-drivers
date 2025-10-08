//
//  NSString+QCExtension.h
//  JotusStripEnd
//
//  Created by 陈立华 on 16/10/8.
//  Copyright © 2016年 陈立华. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NSString (QCExtension)

//字符串转十六进制
+ (NSString*)convertStringToRed:(CGFloat)red Green:(CGFloat)green Blue:(CGFloat)blue;

//int 转十六进制
+ (NSString *)ToHex:(int)tmpid;

+ (NSInteger)numberWithHexString:(NSString *)hexString;

+ (NSString *)checkedStringWithLatticeArray:(NSArray *)finalArray;

+ (NSString *)checkedStringWithLatticeArrayRGB:(NSArray *)finalArray index:(int)index;

+ (NSString *)checkedStringWithData:(NSData *)data;

+ (NSString *)packageStringWith:(NSString *)dataString
                    totalLength:(int)totalLength
                  currentLength:(int)currentLength
                      packageId:(int)packageId;

//针对32设备数据总长度4个字节
+ (NSString *)packageStringWith:(NSString *)dataString
                    totalLength:(int)totalLength
                  currentLength:(int)currentLength
                      packageId:(int)packageId fontsType:(int)fontsType;

+ (NSArray *)getPackageCommandsWithDataString:(NSString *)dataString type:(int)type;

//针对32设备数据总长度4个字节
+ (NSArray *)getPackageCommandsWithDataString:(NSString *)dataString type:(int)type fontsType:(int)fontsType;

/// 校验
+ (NSString *)verifyStringWith:(NSString *)dataString;

// 将数据强制转换,没有拼接01 和03
+ (NSString *)translationWith:(NSString *)dataString;

// 将数据强制转换,已拼接01 和03
+ (NSString *)finalDataWith:(NSString *)dataString;

// 判断字符串是否包含中文
+ (BOOL)hasChinese:(NSString *)originString;

/// 判断是否全是数字
+ (BOOL)isNumber:(NSString *)originString;

// 将强制转换后的数据反解析
+ (NSArray *)decodeResultWith:(NSString *)dataString;

- (NSArray *)rgbArray;

- (NSMutableAttributedString *)attributeStringWithRgbsArray:(NSArray *)rgbsArray;

@end
