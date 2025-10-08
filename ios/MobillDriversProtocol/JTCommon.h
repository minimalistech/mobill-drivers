//
//  JTCommon.h
//  CoolLED1248
//
//  Created by 君同 on 2023/3/13.
//  Copyright © 2023 Haley. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GraffitiModel32.h"
#import "AnimationModel32.h"
#import "ColorTextModel32.h"
#import "ColorItemModel32.h"
#import "FLAnimatedImage.h"
#import <UIKit/UIKit.h>
#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "EyeItemModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface JTCommon : NSObject

+ (NSString *)filePathWithKey:(NSString *)textDataListKey;

+ (NSString *)filePathDriveStateWithKey:(NSInteger)state;

+ (UIImage *)createImageWithColor:(UIColor *)color;

+ (NSArray *)getSystemEdging;

+ (NSArray *)getSystemEdgingWithLine:(NSInteger)line;

+ (NSArray *)getSystemDazzle;

+ (NSArray *)getSystemDazzleCoolLEDU;

//对于节目对象计算节目内容数量
+ (int)getItemContentCount:(ColorItemModel32 *)colorItemModel32;

//返回节目类型1、文字 2、涂鸦 3、动画
+ (int)getColorItemModel32Type:(ColorItemModel32 *)colorItemModel32;

//创建文字模型对象
+ (ColorTextModel32 *)getColorTextModel32WithCoverType:(int)coverTypeP
                                               startRow:(int)startRowP
                                               startCol:(int)startColP
                                              widthData:(int)widthDataP
                                             heightData:(int)heightDataP;

+ (NSString *)getWordColorFrom:(NSString *)rgbString;

+ (ColorItemModel32 *)getNewColorItemModel32From:(ColorItemModel32 *)colorItemModel32Origin;

+ (EyeItemModel *)getEyeItemModelFrom:(EyeItemModel *)eyeItemModelOrigin;

+(NSArray *)copyDataSub:(NSArray *)dataAnimationOrigin;

+ (BOOL)compareColorItemModel32Origin:(ColorItemModel32 *)colorItemModel32Origin colorItemModel32New:(ColorItemModel32 *)colorItemModel32New;

//判断设备是否有密码
+ (BOOL)hasPasswordDevice;

+ (EyeItemModel *)getEyeItemModel;

//模板类型
//屏幕高度32时，1、为1行文字，2、为2行文字，3、左图片右1行文字，4、左图片右2行文字，5、左1行文字右图片，6、左2行文字右图片，7、为一帧静态涂鸦，8、为动画
//屏幕高度16时，1、为1行文字，2、为一帧静态涂鸦，3、为动画，4、左图片右1行文字，5、左1行文字右图片，
//屏幕高度48时，1、为1行文字，2、为2行文字各24行文字，3、为2行文字上16文字下32文字，4、为2行文字上32文字下16文字，5、为3行16文字
+ (ColorItemModel32 *)getColorItemModel32WithMasterplateCaseType:(int) masterplateCaseType;

//itemCreateType节目类型，1、文字 2、涂鸦 3、动画
+ (ColorItemModel32 *)getColorItemModel32;

//构建节目对象（内容、颜色、边框组合部分）
+ (ColorTextModel32 *)getColorTextModel32WithCoverType:(int) coverTypeP startRow:(int) startRowP startCol:(int) startColP widthData:(int) widthDataP heightData:(int) heightDataP;

//构建节目对象（涂鸦内容数据格式）
+ (GraffitiModel32 *)getGraffitiModel32WithCoverType:(int) coverTypeP startRow:(int) startRowP startCol:(int) startColP widthData:(int) widthDataP heightData:(int) heightDataP;

//构建节目对象 (动画内容数据格式)
+ (AnimationModel32 *)getAnimationModel32WithCoverType:(int) coverTypeP startRow:(int) startRowP startCol:(int) startColP widthData:(int) widthDataP heightData:(int) heightDataP;

//把点阵数组转化为字符串
+ (NSString *)resultStrWithData:(NSArray *)data;

+ (BOOL)containMaterial;

//获取每个像素的宽度
+(CGFloat)getPixelWidth;

//对于当前屏幕显示进行居中处理
+(NSDictionary *)makeWordCenter:(NSMutableArray *) dataM cols:(int)cols rows:(int)rows;

//通过动画类型点阵生成字符串类型字节数组
+(NSString *)getStrFromAnimationArr:(NSArray *)data;

+(NSArray *)getShareDataFrom:(NSArray *)frameArr;

+(NSString *)getNowTimeTimestamp;

#pragma mark - tool method
+ (NSArray *)resultArrayWithDataArray:(NSArray *)data;

+(NSArray *)frameToRGBByte:(NSArray *)animationData;

+ (NSDictionary *)parseGIFWithData:(NSData *)gifData;

+(NSData *)makeAnimatedGif:(NSArray *)imgArray withDelayTime:(CGFloat)delayTime;

+(void)saveAnimatedGifPhotoAlbum:(NSArray *)imgArray withDelayTime:(CGFloat)delayTime gifName:(NSString *)gifName;

+(void)saveAnimatedGif:(NSArray *)imgArray withDelayTime:(CGFloat)delayTime gifName:(NSString *)gifName;

+ (void)saveImageToPhotoLibrary:(UIImage *)image;

+ (UIImage *)createImageFromPixelData:(NSArray *)pixelData width:(NSUInteger)width height:(NSUInteger)height scale:(CGFloat)scale;

+ (UIImage *)createImageFromPixelData:(NSArray *)pixelData width:(NSUInteger)width height:(NSUInteger)height  scale:(CGFloat)scale monochrome:(NSString *)rgbString;

+(void)saveGIFToPhotoLibrary:(NSData *)gifData;

//获取图片的原始Data数据
+ (NSArray *)getColorDataDefaultFromImage:(UIImage *)image  scale:(CGFloat)scale;

+ (NSArray *)getDataFromFontImage:(UIImage *)image  scale:(CGFloat)scale;

+ (NSArray *)showDataArrayWithSendData:(NSArray *)sendData frames:(int)frames cols:(int)cols rows:(int)rows deviceType:(NSInteger)deviceType;

+(void)shareGraffitiData:(GraffitiModel32 *)graffitiModel32 vc:(UIViewController *)vc view:(UIView *)view;

+(void)shareAnimationData:(AnimationModel32 *)animationModel32 vc:(UIViewController *)vc view:(UIView *)view;

//state： 1表示图片，2表示gif type：1表示CoolLEDU设备
+ (NSArray *)getImageNameState:(int)state type:(NSInteger)type cols:(int)cols rows:(int)rows;

+(NSString *)getElementName:(NSString *)index;

+(void)saveGIFToPhotoAlbumwithAnimationModel32:(AnimationModel32 *) animationModel32;

+(ColorItemModel32 *)saveGIFwithColorItemModel32:(ColorItemModel32 *) colorItemModel32Data;

+(ColorItemModel32 *)saveGIFDeleteDataAnimation:(ColorItemModel32 *) colorItemModel32Data;

+(void)deleteGIFwithColorItemModel32:(ColorItemModel32 *) colorItemModel32Data;

+(ColorItemModel32 *)getDataAnimationfromGIF:(ColorItemModel32 *)textModel;

+(NSData *)gifDecoding:(NSData *)data;

+(NSData* )enlargeGifPixels:(NSData*) inputData :(CGFloat) scale;

+ (NSArray *)getSendDataFromDic:(NSDictionary *)dic;

+ (NSArray *)getCopyFrame:(NSArray *)frame;

+(float)ratioStringByte:(NSInteger)wordShowHeight;

+(void)saveDriveStateData:(NSInteger)state data:(ColorItemModel32 *)textModel;

//对文字对象设置默认字体
+(ColorTextModel32 *)getDefaultFontType:(ColorTextModel32 *)colorTextModel32 isLargeEdge:(BOOL)isLargeEdge;

+(NSArray * )getMaxFontArr:(ColorTextModel32 *)colorTextModel32;

//获取字库类型
+(NSData *)getFontTypeFont:(NSInteger)font bold:(BOOL)bold;

+(NSData *)getOriginDataWordShowHeight:(NSInteger)wordShowHeight asciiCode:(int)asciiCode font:(NSInteger)font unicodeData:(NSData *)unicodeData degree:(int)degree;

+(NSData *)getOriginDataWordShowHeight:(NSInteger)wordShowHeight  font:(NSInteger)font emojiData:(NSData *)emojiData degree:(int)degree;

+(NSArray *)getEmojiArrTransformShowHeight:(NSInteger)wordShowHeight  font:(NSInteger)font emojiArr:(NSArray *)emojiArr degree:(int)degree;

+(FLAnimatedImage *)getGIFWithName:(NSString *)gifName;
@end

NS_ASSUME_NONNULL_END
