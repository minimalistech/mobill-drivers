//
//  JTCommon.m
//  CoolLED1248
//
//  Created by 君同 on 2023/3/13.
//  Copyright © 2023 Haley. All rights reserved.
//

#import "JTCommon.h"
#import <Photos/Photos.h>
#import "HLUtils.h"
#import "DNApplication.h"
#import "Const_Header.h"
#import "ThemManager.h"

@implementation JTCommon

+ (NSString *)filePathWithKey:(NSString *)textDataListKey
{
    if (textDataListKey.length == 0) {
        return nil;
    }
    
    // 获取沙盒Document路径
    NSString *filePath = [HLUtils documentPath];
    //文件路径
    NSString *uniquePath = [filePath stringByAppendingPathComponent:textDataListKey];
    
    return uniquePath;
}

+ (NSString *)filePathDriveStateWithKey:(NSInteger)state
{
    NSString *driveStatetKey = [NSString stringWithFormat:@"DriveState%ld",state];
    
    // 获取沙盒Document路径
    NSString *filePath = [HLUtils documentPath];
    //文件路径
    NSString *uniquePath = [filePath stringByAppendingPathComponent:driveStatetKey];
    
    return uniquePath;
}

+ (UIImage *)createImageWithColor:(UIColor *)color

{
    
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    
    UIGraphicsBeginImageContext(rect.size);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    
    CGContextFillRect(context, rect);
    
    UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return theImage;
}

+ (NSArray *)getSystemEdging{
    NSArray *edgingArr = [[NSArray alloc] init];
    if([CurrentDeviceType isEqual:@"CoolLEDM"]){
        edgingArr = @[@{@"name":showText(@"无边框"),@"imageName":@"无边框"},@{@"name":[NSString stringWithFormat:@"%@1",showText(@"七彩")],@"imageName":@"七彩1",@"imageEdgeName":@"边框七彩1",@"edgeContent":@"808000000080800080808000008000000080808080",@"heightEdge":@(1),@"edgelenght":@(21)},@{@"name":[NSString stringWithFormat:@"%@2",showText(@"七彩")],@"imageName":@"七彩2",@"imageEdgeName":@"边框七彩2",@"edgeContent":@"800080000000000000008000800000008000800080000000000080000000000000008000800080008000",@"heightEdge":@(1),@"edgelenght":@(42)},@{@"name":[NSString stringWithFormat:@"%@3",showText(@"七彩")],@"imageName":@"七彩3",@"imageEdgeName":@"边框七彩3",@"edgeContent":@"808080808080000000000000000000808080808080000000000000808080808080808080000000000000808080000000000000000000000000808080808080808080808080000000",@"heightEdge":@(1),@"edgelenght":@(72)},@{@"name":[NSString stringWithFormat:@"%@1",showText(@"三色")],@"imageName":@"三色1",@"imageEdgeName":@"边框三色1",@"edgeContent":@"808080808000000000000000000000000000000080808080800000000000000000000000000000008080808080",@"heightEdge":@(1),@"edgelenght":@(45)},@{@"name":[NSString stringWithFormat:@"%@2",showText(@"三色")],@"imageName":@"三色2",@"imageEdgeName":@"边框三色2",@"edgeContent":@"800000000000000080000000000000008000",@"heightEdge":@(1),@"edgelenght":@(18)},@{@"name":[NSString stringWithFormat:@"%@3",showText(@"三色")],@"imageName":@"三色3",@"imageEdgeName":@"边框三色3",@"edgeContent":@"808000000000808080008080808000800000000000000000",@"heightEdge":@(1),@"edgelenght":@(24)},@{@"name":[NSString stringWithFormat:@"%@1",showText(@"红色")],@"imageName":@"红色1",@"imageEdgeName":@"边框红色1",@"edgeContent":@"800000",@"heightEdge":@(1),@"edgelenght":@(3)},@{@"name":[NSString stringWithFormat:@"%@2",showText(@"红色")],@"imageName":@"红色2",@"imageEdgeName":@"边框红色2",@"edgeContent":@"800000000000",@"heightEdge":@(1),@"edgelenght":@(6)},@{@"name":[NSString stringWithFormat:@"%@3",showText(@"红色")],@"imageName":@"红色3",@"imageEdgeName":@"边框红色3",@"edgeContent":@"808080800000000000000000000000000000000000000000",@"heightEdge":@(1),@"edgelenght":@(24)},@{@"name":[NSString stringWithFormat:@"%@1",showText(@"四色")],@"imageName":@"四色1",@"imageEdgeName":@"边框四色1",@"edgeContent":@"808080808080808080808080808080000000000080808080808080808080000000000080808080808080808080000000000080808080808080808080",@"heightEdge":@(1),@"edgelenght":@(60)},@{@"name":[NSString stringWithFormat:@"%@2",showText(@"四色")],@"imageName":@"四色2",@"imageEdgeName":@"边框四色2",@"edgeContent":@"808080000080808000008080800000000000000080808000008080800000000000000080808000008080800000000000000080808000008080800000",@"heightEdge":@(1),@"edgelenght":@(60)},@{@"name":[NSString stringWithFormat:@"%@3",showText(@"四色")],@"imageName":@"四色3",@"imageEdgeName":@"边框四色3",@"edgeContent":@"808080000000000000000000000000808080000000808080000000000000808080808080",@"heightEdge":@(1),@"edgelenght":@(36)},@{@"name":[NSString stringWithFormat:@"%@4",showText(@"四色")],@"imageName":@"四色4",@"imageEdgeName":@"边框四色4",@"edgeContent":@"808080000000000000000000000000000000000000000000008080800000000000000080808000000000000000000000000080808000008080800000",@"heightEdge":@(1),@"edgelenght":@(60)},@{@"name":[NSString stringWithFormat:@"%@1",showText(@"绿色")],@"imageName":@"绿色1",@"imageEdgeName":@"边框绿色1",@"edgeContent":@"008000",@"heightEdge":@(1),@"edgelenght":@(3)},@{@"name":[NSString stringWithFormat:@"%@2",showText(@"绿色")],@"imageName":@"绿色2",@"imageEdgeName":@"边框绿色2",@"edgeContent":@"000080000000",@"heightEdge":@(1),@"edgelenght":@(6)},@{@"name":[NSString stringWithFormat:@"%@3",showText(@"绿色")],@"imageName":@"绿色3",@"imageEdgeName":@"边框绿色3",@"edgeContent":@"000000000000000080808080000000000000000000000000",@"heightEdge":@(1),@"edgelenght":@(24)},@{@"name":[NSString stringWithFormat:@"%@1",showText(@"黄色")],@"imageName":@"黄色1",@"imageEdgeName":@"边框黄色1",@"edgeContent":@"808000",@"heightEdge":@(1),@"edgelenght":@(3)},@{@"name":[NSString stringWithFormat:@"%@2",showText(@"黄色")],@"imageName":@"黄色2",@"imageEdgeName":@"边框黄色2",@"edgeContent":@"800080000000",@"heightEdge":@(1),@"edgelenght":@(6)},@{@"name":[NSString stringWithFormat:@"%@3",showText(@"黄色")],@"imageName":@"黄色3",@"imageEdgeName":@"边框黄色3",@"edgeContent":@"808080800000000080808080000000000000000000000000",@"heightEdge":@(1),@"edgelenght":@(24)}];
    }else if ([CurrentDeviceType isEqual:@"CoolLEDU"]){
        edgingArr = @[@{@"name":showText(@"无边框"),@"imageName":@"无边框"},@{@"name":[NSString stringWithFormat:@"%@1",showText(@"七彩")],@"imageName":@"七彩0",@"imageEdgeName":@"边框七彩0",@"edgeContent":@"0F000F200F400F600F800FA00FC00FF00CF00AF008F006F004F002F000F000F200F400F600F800FA00FC00FF00CF00AF008F006F004F002F000F020F040F060F080F0A0F0C0F0F0F0F0C0F0A0F080F060F040F020F00",@"heightEdge":@(1),@"edgelenght":@(86)},@{@"name":[NSString stringWithFormat:@"%@2",showText(@"七彩")],@"imageName":@"七彩1",@"imageEdgeName":@"边框七彩1",@"edgeContent":@"0F000FF000F000FF000F0F0F0FFF",@"heightEdge":@(1),@"edgelenght":@(14)},@{@"name":[NSString stringWithFormat:@"%@3",showText(@"七彩")],@"imageName":@"七彩2",@"imageEdgeName":@"边框七彩2",@"edgeContent":@"0F0000000FF0000000F0000000FF0000000F00000F0F00000FFF0000",@"heightEdge":@(1),@"edgelenght":@(28)},@{@"name":[NSString stringWithFormat:@"%@4",showText(@"七彩")],@"imageName":@"七彩3",@"imageEdgeName":@"边框七彩3",@"edgeContent":@"0F000F000F000FF00FF00FF000F000F000F000FF00FF00FF000F000F000F0F0F0F0F0F0F0FFF0FFF0FFF000000000000",@"heightEdge":@(1),@"edgelenght":@(48)},@{@"name":[NSString stringWithFormat:@"%@1",showText(@"三色")],@"imageName":@"三色1",@"imageEdgeName":@"边框三色1",@"edgeContent":@"0F000F000F000F000F0000F00F000F000F000F00000F0F000F000F000F00",@"heightEdge":@(1),@"edgelenght":@(30)},@{@"name":[NSString stringWithFormat:@"%@2",showText(@"三色")],@"imageName":@"三色2",@"imageEdgeName":@"边框三色2",@"edgeContent":@"0F00000000F00000000F0000",@"heightEdge":@(1),@"edgelenght":@(12)},@{@"name":[NSString stringWithFormat:@"%@3",showText(@"三色")],@"imageName":@"三色3",@"imageEdgeName":@"边框三色3",@"edgeContent":@"0FF00F0000F000F000F000F00F000FF0",@"heightEdge":@(1),@"edgelenght":@(16)},@{@"name":[NSString stringWithFormat:@"%@1",showText(@"红色")],@"imageName":@"红色1",@"imageEdgeName":@"边框红色1",@"edgeContent":@"0F00",@"heightEdge":@(1),@"edgelenght":@(2)},@{@"name":[NSString stringWithFormat:@"%@2",showText(@"红色")],@"imageName":@"红色2",@"imageEdgeName":@"边框红色2",@"edgeContent":@"0F000000",@"heightEdge":@(1),@"edgelenght":@(4)},@{@"name":[NSString stringWithFormat:@"%@3",showText(@"红色")],@"imageName":@"红色3",@"imageEdgeName":@"边框红色3",@"edgeContent":@"0F000F000F000F000000000000000000",@"heightEdge":@(1),@"edgelenght":@(16)},@{@"name":[NSString stringWithFormat:@"%@1",showText(@"四色")],@"imageName":@"四色1",@"imageEdgeName":@"边框四色1",@"edgeContent":@"0FFF0FFF0FFF0FFF0FFF0FF00FF00FF00FF00FF00F0F0F0F0F0F0F0F0F0F00FF00FF00FF00FF00FF",@"heightEdge":@(1),@"edgelenght":@(40)},@{@"name":[NSString stringWithFormat:@"%@2",showText(@"四色")],@"imageName":@"四色2",@"imageEdgeName":@"边框四色2",@"edgeContent":@"0FFF0FFF0FFF000000000FF00FF00FF0000000000F0F0F0F0F0F0000000000FF00FF00FF00000000",@"heightEdge":@(1),@"edgelenght":@(40)},@{@"name":[NSString stringWithFormat:@"%@3",showText(@"四色")],@"imageName":@"四色3",@"imageEdgeName":@"边框四色3",@"edgeContent":@"0F000F000F0000F000F000F0000F000F000F00FF00FF00FF",@"heightEdge":@(1),@"edgelenght":@(24)},@{@"name":[NSString stringWithFormat:@"%@4",showText(@"四色")],@"imageName":@"四色4",@"imageEdgeName":@"边框四色4",@"edgeContent":@"0F000F000F000000000000F000F000F000000000000F000F000F0000000000FF00FF00FF00000000",@"heightEdge":@(1),@"edgelenght":@(40)},@{@"name":[NSString stringWithFormat:@"%@1",showText(@"绿色")],@"imageName":@"绿色1",@"imageEdgeName":@"边框绿色1",@"edgeContent":@"00F0",@"heightEdge":@(1),@"edgelenght":@(2)},@{@"name":[NSString stringWithFormat:@"%@2",showText(@"绿色")],@"imageName":@"绿色2",@"imageEdgeName":@"边框绿色2",@"edgeContent":@"00F00000",@"heightEdge":@(1),@"edgelenght":@(4)},@{@"name":[NSString stringWithFormat:@"%@3",showText(@"绿色")],@"imageName":@"绿色3",@"imageEdgeName":@"边框绿色3",@"edgeContent":@"00F000F000F000F00000000000000000",@"heightEdge":@(1),@"edgelenght":@(16)},@{@"name":[NSString stringWithFormat:@"%@1",showText(@"黄色")],@"imageName":@"黄色1",@"imageEdgeName":@"边框黄色1",@"edgeContent":@"0FF0",@"heightEdge":@(1),@"edgelenght":@(2)},@{@"name":[NSString stringWithFormat:@"%@2",showText(@"黄色")],@"imageName":@"黄色2",@"imageEdgeName":@"边框黄色2",@"edgeContent":@"0FF00000",@"heightEdge":@(1),@"edgelenght":@(4)},@{@"name":[NSString stringWithFormat:@"%@3",showText(@"黄色")],@"imageName":@"黄色3",@"imageEdgeName":@"边框黄色3",@"edgeContent":@"0FF00FF00FF00FF00000000000000000",@"heightEdge":@(1),@"edgelenght":@(16)}];
    }else if ([CurrentDeviceType isEqual:@"CoolLEDC"]){
        edgingArr = @[@{@"name":showText(@"无边框"),@"imageName":@"无边框"},@{@"name":[NSString stringWithFormat:@"%@1",showText(@"红色")],@"imageName":@"红色2",@"edgeContent":@"8000",@"heightEdge":@(1),@"edgelenght":@(2)},@{@"name":[NSString stringWithFormat:@"%@2",showText(@"红色")],@"imageName":@"红色3",@"edgeContent":@"80800000",@"heightEdge":@(1),@"edgelenght":@(8)},@{@"name":[NSString stringWithFormat:@"%@3",showText(@"红色")],@"imageName":@"红色3",@"edgeContent":@"8080808000000000",@"heightEdge":@(1),@"edgelenght":@(8)},@{@"name":[NSString stringWithFormat:@"%@4",showText(@"红色")],@"imageName":@"红色3",@"edgeContent":@"80808080808080800000000000000000",@"heightEdge":@(1),@"edgelenght":@(16)},@{@"name":[NSString stringWithFormat:@"%@5",showText(@"红色")],@"imageName":@"红色1",@"edgeContent":@"80",@"heightEdge":@(1),@"edgelenght":@(1)},@{@"name":[NSString stringWithFormat:@"%@6",showText(@"红色")],@"imageName":@"红色2",@"edgeContent":@"C0C00000",@"heightEdge":@(2),@"edgelenght":@(4)},@{@"name":[NSString stringWithFormat:@"%@7",showText(@"红色")],@"imageName":@"红色3",@"edgeContent":@"C0C0C0C000000000",@"heightEdge":@(2),@"edgelenght":@(8)},@{@"name":[NSString stringWithFormat:@"%@8",showText(@"红色")],@"imageName":@"红色3",@"edgeContent":@"C0C0C0C0C0C0C0C00000000000000000",@"heightEdge":@(2),@"edgelenght":@(16)},@{@"name":[NSString stringWithFormat:@"%@9",showText(@"红色")],@"imageName":@"红色3",@"edgeContent":@"40408080",@"heightEdge":@(2),@"edgelenght":@(4)},@{@"name":[NSString stringWithFormat:@"%@10",showText(@"红色")],@"imageName":@"红色3",@"edgeContent":@"C080C040",@"heightEdge":@(2),@"edgelenght":@(4)},@{@"name":[NSString stringWithFormat:@"%@11",showText(@"红色")],@"imageName":@"红色3",@"edgeContent":@"4080",@"heightEdge":@(2),@"edgelenght":@(2)},@{@"name":[NSString stringWithFormat:@"%@12",showText(@"红色")],@"imageName":@"红色3",@"edgeContent":@"C0C08080",@"heightEdge":@(2),@"edgelenght":@(4)},@{@"name":[NSString stringWithFormat:@"%@13",showText(@"红色")],@"imageName":@"红色1",@"edgeContent":@"C0",@"heightEdge":@(2),@"edgelenght":@(1)}];
    }
    return edgingArr;
}

+ (NSArray *)getSystemEdgingWithLine:(NSInteger)line{
    NSArray *edgingArr= [JTCommon getSystemEdging];
    NSMutableArray *edgingArrSpecial = [[NSMutableArray alloc] init];
    [edgingArrSpecial addObject:edgingArr[0]];
    for (int i= 0; i < edgingArr.count; i++) {
        NSDictionary *edgingDic = edgingArr[i];
        NSInteger heightEdge = [edgingDic[@"heightEdge"] integerValue];
        if (heightEdge == line) {
            [edgingArrSpecial addObject:edgingDic];
        }
    }
    return [edgingArrSpecial copy];
}

+ (NSArray *)getSystemDazzle{
    
    NSArray *dazzleArr = [[NSArray alloc] init];
    if([CurrentDeviceType isEqual:@"CoolLEDM"]){
        dazzleArr = @[@{@"name":showText(@"七彩向左滚动"),@"imageName":@"七彩向左滚动",@"dazzleType":@"010302060405",@"dazzleShowModel":@(1),@"dazzleShowModelDirection":@(0),@"dazzleTypeLength":@(6)},@{@"name":showText(@"七彩向右滚动"),@"imageName":@"七彩向右滚动",@"dazzleType":@"010302060405",@"dazzleShowModel":@(1),@"dazzleShowModelDirection":@(1),@"dazzleTypeLength":@(6)},@{@"name":showText(@"七彩静态"),@"imageName":@"七彩静态",@"dazzleType":@"010302060405",@"dazzleShowModel":@(2),@"dazzleShowModelDirection":@(0),@"dazzleTypeLength":@(6)},@{@"name":showText(@"七彩向上滚动"),@"imageName":@"七彩向上滚动",@"dazzleType":@"010302060405",@"dazzleShowModel":@(3),@"dazzleShowModelDirection":@(2),@"dazzleTypeLength":@(6)},@{@"name":showText(@"七彩向下滚动"),@"imageName":@"七彩向下滚动",@"dazzleType":@"010302060405",@"dazzleShowModel":@(3),@"dazzleShowModelDirection":@(3),@"dazzleTypeLength":@(6)},@{@"name":showText(@"七彩向中间滚动"),@"imageName":@"七彩向中间滚动",@"dazzleType":@"010302060405",@"dazzleShowModel":@(4),@"dazzleShowModelDirection":@(4),@"dazzleTypeLength":@(6)},@{@"name":showText(@"七彩向两边滚动"),@"imageName":@"七彩向两边滚动",@"dazzleType":@"010302060405",@"dazzleShowModel":@(4),@"dazzleShowModelDirection":@(5),@"dazzleTypeLength":@(6)},@{@"name":showText(@"七彩跳变"),@"imageName":@"七彩跳变",@"dazzleType":@"010302060405",@"dazzleShowModel":@(5),@"dazzleShowModelDirection":@(0),@"dazzleTypeLength":@(6)},@{@"name":showText(@"七彩水平向左覆盖"),@"imageName":@"七彩水平向左覆盖",@"dazzleType":@"010302060405",@"dazzleShowModel":@(6),@"dazzleShowModelDirection":@(0),@"dazzleTypeLength":@(6)},@{@"name":showText(@"七彩水平向右覆盖"),@"imageName":@"七彩水平向右覆盖",@"dazzleType":@"010302060405",@"dazzleShowModel":@(6),@"dazzleShowModelDirection":@(1),@"dazzleTypeLength":@(6)},@{@"name":showText(@"七彩斜线向左滚动"),@"imageName":@"七彩斜线向左滚动",@"dazzleType":@"010302060405",@"dazzleShowModel":@(7),@"dazzleShowModelDirection":@(0),@"dazzleTypeLength":@(6)},@{@"name":showText(@"七彩斜线向右滚动"),@"imageName":@"七彩斜线向右滚动",@"dazzleType":@"010302060405",@"dazzleShowModel":@(7),@"dazzleShowModelDirection":@(1),@"dazzleTypeLength":@(6)},@{@"name":showText(@"七彩向左旋转"),@"imageName":@"七彩向左旋转",@"dazzleType":@"010302060405",@"dazzleShowModel":@(8),@"dazzleShowModelDirection":@(0),@"dazzleTypeLength":@(6)},@{@"name":showText(@"七彩向右旋转"),@"imageName":@"七彩向右旋转",@"dazzleType":@"010302060405",@"dazzleShowModel":@(8),@"dazzleShowModelDirection":@(1),@"dazzleTypeLength":@(6)},@{@"name":showText(@"青紫黄三色向左滚动"),@"imageName":@"青紫黄三色向左滚动",@"dazzleType":@"060503",@"dazzleShowModel":@(1),@"dazzleShowModelDirection":@(0),@"dazzleTypeLength":@(3)},@{@"name":showText(@"青紫黄三色向右滚动"),@"imageName":@"青紫黄三色向右滚动",@"dazzleType":@"060503",@"dazzleShowModel":@(1),@"dazzleShowModelDirection":@(1),@"dazzleTypeLength":@(3)},@{@"name":showText(@"青紫黄三色静态"),@"imageName":@"青紫黄三色静态",@"dazzleType":@"060503",@"dazzleShowModel":@(2),@"dazzleShowModelDirection":@(0),@"dazzleTypeLength":@(3)},@{@"name":showText(@"青紫黄三色向上滚动"),@"imageName":@"青紫黄三色向上滚动",@"dazzleType":@"060503",@"dazzleShowModel":@(3),@"dazzleShowModelDirection":@(2),@"dazzleTypeLength":@(3)},@{@"name":showText(@"青紫黄三色向下滚动"),@"imageName":@"青紫黄三色向下滚动",@"dazzleType":@"060503",@"dazzleShowModel":@(3),@"dazzleShowModelDirection":@(3),@"dazzleTypeLength":@(3)},@{@"name":showText(@"青紫黄三色向中间滚动"),@"imageName":@"青紫黄三色向中间滚动",@"dazzleType":@"060503",@"dazzleShowModel":@(4),@"dazzleShowModelDirection":@(4),@"dazzleTypeLength":@(3)},@{@"name":showText(@"青紫黄三色向两边滚动"),@"imageName":@"青紫黄三色向两边滚动",@"dazzleType":@"060503",@"dazzleShowModel":@(4),@"dazzleShowModelDirection":@(5),@"dazzleTypeLength":@(3)},@{@"name":showText(@"青紫黄三色跳变"),@"imageName":@"青紫黄三色跳变",@"dazzleType":@"060503",@"dazzleShowModel":@(5),@"dazzleShowModelDirection":@(0),@"dazzleTypeLength":@(3)},@{@"name":showText(@"青紫黄三色水平向左覆盖"),@"imageName":@"青紫黄三色水平向左覆盖",@"dazzleType":@"060503",@"dazzleShowModel":@(6),@"dazzleShowModelDirection":@(0),@"dazzleTypeLength":@(3)},@{@"name":showText(@"青紫黄三色水平向右覆盖"),@"imageName":@"青紫黄三色水平向右覆盖",@"dazzleType":@"060503",@"dazzleShowModel":@(6),@"dazzleShowModelDirection":@(1),@"dazzleTypeLength":@(3)},@{@"name":showText(@"青紫黄三色斜线向左滚动"),@"imageName":@"青紫黄三色斜线向左滚动",@"dazzleType":@"060503",@"dazzleShowModel":@(7),@"dazzleShowModelDirection":@(0),@"dazzleTypeLength":@(3)},@{@"name":showText(@"青紫黄三色斜线向右滚动"),@"imageName":@"青紫黄三色斜线向右滚动",@"dazzleType":@"060503",@"dazzleShowModel":@(7),@"dazzleShowModelDirection":@(1),@"dazzleTypeLength":@(3)},@{@"name":showText(@"青紫黄三色向左旋转"),@"imageName":@"青紫黄三色向左旋转",@"dazzleType":@"060503",@"dazzleShowModel":@(8),@"dazzleShowModelDirection":@(0),@"dazzleTypeLength":@(3)},@{@"name":showText(@"青紫黄三色向右旋转"),@"imageName":@"青紫黄三色向右旋转",@"dazzleType":@"060503",@"dazzleShowModel":@(8),@"dazzleShowModelDirection":@(1),@"dazzleTypeLength":@(3)}];
        
    }else if ([CurrentDeviceType isEqual:@"CoolLEDU"]){
        dazzleArr = @[@{@"name":showText(@"七彩渐变向左滚动"),@"imageName":@"七彩向左滚动",@"dazzleType":@"0F000F200F400F600F800FA00FC00FF00CF00AF008F006F004F002F000F000F200F400F600F800FA00FC00FF00CF00AF008F006F004F002F000F020F040F060F080F0A0F0C0F0F0F0F0C0F0A0F080F060F040F020F00",@"dazzleShowModel":@(1),@"dazzleShowModelDirection":@(0),@"dazzleTypeLength":@(86)},@{@"name":showText(@"七彩渐变向右滚动"),@"imageName":@"七彩向右滚动",@"dazzleType":@"0F000F200F400F600F800FA00FC00FF00CF00AF008F006F004F002F000F000F200F400F600F800FA00FC00FF00CF00AF008F006F004F002F000F020F040F060F080F0A0F0C0F0F0F0F0C0F0A0F080F060F040F020F00",@"dazzleShowModel":@(1),@"dazzleShowModelDirection":@(1),@"dazzleTypeLength":@(86)},@{@"name":showText(@"七彩渐变静态"),@"imageName":@"七彩静态",@"dazzleType":@"0F000F200F400F600F800FA00FC00FF00CF00AF008F006F004F002F000F000F200F400F600F800FA00FC00FF00CF00AF008F006F004F002F000F020F040F060F080F0A0F0C0F0F0F0F0C0F0A0F080F060F040F020F00",@"dazzleShowModel":@(2),@"dazzleShowModelDirection":@(0),@"dazzleTypeLength":@(86)},@{@"name":showText(@"七彩渐变向上滚动"),@"imageName":@"七彩向上滚动",@"dazzleType":@"0F000F200F400F600F800FA00FC00FF00CF00AF008F006F004F002F000F000F200F400F600F800FA00FC00FF00CF00AF008F006F004F002F000F020F040F060F080F0A0F0C0F0F0F0F0C0F0A0F080F060F040F020F00",@"dazzleShowModel":@(3),@"dazzleShowModelDirection":@(2),@"dazzleTypeLength":@(86)},@{@"name":showText(@"七彩渐变向下滚动"),@"imageName":@"七彩向下滚动",@"dazzleType":@"0F000F200F400F600F800FA00FC00FF00CF00AF008F006F004F002F000F000F200F400F600F800FA00FC00FF00CF00AF008F006F004F002F000F020F040F060F080F0A0F0C0F0F0F0F0C0F0A0F080F060F040F020F00",@"dazzleShowModel":@(3),@"dazzleShowModelDirection":@(3),@"dazzleTypeLength":@(86)},@{@"name":showText(@"七彩渐变向中间滚动"),@"imageName":@"七彩向中间滚动",@"dazzleType":@"0F000F200F400F600F800FA00FC00FF00CF00AF008F006F004F002F000F000F200F400F600F800FA00FC00FF00CF00AF008F006F004F002F000F020F040F060F080F0A0F0C0F0F0F0F0C0F0A0F080F060F040F020F00",@"dazzleShowModel":@(4),@"dazzleShowModelDirection":@(4),@"dazzleTypeLength":@(86)},@{@"name":showText(@"七彩渐变向两边滚动"),@"imageName":@"七彩向两边滚动",@"dazzleType":@"0F000F200F400F600F800FA00FC00FF00CF00AF008F006F004F002F000F000F200F400F600F800FA00FC00FF00CF00AF008F006F004F002F000F020F040F060F080F0A0F0C0F0F0F0F0C0F0A0F080F060F040F020F00",@"dazzleShowModel":@(4),@"dazzleShowModelDirection":@(5),@"dazzleTypeLength":@(86)},@{@"name":showText(@"七彩跳变"),@"imageName":@"七彩跳变",@"dazzleType":@"0F000FF000F000FF000F0F0F",@"dazzleShowModel":@(5),@"dazzleShowModelDirection":@(0),@"dazzleTypeLength":@(12)},@{@"name":showText(@"七彩水平向左覆盖"),@"imageName":@"七彩水平向左覆盖",@"dazzleType":@"0F000FF000F000FF000F0F0F",@"dazzleShowModel":@(6),@"dazzleShowModelDirection":@(0),@"dazzleTypeLength":@(12)},@{@"name":showText(@"七彩水平向右覆盖"),@"imageName":@"七彩水平向右覆盖",@"dazzleType":@"0F000FF000F000FF000F0F0F",@"dazzleShowModel":@(6),@"dazzleShowModelDirection":@(1),@"dazzleTypeLength":@(12)},@{@"name":showText(@"七彩渐变斜线向左滚动"),@"imageName":@"七彩斜线向左滚动",@"dazzleType":@"0F000F200F400F600F800FA00FC00FF00CF00AF008F006F004F002F000F000F200F400F600F800FA00FC00FF00CF00AF008F006F004F002F000F020F040F060F080F0A0F0C0F0F0F0F0C0F0A0F080F060F040F020F00",@"dazzleShowModel":@(7),@"dazzleShowModelDirection":@(0),@"dazzleTypeLength":@(86)},@{@"name":showText(@"七彩渐变斜线向右滚动"),@"imageName":@"七彩斜线向右滚动",@"dazzleType":@"0F000F200F400F600F800FA00FC00FF00CF00AF008F006F004F002F000F000F200F400F600F800FA00FC00FF00CF00AF008F006F004F002F000F020F040F060F080F0A0F0C0F0F0F0F0C0F0A0F080F060F040F020F00",@"dazzleShowModel":@(7),@"dazzleShowModelDirection":@(1),@"dazzleTypeLength":@(86)},@{@"name":showText(@"七彩渐变向左旋转"),@"imageName":@"七彩向左旋转",@"dazzleType":@"0F000F200F400F600F800FA00FC00FF00CF00AF008F006F004F002F000F000F200F400F600F800FA00FC00FF00CF00AF008F006F004F002F000F020F040F060F080F0A0F0C0F0F0F0F0C0F0A0F080F060F040F020F00",@"dazzleShowModel":@(8),@"dazzleShowModelDirection":@(0),@"dazzleTypeLength":@(86)},@{@"name":showText(@"七彩渐变向右旋转"),@"imageName":@"七彩向右旋转",@"dazzleType":@"0F000F200F400F600F800FA00FC00FF00CF00AF008F006F004F002F000F000F200F400F600F800FA00FC00FF00CF00AF008F006F004F002F000F020F040F060F080F0A0F0C0F0F0F0F0C0F0A0F080F060F040F020F00",@"dazzleShowModel":@(8),@"dazzleShowModelDirection":@(1),@"dazzleTypeLength":@(86)},@{@"name":showText(@"青紫黄三色向左滚动"),@"imageName":@"青紫黄三色向左滚动",@"dazzleType":@"00FF0F0F0FF0",@"dazzleShowModel":@(1),@"dazzleShowModelDirection":@(0),@"dazzleTypeLength":@(6)},@{@"name":showText(@"青紫黄三色向右滚动"),@"imageName":@"青紫黄三色向右滚动",@"dazzleType":@"00FF0F0F0FF0",@"dazzleShowModel":@(1),@"dazzleShowModelDirection":@(1),@"dazzleTypeLength":@(6)},@{@"name":showText(@"青紫黄三色静态"),@"imageName":@"青紫黄三色静态",@"dazzleType":@"00FF0F0F0FF0",@"dazzleShowModel":@(2),@"dazzleShowModelDirection":@(0),@"dazzleTypeLength":@(6)},@{@"name":showText(@"青紫黄三色向上滚动"),@"imageName":@"青紫黄三色向上滚动",@"dazzleType":@"00FF0F0F0FF0",@"dazzleShowModel":@(3),@"dazzleShowModelDirection":@(2),@"dazzleTypeLength":@(6)},@{@"name":showText(@"青紫黄三色向下滚动"),@"imageName":@"青紫黄三色向下滚动",@"dazzleType":@"00FF0F0F0FF0",@"dazzleShowModel":@(3),@"dazzleShowModelDirection":@(3),@"dazzleTypeLength":@(6)},@{@"name":showText(@"青紫黄三色向中间滚动"),@"imageName":@"青紫黄三色向中间滚动",@"dazzleType":@"00FF0F0F0FF0",@"dazzleShowModel":@(4),@"dazzleShowModelDirection":@(4),@"dazzleTypeLength":@(6)},@{@"name":showText(@"青紫黄三色向两边滚动"),@"imageName":@"青紫黄三色向两边滚动",@"dazzleType":@"00FF0F0F0FF0",@"dazzleShowModel":@(4),@"dazzleShowModelDirection":@(5),@"dazzleTypeLength":@(6)},@{@"name":showText(@"青紫黄三色跳变"),@"imageName":@"青紫黄三色跳变",@"dazzleType":@"00FF0F0F0FF0",@"dazzleShowModel":@(5),@"dazzleShowModelDirection":@(0),@"dazzleTypeLength":@(6)},@{@"name":showText(@"青紫黄三色水平向左覆盖"),@"imageName":@"青紫黄三色水平向左覆盖",@"dazzleType":@"00FF0F0F0FF0",@"dazzleShowModel":@(6),@"dazzleShowModelDirection":@(0),@"dazzleTypeLength":@(6)},@{@"name":showText(@"青紫黄三色水平向右覆盖"),@"imageName":@"青紫黄三色水平向右覆盖",@"dazzleType":@"00FF0F0F0FF0",@"dazzleShowModel":@(6),@"dazzleShowModelDirection":@(1),@"dazzleTypeLength":@(6)},@{@"name":showText(@"青紫黄三色斜线向左滚动"),@"imageName":@"青紫黄三色斜线向左滚动",@"dazzleType":@"00FF0F0F0FF0",@"dazzleShowModel":@(7),@"dazzleShowModelDirection":@(0),@"dazzleTypeLength":@(6)},@{@"name":showText(@"青紫黄三色斜线向右滚动"),@"imageName":@"青紫黄三色斜线向右滚动",@"dazzleType":@"00FF0F0F0FF0",@"dazzleShowModel":@(7),@"dazzleShowModelDirection":@(1),@"dazzleTypeLength":@(6)},@{@"name":showText(@"青紫黄三色向左旋转"),@"imageName":@"青紫黄三色向左旋转",@"dazzleType":@"00FF0F0F0FF0",@"dazzleShowModel":@(8),@"dazzleShowModelDirection":@(0),@"dazzleTypeLength":@(6)},@{@"name":showText(@"青紫黄三色向右旋转"),@"imageName":@"青紫黄三色向右旋转",@"dazzleType":@"00FF0F0F0FF0",@"dazzleShowModel":@(8),@"dazzleShowModelDirection":@(1),@"dazzleTypeLength":@(6)}];
    }else if ([CurrentDeviceType isEqual:@"CoolLEDC"]){
        dazzleArr = @[@{@"name":showText(@"七彩渐变向左滚动"),@"imageName":@"七彩向左滚动",@"dazzleType":@"0F000F200F400F600F800FA00FC00FF00CF00AF008F006F004F002F000F000F200F400F600F800FA00FC00FF00CF00AF008F006F004F002F000F020F040F060F080F0A0F0C0F0F0F0F0C0F0A0F080F060F040F020F00",@"dazzleShowModel":@(1),@"dazzleShowModelDirection":@(0),@"dazzleTypeLength":@(86)},@{@"name":showText(@"七彩渐变向右滚动"),@"imageName":@"七彩向右滚动",@"dazzleType":@"0F000F200F400F600F800FA00FC00FF00CF00AF008F006F004F002F000F000F200F400F600F800FA00FC00FF00CF00AF008F006F004F002F000F020F040F060F080F0A0F0C0F0F0F0F0C0F0A0F080F060F040F020F00",@"dazzleShowModel":@(1),@"dazzleShowModelDirection":@(1),@"dazzleTypeLength":@(86)},@{@"name":showText(@"七彩渐变静态"),@"imageName":@"七彩静态",@"dazzleType":@"0F000F200F400F600F800FA00FC00FF00CF00AF008F006F004F002F000F000F200F400F600F800FA00FC00FF00CF00AF008F006F004F002F000F020F040F060F080F0A0F0C0F0F0F0F0C0F0A0F080F060F040F020F00",@"dazzleShowModel":@(2),@"dazzleShowModelDirection":@(0),@"dazzleTypeLength":@(86)},@{@"name":showText(@"七彩渐变向上滚动"),@"imageName":@"七彩向上滚动",@"dazzleType":@"0F000F200F400F600F800FA00FC00FF00CF00AF008F006F004F002F000F000F200F400F600F800FA00FC00FF00CF00AF008F006F004F002F000F020F040F060F080F0A0F0C0F0F0F0F0C0F0A0F080F060F040F020F00",@"dazzleShowModel":@(3),@"dazzleShowModelDirection":@(2),@"dazzleTypeLength":@(86)},@{@"name":showText(@"七彩渐变向下滚动"),@"imageName":@"七彩向下滚动",@"dazzleType":@"0F000F200F400F600F800FA00FC00FF00CF00AF008F006F004F002F000F000F200F400F600F800FA00FC00FF00CF00AF008F006F004F002F000F020F040F060F080F0A0F0C0F0F0F0F0C0F0A0F080F060F040F020F00",@"dazzleShowModel":@(3),@"dazzleShowModelDirection":@(3),@"dazzleTypeLength":@(86)},@{@"name":showText(@"七彩渐变向中间滚动"),@"imageName":@"七彩向中间滚动",@"dazzleType":@"0F000F200F400F600F800FA00FC00FF00CF00AF008F006F004F002F000F000F200F400F600F800FA00FC00FF00CF00AF008F006F004F002F000F020F040F060F080F0A0F0C0F0F0F0F0C0F0A0F080F060F040F020F00",@"dazzleShowModel":@(4),@"dazzleShowModelDirection":@(4),@"dazzleTypeLength":@(86)},@{@"name":showText(@"七彩渐变向两边滚动"),@"imageName":@"七彩向两边滚动",@"dazzleType":@"0F000F200F400F600F800FA00FC00FF00CF00AF008F006F004F002F000F000F200F400F600F800FA00FC00FF00CF00AF008F006F004F002F000F020F040F060F080F0A0F0C0F0F0F0F0C0F0A0F080F060F040F020F00",@"dazzleShowModel":@(4),@"dazzleShowModelDirection":@(5),@"dazzleTypeLength":@(86)},@{@"name":showText(@"七彩跳变"),@"imageName":@"七彩跳变",@"dazzleType":@"0F000FF000F000FF000F0F0F",@"dazzleShowModel":@(5),@"dazzleShowModelDirection":@(0),@"dazzleTypeLength":@(12)},@{@"name":showText(@"七彩水平向左覆盖"),@"imageName":@"七彩水平向左覆盖",@"dazzleType":@"0F000FF000F000FF000F0F0F",@"dazzleShowModel":@(6),@"dazzleShowModelDirection":@(0),@"dazzleTypeLength":@(12)},@{@"name":showText(@"七彩水平向右覆盖"),@"imageName":@"七彩水平向右覆盖",@"dazzleType":@"0F000FF000F000FF000F0F0F",@"dazzleShowModel":@(6),@"dazzleShowModelDirection":@(1),@"dazzleTypeLength":@(12)},@{@"name":showText(@"七彩渐变斜线向左滚动"),@"imageName":@"七彩斜线向左滚动",@"dazzleType":@"0F000F200F400F600F800FA00FC00FF00CF00AF008F006F004F002F000F000F200F400F600F800FA00FC00FF00CF00AF008F006F004F002F000F020F040F060F080F0A0F0C0F0F0F0F0C0F0A0F080F060F040F020F00",@"dazzleShowModel":@(7),@"dazzleShowModelDirection":@(0),@"dazzleTypeLength":@(86)},@{@"name":showText(@"七彩渐变斜线向右滚动"),@"imageName":@"七彩斜线向右滚动",@"dazzleType":@"0F000F200F400F600F800FA00FC00FF00CF00AF008F006F004F002F000F000F200F400F600F800FA00FC00FF00CF00AF008F006F004F002F000F020F040F060F080F0A0F0C0F0F0F0F0C0F0A0F080F060F040F020F00",@"dazzleShowModel":@(7),@"dazzleShowModelDirection":@(1),@"dazzleTypeLength":@(86)},@{@"name":showText(@"七彩渐变向左旋转"),@"imageName":@"七彩向左旋转",@"dazzleType":@"0F000F200F400F600F800FA00FC00FF00CF00AF008F006F004F002F000F000F200F400F600F800FA00FC00FF00CF00AF008F006F004F002F000F020F040F060F080F0A0F0C0F0F0F0F0C0F0A0F080F060F040F020F00",@"dazzleShowModel":@(8),@"dazzleShowModelDirection":@(0),@"dazzleTypeLength":@(86)},@{@"name":showText(@"七彩渐变向右旋转"),@"imageName":@"七彩向右旋转",@"dazzleType":@"0F000F200F400F600F800FA00FC00FF00CF00AF008F006F004F002F000F000F200F400F600F800FA00FC00FF00CF00AF008F006F004F002F000F020F040F060F080F0A0F0C0F0F0F0F0C0F0A0F080F060F040F020F00",@"dazzleShowModel":@(8),@"dazzleShowModelDirection":@(1),@"dazzleTypeLength":@(86)},@{@"name":showText(@"青紫黄三色向左滚动"),@"imageName":@"青紫黄三色向左滚动",@"dazzleType":@"00FF0F0F0FF0",@"dazzleShowModel":@(1),@"dazzleShowModelDirection":@(0),@"dazzleTypeLength":@(6)},@{@"name":showText(@"青紫黄三色向右滚动"),@"imageName":@"青紫黄三色向右滚动",@"dazzleType":@"00FF0F0F0FF0",@"dazzleShowModel":@(1),@"dazzleShowModelDirection":@(1),@"dazzleTypeLength":@(6)},@{@"name":showText(@"青紫黄三色静态"),@"imageName":@"青紫黄三色静态",@"dazzleType":@"00FF0F0F0FF0",@"dazzleShowModel":@(2),@"dazzleShowModelDirection":@(0),@"dazzleTypeLength":@(6)},@{@"name":showText(@"青紫黄三色向上滚动"),@"imageName":@"青紫黄三色向上滚动",@"dazzleType":@"00FF0F0F0FF0",@"dazzleShowModel":@(3),@"dazzleShowModelDirection":@(2),@"dazzleTypeLength":@(6)},@{@"name":showText(@"青紫黄三色向下滚动"),@"imageName":@"青紫黄三色向下滚动",@"dazzleType":@"00FF0F0F0FF0",@"dazzleShowModel":@(3),@"dazzleShowModelDirection":@(3),@"dazzleTypeLength":@(6)},@{@"name":showText(@"青紫黄三色向中间滚动"),@"imageName":@"青紫黄三色向中间滚动",@"dazzleType":@"00FF0F0F0FF0",@"dazzleShowModel":@(4),@"dazzleShowModelDirection":@(4),@"dazzleTypeLength":@(6)},@{@"name":showText(@"青紫黄三色向两边滚动"),@"imageName":@"青紫黄三色向两边滚动",@"dazzleType":@"00FF0F0F0FF0",@"dazzleShowModel":@(4),@"dazzleShowModelDirection":@(5),@"dazzleTypeLength":@(6)},@{@"name":showText(@"青紫黄三色跳变"),@"imageName":@"青紫黄三色跳变",@"dazzleType":@"00FF0F0F0FF0",@"dazzleShowModel":@(5),@"dazzleShowModelDirection":@(0),@"dazzleTypeLength":@(6)},@{@"name":showText(@"青紫黄三色水平向左覆盖"),@"imageName":@"青紫黄三色水平向左覆盖",@"dazzleType":@"00FF0F0F0FF0",@"dazzleShowModel":@(6),@"dazzleShowModelDirection":@(0),@"dazzleTypeLength":@(6)},@{@"name":showText(@"青紫黄三色水平向右覆盖"),@"imageName":@"青紫黄三色水平向右覆盖",@"dazzleType":@"00FF0F0F0FF0",@"dazzleShowModel":@(6),@"dazzleShowModelDirection":@(1),@"dazzleTypeLength":@(6)},@{@"name":showText(@"青紫黄三色斜线向左滚动"),@"imageName":@"青紫黄三色斜线向左滚动",@"dazzleType":@"00FF0F0F0FF0",@"dazzleShowModel":@(7),@"dazzleShowModelDirection":@(0),@"dazzleTypeLength":@(6)},@{@"name":showText(@"青紫黄三色斜线向右滚动"),@"imageName":@"青紫黄三色斜线向右滚动",@"dazzleType":@"00FF0F0F0FF0",@"dazzleShowModel":@(7),@"dazzleShowModelDirection":@(1),@"dazzleTypeLength":@(6)},@{@"name":showText(@"青紫黄三色向左旋转"),@"imageName":@"青紫黄三色向左旋转",@"dazzleType":@"00FF0F0F0FF0",@"dazzleShowModel":@(8),@"dazzleShowModelDirection":@(0),@"dazzleTypeLength":@(6)},@{@"name":showText(@"青紫黄三色向右旋转"),@"imageName":@"青紫黄三色向右旋转",@"dazzleType":@"00FF0F0F0FF0",@"dazzleShowModel":@(8),@"dazzleShowModelDirection":@(1),@"dazzleTypeLength":@(6)}];
    }
    return dazzleArr;
}

+ (NSArray *)getSystemDazzleCoolLEDU{
    NSArray *dazzleArr = @[];
    return dazzleArr;
}


+ (int)getItemContentCount:(ColorItemModel32 *)colorItemModel32{
    int itemContentCountSum = 0;
    NSArray *colorTextModel32Arr = colorItemModel32.colorTextModel32Arr;
    for (int i = 0; i< colorTextModel32Arr.count; i++) {
        ColorTextModel32 *colorTextModel32 = colorTextModel32Arr[i];
        
        int itemContentCount = 0;
        
        //允许边框单独存在，判断是否有内容
        if([colorTextModel32 isOnlyEdge]){
            itemContentCount = (colorTextModel32.isEdge ? 1 : 0);
        }else{
            if (![CurrentDeviceType isEqual:@"CoolLEDC"]){
                itemContentCount = ((colorTextModel32.colorShowType == 0) ? 1 : 2) + (colorTextModel32.isEdge ? 1 : 0);
                }else{
                    itemContentCount = ((colorTextModel32.colorShowType == 0) ? 0 : 1) + (colorTextModel32.isEdge ? 1 : 0);
                }
        }
        itemContentCountSum += itemContentCount;
        
    }
    
    NSInteger graffitiCount = 0;
    NSArray *graffitiModel32Arr = colorItemModel32.graffitiModel32Arr;
    if (graffitiModel32Arr != nil) {
        graffitiCount = graffitiModel32Arr.count;
    }
    
    NSInteger animationCount = 0;
    NSArray *animationModel32Arr = colorItemModel32.animationModel32Arr;
    if (animationModel32Arr != nil) {
        animationCount = animationModel32Arr.count;
    }
    
    NSInteger clockTimeCount = 0;
    NSArray *clockTimeModelArr = colorItemModel32.clockTimeModelArr;
    if (clockTimeModelArr != nil) {
        clockTimeCount = clockTimeModelArr.count;
    }
    
    NSInteger dateTimeCount = 0;
    NSArray *dateTimeModelArr = colorItemModel32.dateTimeModelArr;
    if (dateTimeModelArr != nil) {
        dateTimeCount = dateTimeModelArr.count;
    }
    
    NSInteger scoreboardCount = 0;
    NSArray *scoreboardModelArr = colorItemModel32.scoreboardModelArr;
    if (scoreboardModelArr != nil) {
        scoreboardCount = scoreboardModelArr.count;
    }
    
    NSInteger countdownCount = 0;
    NSArray *countdownModelArr = colorItemModel32.countdownModelArr;
    if (countdownModelArr != nil) {
        countdownCount = countdownModelArr.count;
    }
    
    itemContentCountSum = itemContentCountSum + graffitiCount + animationCount + clockTimeCount + dateTimeCount + scoreboardCount + countdownCount;
    
    return itemContentCountSum;
}

+ (int)getColorItemModel32Type:(ColorItemModel32 *)colorItemModel32{
    
    NSArray *colorTextModel32Arr = colorItemModel32.colorTextModel32Arr;
    if(colorTextModel32Arr.count != 0)return 1;
    
    NSArray *graffitiModel32Arr = colorItemModel32.graffitiModel32Arr;
    if(graffitiModel32Arr.count != 0)return 2;
    
    NSArray *animationModel32Arr = colorItemModel32.animationModel32Arr;
    if(animationModel32Arr.count != 0)return 3;
    
    return 0;
}

+ (NSString *)getWordColorFrom:(NSString *)rgbString{
    if([CurrentDeviceType isEqual:@"CoolLEDM"]){
        if([rgbString isEqual:@"1,0,0"]){
            return @"01";
        }
        if([rgbString isEqual:@"1,0,1"]){
            return @"05";
        }
        if([rgbString isEqual:@"1,1,0"]){
            return @"03";
        }
        if([rgbString isEqual:@"0,1,0"]){
            return @"02";
        }
        if([rgbString isEqual:@"0,1,1"]){
            return @"06";
        }
        if([rgbString isEqual:@"0,0,1"]){
            return @"04";
        }
        if([rgbString isEqual:@"1,1,1"]){
            return @"07";
        }
    }else if([CurrentDeviceType isEqual:@"CoolLEDU"]){
        NSArray *rgbArray = [rgbString componentsSeparatedByString:@","];
        
        CGFloat red = [rgbArray[0] floatValue] ;
        CGFloat green = [rgbArray[1] floatValue];
        CGFloat blue = [rgbArray[2] floatValue];
        
        NSString *sendText = @"";
        
        sendText = [sendText stringByAppendingFormat:@"%02x", [HLUtils colorExchangeFloat:red]];
        
        sendText = [sendText stringByAppendingFormat:@"%02x", [HLUtils colorExchangeFloat:green] * 16 + [HLUtils colorExchangeFloat:blue]];
        
        return sendText;
    }
    
    return @"";
}

+ (ColorItemModel32 *)getNewColorItemModel32From:(ColorItemModel32 *)colorItemModel32Origin{
    
    //文字部分赋值
    NSMutableArray *colorTextModel32Arr = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < colorItemModel32Origin.colorTextModel32Arr.count; i++) {
        
        ColorTextModel32 *colorTextModelOrigin = colorItemModel32Origin.colorTextModel32Arr[i];
        
        ColorTextModel32 *colorTextModel = [[ColorTextModel32 alloc] init];
        
        colorTextModel.bold = colorTextModelOrigin.bold;
        colorTextModel.degree = colorTextModelOrigin.degree;
        colorTextModel.font = colorTextModelOrigin.font;
        colorTextModel.fontDefaultFit = colorTextModelOrigin.fontDefaultFit;
        colorTextModel.fontSpace = colorTextModelOrigin.fontSpace;
        colorTextModel.isMirror = colorTextModelOrigin.isMirror;
        
        colorTextModel.coverType = colorTextModelOrigin.coverType;
        colorTextModel.startRow = colorTextModelOrigin.startRow;
        colorTextModel.startCol = colorTextModelOrigin.startCol;
        colorTextModel.widthData =colorTextModelOrigin.widthData;
        colorTextModel.heightData = colorTextModelOrigin.heightData;
        colorTextModel.showModel = colorTextModelOrigin.showModel;
        colorTextModel.speedData = colorTextModelOrigin.speedData;
        colorTextModel.isTrueSpeedData = colorTextModelOrigin.isTrueSpeedData;
        colorTextModel.stayTime = colorTextModelOrigin.stayTime;
        
        colorTextModel.dazzleShowModel = colorTextModelOrigin.dazzleShowModel;
        colorTextModel.dazzleSpeedData = colorTextModelOrigin.dazzleSpeedData;
        colorTextModel.dazzleShowModelDirection = colorTextModelOrigin.dazzleShowModelDirection;
        colorTextModel.dazzleIndexSelect = colorTextModelOrigin.dazzleIndexSelect;
        colorTextModel.dazzleType = colorTextModelOrigin.dazzleType;
        colorTextModel.dazzleTypeLength = colorTextModelOrigin.dazzleTypeLength;
        
        colorTextModel.coverTypeEdge = colorTextModelOrigin.coverTypeEdge;
        colorTextModel.startRowEdge = colorTextModelOrigin.startRowEdge;
        colorTextModel.startColEdge = colorTextModelOrigin.startColEdge;
        colorTextModel.widthDataEdge = colorTextModelOrigin.widthDataEdge;
        colorTextModel.heightDataEdge = colorTextModelOrigin.heightDataEdge;
        colorTextModel.showModelEdge = colorTextModelOrigin.showModelEdge;
        colorTextModel.speedDataEdge = colorTextModelOrigin.speedDataEdge;
        colorTextModel.heightEdge = colorTextModelOrigin.heightEdge;
        colorTextModel.edgingIndexSelect = colorTextModelOrigin.edgingIndexSelect;
        colorTextModel.edgeContent = colorTextModelOrigin.edgeContent;
        colorTextModel.edgelenght = colorTextModelOrigin.edgelenght;
        
        colorTextModel.colorShowType = colorTextModelOrigin.colorShowType;
        colorTextModel.isEdge = colorTextModelOrigin.isEdge;
        
        NSArray * textItemsArrOrigin = [colorTextModelOrigin.textItems copy];;
        NSMutableArray * textItemsArrNew = [[NSMutableArray alloc] init];
        
        for (int j = 0; j < textItemsArrOrigin.count; j++) {
            HLColorTextItem *textItemOrigin = textItemsArrOrigin[j];
            HLColorTextItem *textItemNew =  [[HLColorTextItem alloc] init];
            textItemNew.itemType = textItemOrigin.itemType;
            textItemNew.rgbString = textItemOrigin.rgbString;
            textItemNew.text = textItemOrigin.text;
            if(textItemOrigin.emojiDict != nil)textItemNew.emojiDict = textItemOrigin.emojiDict;
            [textItemsArrNew addObject:textItemNew];
        }
        colorTextModel.textItems = [textItemsArrNew copy];
        
        colorTextModel.originText = colorTextModelOrigin.originText;
        
        colorTextModel.itemContentCount = colorTextModelOrigin.itemContentCount;
        
        [colorTextModel32Arr addObject:colorTextModel];
        
    }
    
    //涂鸦部分赋值
    NSMutableArray *graffitiModel32Arr = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < colorItemModel32Origin.graffitiModel32Arr.count; i++) {
        
        GraffitiModel32 *graffitiModelOrigin = colorItemModel32Origin.graffitiModel32Arr[i];
        
        //创建节目内容对象并赋值
        GraffitiModel32 *graffitiModel = [[GraffitiModel32 alloc] init];
        
        graffitiModel.coverTypeGraffiti = graffitiModelOrigin.coverTypeGraffiti;
        graffitiModel.startRowGraffiti = graffitiModelOrigin.startRowGraffiti;
        graffitiModel.startColGraffiti = graffitiModelOrigin.startColGraffiti;
        graffitiModel.widthDataGraffiti = graffitiModelOrigin.widthDataGraffiti;
        graffitiModel.heightDataGraffiti = graffitiModelOrigin.heightDataGraffiti;
        graffitiModel.showModelGraffiti = graffitiModelOrigin.showModelGraffiti;
        graffitiModel.speedDataGraffiti = graffitiModelOrigin.speedDataGraffiti;
        graffitiModel.stayTimeGraffiti = graffitiModelOrigin.stayTimeGraffiti;
        
        NSMutableArray *colArr = [[NSMutableArray alloc] init];
        for (int i = 0; i < graffitiModelOrigin.dataGraffiti.count; i++) {
            NSMutableArray *rowArr = [[NSMutableArray alloc] init];
            NSArray *tols = [graffitiModelOrigin.dataGraffiti objectAtIndex:i];
            for (int j = 0; j < tols.count; j++) {
                NSArray *rgbOriginArray = graffitiModelOrigin.dataGraffiti[i][j];
                NSMutableArray *rgbArray = [[NSMutableArray alloc] init];
                for (int m = 0; m < rgbOriginArray.count; m++) {
                    NSNumber *rgb = rgbOriginArray[m];
                    [rgbArray addObject:rgb];
                }
                [rowArr addObject:rgbArray];
            }
            [colArr addObject:rowArr];
        }
        graffitiModel.dataGraffiti = [colArr copy];
        
        [graffitiModel32Arr addObject:graffitiModel];
    }
    
    //动画部分赋值
    NSMutableArray *animationModel32Arr = [[NSMutableArray alloc] init];
    NSMutableArray *animationGIFName32Arr = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < colorItemModel32Origin.animationModel32Arr.count; i++) {
        
        AnimationModel32 *animationModelOrigin = colorItemModel32Origin.animationModel32Arr[i];
        
        //创建节目内容对象并赋值
        AnimationModel32 *animationModel = [[AnimationModel32 alloc] init];
        
        animationModel.coverTypeAnimation = animationModelOrigin.coverTypeAnimation;
        animationModel.startRowAnimation = animationModelOrigin.startRowAnimation;
        animationModel.startColAnimation = animationModelOrigin.startColAnimation;
        animationModel.widthDataAnimation = animationModelOrigin.widthDataAnimation;
        animationModel.heightDataAnimation = animationModelOrigin.heightDataAnimation;
        animationModel.timeIntervalAnimation = animationModelOrigin.timeIntervalAnimation;
        
        //对GIF的复制，与字节数组的复制
        if(animationModelOrigin.dataAnimation.count == 0 && colorItemModel32Origin.animationGIFName32Arr.count != 0){
            NSString *gifNameSource = colorItemModel32Origin.animationGIFName32Arr[i];
            NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
            NSURL *sourceFileURL = [documentsDirectoryURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.gif",gifNameSource]];
            
            NSString *index = [NSString stringWithFormat:@"%d",i];
            NSString *gifName = [JTCommon getElementName:index];
            
            NSURL *destinationURL = [documentsDirectoryURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.gif",gifName]];
            
            NSData *imageData = [NSData dataWithContentsOfURL:sourceFileURL];
            if (imageData) {
                BOOL success = [imageData writeToFile:destinationURL.path atomically:YES];
                if (success) {
                    //                    NSLog(@"成功复制 GIF 图片");
                } else {
                    //                    NSLog(@"复制 GIF 图片失败");
                }
            } else {
                //                NSLog(@"下载 GIF 图片失败");
            }
            [animationGIFName32Arr addObject:gifName];
        }else{
            NSMutableArray *dataAnimation = [[NSMutableArray alloc] init];
            for (int q = 0; q < animationModelOrigin.dataAnimation.count; q++) {
                NSArray *dataAnimationOrigin = animationModelOrigin.dataAnimation[q];
                
                NSMutableArray *colArr = [[NSMutableArray alloc] init];
                for (int i = 0; i < dataAnimationOrigin.count; i++) {
                    NSMutableArray *rowArr = [[NSMutableArray alloc] init];
                    NSArray *tols = [dataAnimationOrigin objectAtIndex:i];
                    for (int j = 0; j < tols.count; j++) {
                        NSArray *rgbOriginArray = dataAnimationOrigin[i][j];
                        NSMutableArray *rgbArray = [[NSMutableArray alloc] init];
                        for (int m = 0; m < rgbOriginArray.count; m++) {
                            NSNumber *rgb = rgbOriginArray[m];
                            [rgbArray addObject:rgb];
                        }
                        [rowArr addObject:rgbArray];
                    }
                    [colArr addObject:rowArr];
                }
                [dataAnimation addObject:colArr];
            }
            
            animationModel.dataAnimation = [dataAnimation copy];
        }
        [animationModel32Arr addObject:animationModel];
    }
    
    
    ColorItemModel32 *colorItemModel32 = [[ColorItemModel32 alloc] init];
    
    colorItemModel32.itemContentCount = colorItemModel32Origin.itemContentCount;
    colorItemModel32.itemShowTime = colorItemModel32Origin.itemShowTime;
    colorItemModel32.masterplateCaseType = colorItemModel32Origin.masterplateCaseType;
    colorItemModel32.colorTextModel32Arr = [colorTextModel32Arr copy];
    colorItemModel32.graffitiModel32Arr = [graffitiModel32Arr copy];
    colorItemModel32.animationGIFName32Arr = [animationGIFName32Arr copy];
    colorItemModel32.animationModel32Arr = [animationModel32Arr copy];
    colorItemModel32.isSelected = colorItemModel32Origin.isSelected;
    colorItemModel32.selectIndex = colorItemModel32Origin.selectIndex;
    colorItemModel32.itemName = colorItemModel32Origin.itemName;
    colorItemModel32.itemDeviceIdentify = colorItemModel32Origin.itemDeviceIdentify;
    colorItemModel32.timestampInMilliseconds = (NSInteger)([[NSDate date] timeIntervalSince1970] * 1000);
    return colorItemModel32;
}

+ (EyeItemModel *)getEyeItemModelFrom:(EyeItemModel *)eyeItemModelOrigin{
    EyeItemModel *eyeItemModel = [[EyeItemModel alloc] init];
    eyeItemModel.timestampInMillisecondsEye = (NSInteger)([[NSDate date] timeIntervalSince1970] * 1000);
    eyeItemModel.itemDeviceIdentifyEye = eyeItemModelOrigin.itemDeviceIdentifyEye;
    eyeItemModel.itemShowTimeEye = eyeItemModelOrigin.itemShowTimeEye;
    eyeItemModel.isSelectedEye = eyeItemModelOrigin.isSelectedEye;
    ColorItemModel32 *textModelCopyL = [JTCommon getNewColorItemModel32From:eyeItemModelOrigin.textModelEyeL];
    eyeItemModel.textModelEyeL = textModelCopyL;
    ColorItemModel32 *textModelCopyR = [JTCommon getNewColorItemModel32From:eyeItemModelOrigin.textModelEyeR];
    eyeItemModel.textModelEyeR = textModelCopyR;
    return eyeItemModel;
}

+(NSArray *)copyDataSub:(NSArray *)dataAnimationOrigin{
    NSMutableArray *colArr = [[NSMutableArray alloc] init];
    for (int i = 0; i < dataAnimationOrigin.count; i++) {
        NSMutableArray *rowArr = [[NSMutableArray alloc] init];
        NSArray *tols = [dataAnimationOrigin objectAtIndex:i];
        for (int j = 0; j < tols.count; j++) {
            NSArray *rgbOriginArray = dataAnimationOrigin[i][j];
            NSMutableArray *rgbArray = [[NSMutableArray alloc] init];
            for (int m = 0; m < rgbOriginArray.count; m++) {
                NSNumber *rgb = rgbOriginArray[m];
                [rgbArray addObject:rgb];
            }
            [rowArr addObject:rgbArray];
        }
        [colArr addObject:rowArr];
    }
    return colArr;
}

+ (BOOL)compareColorItemModel32Origin:(ColorItemModel32 *)colorItemModel32Origin colorItemModel32New:(ColorItemModel32 *)colorItemModel32New{
    
    if(colorItemModel32Origin.itemContentCount != colorItemModel32New.itemContentCount || colorItemModel32Origin.itemShowTime != colorItemModel32New.itemShowTime  || colorItemModel32Origin.isSelected != colorItemModel32New.isSelected || colorItemModel32Origin.selectIndex != colorItemModel32New.selectIndex || ![colorItemModel32Origin.itemName isEqual:colorItemModel32New.itemName]){
        
        return NO;
        
    }
    
    for (int i = 0; i < colorItemModel32Origin.colorTextModel32Arr.count; i++) {
        
        ColorTextModel32 *colorTextModelOrigin = colorItemModel32Origin.colorTextModel32Arr[i];
        ColorTextModel32 *colorTextModelNew = colorItemModel32New.colorTextModel32Arr[i];
        
        if(colorTextModelOrigin.bold != colorTextModelNew.bold || colorTextModelOrigin.degree != colorTextModelNew.degree || colorTextModelOrigin.font != colorTextModelNew.font || colorTextModelOrigin.fontDefaultFit != colorTextModelNew.fontDefaultFit || colorTextModelOrigin.fontSpace != colorTextModelNew.fontSpace || colorTextModelOrigin.isMirror != colorTextModelNew.isMirror || colorTextModelOrigin.coverType != colorTextModelNew.coverType || colorTextModelOrigin.startRow != colorTextModelNew.startRow || colorTextModelOrigin.startCol != colorTextModelNew.startCol || colorTextModelOrigin.widthData != colorTextModelNew.widthData || colorTextModelOrigin.heightData != colorTextModelNew.heightData || colorTextModelOrigin.showModel != colorTextModelNew.showModel || colorTextModelOrigin.speedData != colorTextModelNew.speedData || colorTextModelOrigin.stayTime != colorTextModelNew.stayTime || colorTextModelOrigin.dazzleShowModel != colorTextModelNew.dazzleShowModel || colorTextModelOrigin.dazzleSpeedData != colorTextModelNew.dazzleSpeedData || colorTextModelOrigin.dazzleShowModelDirection != colorTextModelNew.dazzleShowModelDirection || colorTextModelOrigin.dazzleIndexSelect != colorTextModelNew.dazzleIndexSelect || ![colorTextModelOrigin.dazzleType isEqual:colorTextModelNew.dazzleType] || colorTextModelOrigin.dazzleTypeLength != colorTextModelNew.dazzleTypeLength || colorTextModelOrigin.coverTypeEdge != colorTextModelNew.coverTypeEdge || colorTextModelOrigin.startRowEdge != colorTextModelNew.startRowEdge || colorTextModelOrigin.startColEdge != colorTextModelNew.startColEdge || colorTextModelOrigin.widthDataEdge != colorTextModelNew.widthDataEdge || colorTextModelOrigin.heightDataEdge != colorTextModelNew.heightDataEdge || colorTextModelOrigin.showModelEdge != colorTextModelNew.showModelEdge || colorTextModelOrigin.speedDataEdge != colorTextModelNew.speedDataEdge || colorTextModelOrigin.heightEdge != colorTextModelNew.heightEdge || colorTextModelOrigin.edgingIndexSelect != colorTextModelNew.edgingIndexSelect || ![colorTextModelOrigin.edgeContent isEqual: colorTextModelNew.edgeContent] || colorTextModelOrigin.edgelenght != colorTextModelNew.edgelenght || colorTextModelOrigin.colorShowType != colorTextModelNew.colorShowType || colorTextModelOrigin.isEdge != colorTextModelNew.isEdge || ![colorTextModelOrigin.originText isEqual:colorTextModelNew.originText] || colorTextModelOrigin.itemContentCount != colorTextModelNew.itemContentCount){
            return NO;
        }
        
        NSArray * textItemsArrOrigin = colorTextModelOrigin.textItems;
        NSArray * textItemsArrNew = colorTextModelNew.textItems;
        
        for (int j = 0; j < textItemsArrOrigin.count; j++) {
            
            HLColorTextItem *textItemOrigin = textItemsArrOrigin[j];
            HLColorTextItem *textItemNew = textItemsArrNew[j];
            if(textItemOrigin.itemType != textItemNew.itemType || ![textItemOrigin.rgbString isEqual:textItemNew.rgbString] || ![textItemOrigin.text isEqual:textItemNew.text]){
                return NO;
            }
        }
        
    }
    
    for (int i = 0; i < colorItemModel32Origin.graffitiModel32Arr.count; i++) {
        
        GraffitiModel32 *graffitiModelOrigin = colorItemModel32Origin.graffitiModel32Arr[i];
        GraffitiModel32 *graffitiModelNew = colorItemModel32New.graffitiModel32Arr[i];
        
        if(graffitiModelOrigin.coverTypeGraffiti != graffitiModelNew.coverTypeGraffiti || graffitiModelOrigin.startRowGraffiti != graffitiModelNew.startRowGraffiti || graffitiModelOrigin.startColGraffiti != graffitiModelNew.startColGraffiti || graffitiModelOrigin.widthDataGraffiti != graffitiModelNew.widthDataGraffiti || graffitiModelOrigin.heightDataGraffiti != graffitiModelNew.heightDataGraffiti || graffitiModelOrigin.showModelGraffiti != graffitiModelNew.showModelGraffiti || graffitiModelOrigin.speedDataGraffiti != graffitiModelNew.speedDataGraffiti || graffitiModelOrigin.stayTimeGraffiti != graffitiModelNew.stayTimeGraffiti ){
            return NO;
        }
        
        for (int i = 0; i < graffitiModelOrigin.dataGraffiti.count; i++) {
            NSArray *tols = [graffitiModelOrigin.dataGraffiti objectAtIndex:i];
            for (int j = 0; j < tols.count; j++) {
                NSArray *rgbOriginArray = graffitiModelOrigin.dataGraffiti[i][j];
                NSMutableArray *rgbNewArray = graffitiModelNew.dataGraffiti[i][j];
                for (int m = 0; m < rgbOriginArray.count; m++) {
                    NSNumber *rgbOrigin = rgbOriginArray[m];
                    NSNumber *rgbNew = rgbNewArray[m];
                    if([rgbOrigin intValue] != [rgbNew intValue])
                        return NO;
                }
            }
        }
        
    }
    
    for (int i = 0; i < colorItemModel32Origin.animationModel32Arr.count; i++) {
        
        AnimationModel32 *animationModelOrigin = colorItemModel32Origin.animationModel32Arr[i];
        AnimationModel32 *animationModelNew = colorItemModel32New.animationModel32Arr[i];
        
        if(animationModelOrigin.coverTypeAnimation != animationModelNew.coverTypeAnimation || animationModelOrigin.startRowAnimation != animationModelNew.startRowAnimation || animationModelOrigin.startColAnimation != animationModelNew.startColAnimation || animationModelOrigin.widthDataAnimation != animationModelNew.widthDataAnimation || animationModelOrigin.heightDataAnimation != animationModelNew.heightDataAnimation || animationModelOrigin.timeIntervalAnimation != animationModelNew.timeIntervalAnimation ){
            return NO;
        }
        
        for (int q = 0; q < animationModelOrigin.dataAnimation.count; q++) {
            NSArray *dataAnimationOrigin = animationModelOrigin.dataAnimation[q];
            NSArray *dataAnimationNew = animationModelNew.dataAnimation[q];
            
            for (int i = 0; i < dataAnimationOrigin.count; i++) {
                NSArray *tols = [dataAnimationOrigin objectAtIndex:i];
                for (int j = 0; j < tols.count; j++) {
                    NSArray *rgbOriginArray = dataAnimationOrigin[i][j];
                    NSArray *rgbNewArray = dataAnimationNew[i][j];
                    for (int m = 0; m < rgbOriginArray.count; m++) {
                        NSNumber *rgbOrigin = rgbOriginArray[m];
                        NSNumber *rgbNew = rgbNewArray[m];
                        if([rgbOrigin intValue] != [rgbNew intValue])
                            return NO;
                    }
                }
            }
        }
        
    }
    
    return YES;
}

+ (BOOL)hasPasswordDevice{
    if([ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDM16 || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDMX16 || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDM16 || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDM32 || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDU16 || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDUX16 || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDU32 || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDUiLedBike12 || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDU24 || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDU20 || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDHeightAdaption || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDS1632 || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDS1664 || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDS1696 || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDS16192 || [ThemManager sharedInstance].deviceType == BTPeripheralTypeCoolLEDC48){
        return YES;
    }
    return NO;
}

+ (EyeItemModel *)getEyeItemModel{
    
    EyeItemModel *eyeItemModel = [[EyeItemModel alloc] init];
    
    NSMutableArray *colorTextModel32Arr = [[NSMutableArray alloc] init];
    eyeItemModel.itemDeviceIdentifyEye = [ThemManager sharedInstance].itemDeviceIdentify;
    eyeItemModel.itemShowTimeEye = 1;
    eyeItemModel.isSelectedEye = NO;
    eyeItemModel.selectIndexEye = 0;
    eyeItemModel.textModelEyeR = [JTCommon getColorItemModel32];
    eyeItemModel.textModelEyeL = [JTCommon getColorItemModel32];
    
    return eyeItemModel;
}

//模板类型
//屏幕高度32时，1、为1行文字，2、为2行文字，3、左图片右1行文字，4、左图片右2行文字，5、左1行文字右图片，6、左2行文字右图片，7、为一帧静态涂鸦，8、为动画
//屏幕高度16时，1、为1行文字，2、为一帧静态涂鸦，3、为动画，4、左图片右1行文字，5、左1行文字右图片，
//屏幕高度48时，1、为1行文字，2、为2行文字各24行文字，3、为2行文字上16文字下32文字，4、为2行文字上32文字下16文字，5、为3行16文字
+ (ColorItemModel32 *)getColorItemModel32WithMasterplateCaseType:(int) masterplateCaseType{
    
    ColorItemModel32 *colorItemModel32 = [[ColorItemModel32 alloc] init];
    colorItemModel32.masterplateCaseType = masterplateCaseType;
    NSMutableArray *colorTextModel32Arr = [[NSMutableArray alloc] init];
    
    //根据屏幕分辨率的高度创建节目对象
    switch (DeviceRow) {
        case 12:
        case 16:
        case 20:
        {
            switch (masterplateCaseType) {
                case 1:
                {
                    ColorTextModel32 *colorTextModel = [JTCommon getColorTextModel32WithCoverType:1 startRow:0 startCol:0 widthData:DeviceCol heightData:DeviceRow];
                    [colorTextModel32Arr addObject:colorTextModel];
                }
                    break;
                case 4:
                {
                    ColorTextModel32 *colorTextModel = [JTCommon getColorTextModel32WithCoverType:1 startRow:0 startCol:DeviceRow widthData:DeviceCol - DeviceRow heightData:DeviceRow];
                    [colorTextModel32Arr addObject:colorTextModel];
                }
                    break;
                case 5:
                {
                    ColorTextModel32 *colorTextModel = [JTCommon getColorTextModel32WithCoverType:1 startRow:0 startCol:0 widthData:DeviceCol - DeviceRow heightData:DeviceRow];
                    [colorTextModel32Arr addObject:colorTextModel];
                }
                    break;
                    
                default:
                    break;
            }
            
            colorItemModel32.itemShowTime = 1;
            colorItemModel32.colorTextModel32Arr = [colorTextModel32Arr copy];
            colorItemModel32.isSelected = NO;
            colorItemModel32.selectIndex = 0;
            colorItemModel32.itemName = @"";
            colorItemModel32.itemDeviceIdentify = [ThemManager sharedInstance].itemDeviceIdentify;
            colorItemModel32.graffitiImageName32Arr = [[NSArray alloc] init];
            colorItemModel32.graffitiModel32Arr = [[NSArray alloc] init];
            colorItemModel32.animationGIFName32Arr = [[NSArray alloc] init];
            colorItemModel32.animationModel32Arr = [[NSArray alloc] init];
            colorItemModel32.itemContentCount = [JTCommon getItemContentCount:colorItemModel32];
        }
            break;
        case 24:
        {
            switch (masterplateCaseType) {
                case 1:
                {
                    ColorTextModel32 *colorTextModel = [JTCommon getColorTextModel32WithCoverType:1 startRow:0 startCol:0 widthData:DeviceCol heightData:DeviceRow];
                    [colorTextModel32Arr addObject:colorTextModel];
                }
                    break;
                case 2:
                {
                    //第一行
                    ColorTextModel32 *colorTextModel = [JTCommon getColorTextModel32WithCoverType:1 startRow:0 startCol:0 widthData:DeviceCol heightData:DeviceRow * 0.5];
                    
                    //第二行
                    ColorTextModel32 *colorTextUnderModel = [JTCommon getColorTextModel32WithCoverType:1 startRow:DeviceRow * 0.5 startCol:0 widthData:DeviceCol heightData:DeviceRow * 0.5];
                    
                    [colorTextModel32Arr addObject:colorTextModel];
                    [colorTextModel32Arr addObject:colorTextUnderModel];
                }
                    break;
                case 3:
                {
                    ColorTextModel32 *colorTextModel = [JTCommon getColorTextModel32WithCoverType:1 startRow:0 startCol:DeviceRow widthData:DeviceCol - DeviceRow heightData:DeviceRow];
                    [colorTextModel32Arr addObject:colorTextModel];
                }
                    break;
                case 4:
                {
                    //第一行
                    ColorTextModel32 *colorTextModel = [JTCommon getColorTextModel32WithCoverType:1 startRow:0 startCol:DeviceRow widthData:DeviceCol - DeviceRow heightData:DeviceRow * 0.5];
                    
                    //第二行
                    ColorTextModel32 *colorTextUnderModel = [JTCommon getColorTextModel32WithCoverType:1 startRow:DeviceRow * 0.5 startCol:DeviceRow widthData:DeviceCol - DeviceRow heightData:DeviceRow * 0.5];
                    
                    [colorTextModel32Arr addObject:colorTextModel];
                    [colorTextModel32Arr addObject:colorTextUnderModel];
                }
                    break;
                case 5:
                {
                    ColorTextModel32 *colorTextModel = [JTCommon getColorTextModel32WithCoverType:1 startRow:0 startCol:0 widthData:DeviceCol - DeviceRow heightData:DeviceRow];
                    [colorTextModel32Arr addObject:colorTextModel];
                }
                    break;
                case 6:
                {
                    //第一行
                    ColorTextModel32 *colorTextModel = [JTCommon getColorTextModel32WithCoverType:1 startRow:0 startCol:0 widthData:DeviceCol - DeviceRow heightData:DeviceRow * 0.5];
                    
                    //第二行
                    ColorTextModel32 *colorTextUnderModel = [JTCommon getColorTextModel32WithCoverType:1 startRow:DeviceRow * 0.5 startCol:0 widthData:DeviceCol-DeviceRow heightData:DeviceRow * 0.5];
                    
                    [colorTextModel32Arr addObject:colorTextModel];
                    [colorTextModel32Arr addObject:colorTextUnderModel];
                }
                    break;
                default:
                    break;
            }
            
            colorItemModel32.itemShowTime = 1;
            colorItemModel32.colorTextModel32Arr = [colorTextModel32Arr copy];
            colorItemModel32.isSelected = NO;
            colorItemModel32.selectIndex = 0;
            colorItemModel32.itemName = @"";
            colorItemModel32.itemDeviceIdentify = [ThemManager sharedInstance].itemDeviceIdentify;
            colorItemModel32.graffitiImageName32Arr = [[NSArray alloc] init];
            colorItemModel32.graffitiModel32Arr = [[NSArray alloc] init];
            colorItemModel32.animationGIFName32Arr = [[NSArray alloc] init];
            colorItemModel32.animationModel32Arr = [[NSArray alloc] init];
            colorItemModel32.itemContentCount = [JTCommon getItemContentCount:colorItemModel32];
        }
            break;
        case 32:
        {
            switch (masterplateCaseType) {
                case 1:
                {
                    ColorTextModel32 *colorTextModel = [JTCommon getColorTextModel32WithCoverType:1 startRow:0 startCol:0 widthData:DeviceCol heightData:DeviceRow];
                    [colorTextModel32Arr addObject:colorTextModel];
                }
                    break;
                case 2:
                {
                    //第一行
                    ColorTextModel32 *colorTextModel = [JTCommon getColorTextModel32WithCoverType:1 startRow:0 startCol:0 widthData:DeviceCol heightData:DeviceRow * 0.5];
                    
                    //第二行
                    ColorTextModel32 *colorTextUnderModel = [JTCommon getColorTextModel32WithCoverType:1 startRow:DeviceRow * 0.5 startCol:0 widthData:DeviceCol heightData:DeviceRow * 0.5];
                    
                    [colorTextModel32Arr addObject:colorTextModel];
                    [colorTextModel32Arr addObject:colorTextUnderModel];
                }
                    break;
                case 3:
                {
                    ColorTextModel32 *colorTextModel = [JTCommon getColorTextModel32WithCoverType:1 startRow:0 startCol:DeviceRow widthData:DeviceCol - DeviceRow heightData:DeviceRow];
                    [colorTextModel32Arr addObject:colorTextModel];
                }
                    break;
                case 4:
                {
                    //第一行
                    ColorTextModel32 *colorTextModel = [JTCommon getColorTextModel32WithCoverType:1 startRow:0 startCol:DeviceRow widthData:DeviceCol - DeviceRow heightData:DeviceRow * 0.5];
                    
                    //第二行
                    ColorTextModel32 *colorTextUnderModel = [JTCommon getColorTextModel32WithCoverType:1 startRow:DeviceRow * 0.5 startCol:DeviceRow widthData:DeviceCol - DeviceRow heightData:DeviceRow * 0.5];
                    
                    [colorTextModel32Arr addObject:colorTextModel];
                    [colorTextModel32Arr addObject:colorTextUnderModel];
                }
                    break;
                case 5:
                {
                    ColorTextModel32 *colorTextModel = [JTCommon getColorTextModel32WithCoverType:1 startRow:0 startCol:0 widthData:DeviceCol - DeviceRow heightData:DeviceRow];
                    [colorTextModel32Arr addObject:colorTextModel];
                }
                    break;
                case 6:
                {
                    //第一行
                    ColorTextModel32 *colorTextModel = [JTCommon getColorTextModel32WithCoverType:1 startRow:0 startCol:0 widthData:DeviceCol -DeviceRow heightData:DeviceRow * 0.5];
                    
                    //第二行
                    ColorTextModel32 *colorTextUnderModel = [JTCommon getColorTextModel32WithCoverType:1 startRow:DeviceRow * 0.5 startCol:0 widthData:DeviceCol-DeviceRow heightData:DeviceRow * 0.5];
                    
                    [colorTextModel32Arr addObject:colorTextModel];
                    [colorTextModel32Arr addObject:colorTextUnderModel];
                }
                    break;
                default:
                    break;
            }
            
            colorItemModel32.itemShowTime = 1;
            colorItemModel32.colorTextModel32Arr = [colorTextModel32Arr copy];
            colorItemModel32.isSelected = NO;
            colorItemModel32.selectIndex = 0;
            colorItemModel32.itemName = @"";
            colorItemModel32.itemDeviceIdentify = [ThemManager sharedInstance].itemDeviceIdentify;
            colorItemModel32.graffitiImageName32Arr = [[NSArray alloc] init];
            colorItemModel32.graffitiModel32Arr = [[NSArray alloc] init];
            colorItemModel32.animationGIFName32Arr = [[NSArray alloc] init];
            colorItemModel32.animationModel32Arr = [[NSArray alloc] init];
            colorItemModel32.itemContentCount = [JTCommon getItemContentCount:colorItemModel32];
        }
            break;
        case 48:
        {
            switch (masterplateCaseType) {
                case 1:
                {
                    ColorTextModel32 *colorTextModel = [JTCommon getColorTextModel32WithCoverType:1 startRow:0 startCol:0 widthData:DeviceCol heightData:DeviceRow];
                    [colorTextModel32Arr addObject:colorTextModel];
                }
                    break;
                case 2:
                {
                    //第一行
                    ColorTextModel32 *colorTextModel = [JTCommon getColorTextModel32WithCoverType:1 startRow:0 startCol:0 widthData:DeviceCol heightData:DeviceRow * 0.5];
                    
                    //第二行
                    ColorTextModel32 *colorTextUnderModel = [JTCommon getColorTextModel32WithCoverType:1 startRow:DeviceRow * 0.5 startCol:0 widthData:DeviceCol heightData:DeviceRow * 0.5];
                    
                    [colorTextModel32Arr addObject:colorTextModel];
                    [colorTextModel32Arr addObject:colorTextUnderModel];
                }
                    break;
                case 3:
                {
                    //第一行
                    ColorTextModel32 *colorTextModel = [JTCommon getColorTextModel32WithCoverType:1 startRow:0 startCol:0 widthData:DeviceCol heightData:DeviceRow / 3];
                    
                    //第二行
                    ColorTextModel32 *colorTextUnderModel = [JTCommon getColorTextModel32WithCoverType:1 startRow:DeviceRow / 3 startCol:0 widthData:DeviceCol heightData:DeviceRow / 3 * 2];
                    
                    [colorTextModel32Arr addObject:colorTextModel];
                    [colorTextModel32Arr addObject:colorTextUnderModel];
                }
                    break;
                case 4:
                {
                    //第一行
                    ColorTextModel32 *colorTextModel = [JTCommon getColorTextModel32WithCoverType:1 startRow:0 startCol:0 widthData:DeviceCol heightData:DeviceRow / 3 * 2];
                    
                    //第二行
                    ColorTextModel32 *colorTextUnderModel = [JTCommon getColorTextModel32WithCoverType:1 startRow:DeviceRow / 3 * 2 startCol:0 widthData:DeviceCol heightData:DeviceRow / 3];
                    
                    [colorTextModel32Arr addObject:colorTextModel];
                    [colorTextModel32Arr addObject:colorTextUnderModel];
                }
                    break;
                case 5:
                {
                    //第一行
                    ColorTextModel32 *colorTextModel = [JTCommon getColorTextModel32WithCoverType:1 startRow:0 startCol:0 widthData:DeviceCol heightData:DeviceRow / 3];
                    
                    //第二行
                    ColorTextModel32 *colorTextCenterModel = [JTCommon getColorTextModel32WithCoverType:1 startRow:DeviceRow / 3 startCol:0 widthData:DeviceCol heightData:DeviceRow / 3];
                    
                    //第三行
                    ColorTextModel32 *colorTextUnderModel = [JTCommon getColorTextModel32WithCoverType:1 startRow:DeviceRow / 3 * 2 startCol:0 widthData:DeviceCol heightData:DeviceRow / 3];
                    
                    [colorTextModel32Arr addObject:colorTextModel];
                    [colorTextModel32Arr addObject:colorTextCenterModel];
                    [colorTextModel32Arr addObject:colorTextUnderModel];
                }
                    break;
                default:
                    break;
            }
            
            colorItemModel32.itemShowTime = 1;
            colorItemModel32.colorTextModel32Arr = [colorTextModel32Arr copy];
            colorItemModel32.isSelected = NO;
            colorItemModel32.selectIndex = 0;
            colorItemModel32.itemName = @"";
            colorItemModel32.itemDeviceIdentify = [ThemManager sharedInstance].itemDeviceIdentify;
            colorItemModel32.graffitiImageName32Arr = [[NSArray alloc] init];
            colorItemModel32.graffitiModel32Arr = [[NSArray alloc] init];
            colorItemModel32.animationGIFName32Arr = [[NSArray alloc] init];
            colorItemModel32.animationModel32Arr = [[NSArray alloc] init];
            colorItemModel32.itemContentCount = [JTCommon getItemContentCount:colorItemModel32];
            
        }
            break;
        default:
            break;
    }
    
    return colorItemModel32;
}

+ (ColorItemModel32 *)getColorItemModel32{
    //对节目的属性进行赋值
    NSMutableArray *colorTextModel32Arr = [[NSMutableArray alloc] init];
    NSMutableArray *graffitiImageName32Arr = [[NSMutableArray alloc] init];
    NSMutableArray *graffitiModel32Arr = [[NSMutableArray alloc] init];
    NSMutableArray *animationGIFName32Arr = [[NSMutableArray alloc] init];
    NSMutableArray *animationModel32Arr = [[NSMutableArray alloc] init];
    
    ColorItemModel32 *colorItemModel32 = [[ColorItemModel32 alloc] init];
    colorItemModel32.itemShowTime = 1;
    colorItemModel32.colorTextModel32Arr = [colorTextModel32Arr copy];
    colorItemModel32.graffitiImageName32Arr = [graffitiImageName32Arr copy];
    colorItemModel32.graffitiModel32Arr = [graffitiModel32Arr copy];
    colorItemModel32.animationGIFName32Arr = [animationGIFName32Arr copy];
    colorItemModel32.animationModel32Arr = [animationModel32Arr copy];
    colorItemModel32.clockTimeModelArr = [[NSArray alloc] init];
    colorItemModel32.dateTimeModelArr = [[NSArray alloc] init];
    colorItemModel32.itemContentCount = [JTCommon getItemContentCount:colorItemModel32];
    
    colorItemModel32.isSelected = NO;
    colorItemModel32.selectIndex = 0;
    colorItemModel32.itemName = @"";
    colorItemModel32.itemDeviceIdentify = [ThemManager sharedInstance].itemDeviceIdentify;
    
    return colorItemModel32;
}

+ (ColorTextModel32 *)getColorTextModel32WithCoverType:(int) coverTypeP startRow:(int) startRowP startCol:(int) startColP widthData:(int) widthDataP heightData:(int) heightDataP{
    
    //创建节目内容对象并赋值
    ColorTextModel32 *colorTextModel = [[ColorTextModel32 alloc] init];
    
    colorTextModel.coverType = coverTypeP;
    colorTextModel.startRow = startRowP;
    colorTextModel.startCol = startColP;
    colorTextModel.widthData =widthDataP;
    colorTextModel.movespace =widthDataP;
    colorTextModel.heightData = heightDataP;
    
    colorTextModel.coverTypeEdge = coverTypeP;
    colorTextModel.startRowEdge = startRowP;
    colorTextModel.startColEdge = startColP;
    colorTextModel.widthDataEdge = widthDataP;
    colorTextModel.heightDataEdge = heightDataP;
    
    return colorTextModel;
}

+ (GraffitiModel32 *)getGraffitiModel32WithCoverType:(int) coverTypeP startRow:(int) startRowP startCol:(int) startColP widthData:(int) widthDataP heightData:(int) heightDataP{
    //创建节目内容对象并赋值
    GraffitiModel32 *graffitiModel32 = [[GraffitiModel32 alloc] init];
    
    graffitiModel32.coverTypeGraffiti = coverTypeP;
    graffitiModel32.startRowGraffiti = startRowP;
    graffitiModel32.startColGraffiti = startColP;
    graffitiModel32.widthDataGraffiti =widthDataP;
    graffitiModel32.heightDataGraffiti = heightDataP;
    
    graffitiModel32.dataGraffiti = [[NSArray alloc] init];
    
    
    return graffitiModel32;
}

+ (AnimationModel32 *)getAnimationModel32WithCoverType:(int) coverTypeP startRow:(int) startRowP startCol:(int) startColP widthData:(int) widthDataP heightData:(int) heightDataP{
    
    //构建涂鸦相关参数
    int coverType = 1;
    int startRow = 0;
    int startCol = 0;
    int widthData = DeviceCol;
    int heightData = DeviceRow;
    int timeIntervalAnimation = 200;
    
    //对默认参数进行赋值
    coverType = coverTypeP;
    startRow = startRowP;
    startCol =  startColP;
    widthData = widthDataP;
    heightData = heightDataP;
    
    //创建节目内容对象并赋值
    AnimationModel32 *animationModel32 = [[AnimationModel32 alloc] init];
    
    animationModel32.coverTypeAnimation = coverType;
    animationModel32.startRowAnimation = startRow;
    animationModel32.startColAnimation = startCol;
    animationModel32.widthDataAnimation =widthData;
    animationModel32.heightDataAnimation = heightData;
    animationModel32.timeIntervalAnimation = timeIntervalAnimation;
    
    animationModel32.dataAnimation = [[NSArray alloc] init];
    
    return animationModel32;
}


+ (NSString *)resultStrWithData:(NSArray *)data
{
    NSString *result = @"";
    
    for (int i = 0; i < data.count; i++) {
        // rows 中是涂鸦每一列的数据
        NSArray *rows = data[i];
        
        int n = ceil(rows.count / 8.0);
        for (int j = 0; j < n; j++) {
            int sum = 0;
            for (int k = j * 8; k < (j+1) * 8 && k < rows.count; k++) {
                NSNumber *number = rows[k];
                sum += [number intValue] * (int)pow(2, (j+1) * 8 - 1 -k);
            }
            NSString *oneSumString = [NSString stringWithFormat:@"%02x",sum];
            result = [result stringByAppendingString:oneSumString];
        }
    }
    
    return result;
}

+ (BOOL)containMaterial{
    NSString *current = ItemDeviceIdentify;
    if([current isEqualToString:@"012016032"] || [current isEqualToString:@"012016064"]  || [current isEqualToString:@"012016096"] || [current isEqualToString:@"021016032"] || [current isEqualToString:@"021016064"]  || [current isEqualToString:@"021016096"] || [current isEqualToString:@"014016032"]  || [current isEqualToString:@"014016064"] || [current isEqualToString:@"014016096"] || [current isEqualToString:@"022016032"] || [current isEqualToString:@"022016064"]  || [current isEqualToString:@"022016096"] || [current isEqualToString:@"022016128"] || [current isEqualToString:@"022016192"] || [current isEqualToString:@"022016256"]  ||  [current isEqualToString:@"015032064"] || [current isEqualToString:@"015032096"] || [current isEqualToString:@"014016128"] || [current isEqualToString:@"014016192"] || [current isEqualToString:@"014016256"] || [current isEqualToString:@"015032128"] || [current isEqualToString:@"015032160"] || [current isEqualToString:@"015032192"] || [current isEqualToString:@"015032224"]  || [current isEqualToString:@"015032256"]  || [current isEqualToString:@"016012036"] || [current isEqualToString:@"017024048"] || [current isEqualToString:@"017024064"] || [current isEqualToString:@"017024096"] || [current isEqualToString:@"019020064"]){
        return YES;
    }
    
    if (([current hasPrefix:@"014"] || [current hasPrefix:@"015"] || [current hasPrefix:@"022"]) && [currentColNum intValue] <= 256) {
        return YES;
    }
    
    if([current isEqualToString:@"004016032"] || [current isEqualToString:@"005016064"]  || [current isEqualToString:@"006016096"] || [current isEqualToString:@"008016032"]  || [current isEqualToString:@"009016064"] || [current isEqualToString:@"010016096"]){
        return YES;
    }
    return NO;
}

+(CGFloat)getPixelWidth{
    CGFloat xOut,yOut,widthOut,heightOut,xInner,yInner,widthInner,heightInner,pixelWidth;
    xOut = 15;
    yOut = 32;
    
    xInner = 3;
    yInner = 3;
    widthInner = kWidth - 18 * 2;
    pixelWidth = widthInner / DeviceCol;
    
    //    return pixelWidth;
    return 82*scaleXL/DeviceRow;
}

+(NSDictionary *)makeWordCenter:(NSMutableArray *) dataM cols:(int)cols rows:(int)rows{
    // 补全最后一屏的空列
    int screenNumber = ((int)dataM.count + cols - 1) / cols;
    int startCol = (screenNumber - 1) * cols;
    int emptyHalfCol = (screenNumber * cols - (int)dataM.count)/2;
    for (int i = startCol; i < startCol + emptyHalfCol; i++ ) {
        NSArray *EmptyCol = [HLUtils emptyColArrayWith:@[@(0),@(0),@(0)] rows:rows];
        [dataM insertObject:EmptyCol atIndex:i];
    }
    for (int i = (int)dataM.count; i < screenNumber * cols; i++ ) {
        NSArray *EmptyCol = [HLUtils emptyColArrayWith:@[@(0),@(0),@(0)] rows:rows];
        [dataM addObject:EmptyCol];
    }
    
    NSDictionary *result = @{@"dataM":dataM,@"screenNumber":@(screenNumber)};
    return result;
}

//通过动画类型点阵生成字符串类型字节数组
+(NSString *)getStrFromAnimationArr:(NSArray *)data{
    
    NSMutableString *animationContent = [NSMutableString string];
    
    if([CurrentDeviceType isEqual:@"CoolLEDM"]){
        
        NSMutableArray *redData = [NSMutableArray array];
        NSMutableArray *greenData = [NSMutableArray array];
        NSMutableArray *blueData = [NSMutableArray array];
        
        for (int m = 0; m < data.count; m++) {
            NSArray *dataFrame = data[m];
            for (int i = 0; i < dataFrame.count; i++) {
                NSArray *cols = dataFrame[i];
                NSMutableArray *redCols = [NSMutableArray array];
                NSMutableArray *greenCols = [NSMutableArray array];
                NSMutableArray *blueCols = [NSMutableArray array];
                for (int j = 0; j < cols.count; j++) {
                    NSArray *rgbData = cols[j];
                    [redCols addObject:rgbData[0]];
                    [greenCols addObject:rgbData[1]];
                    [blueCols addObject:rgbData[2]];
                }
                [redData addObject:redCols];
                [greenData addObject:greenCols];
                [blueData addObject:blueCols];
            }
        }
        
        NSString *redResult = [JTCommon resultStrWithData:redData];
        
        NSString *greenResult = [JTCommon resultStrWithData:greenData];
        
        NSString *blueResult = [JTCommon resultStrWithData:blueData];
        
        [animationContent appendString:redResult];
        [animationContent appendString:greenResult];
        [animationContent appendString:blueResult];
        
    }else if([CurrentDeviceType isEqual:@"CoolLEDU"]){
        
        for (int m = 0; m < data.count; m++) {
            
            NSArray *dataFrame = data[m];
            NSMutableString *oneFrame = [NSMutableString string];
            
            for (int i = 0; i < dataFrame.count; i++) {
                NSArray *cols = dataFrame[i];
                
                NSMutableString *colStr = [NSMutableString string];
                for (int j = 0; j < cols.count; j++) {
                    NSArray *rgbData = cols[j];
                    
                    CGFloat red = [rgbData[0] floatValue] ;
                    CGFloat green = [rgbData[1] floatValue];
                    CGFloat blue = [rgbData[2] floatValue];
                    
                    NSString *onePixel = [NSString stringWithFormat:@"%02x%02x",[HLUtils colorExchangeFloat:red], [HLUtils colorExchangeFloat:green] * 16 + [HLUtils colorExchangeFloat:blue]];
                    [colStr appendString:onePixel];
                }
                [oneFrame appendString:colStr];
            }
            [animationContent appendString:oneFrame];
        }
    }
    
    return animationContent;
}

//通过动画类型点阵生成字符串类型字节数组-分享JSON格式对应的数据结构
+(NSString *)shareStrFromAnimationArr:(NSArray *)data{
    
    NSMutableString *animationContent = [NSMutableString string];
    
    if([CurrentDeviceType isEqual:@"CoolLEDM"]){
        
        NSMutableArray *redData = [NSMutableArray array];
        NSMutableArray *greenData = [NSMutableArray array];
        NSMutableArray *blueData = [NSMutableArray array];
        
        for (int m = 0; m < data.count; m++) {
            NSArray *dataFrame = data[m];
            for (int i = 0; i < dataFrame.count; i++) {
                NSArray *cols = dataFrame[i];
                NSMutableArray *redCols = [NSMutableArray array];
                NSMutableArray *greenCols = [NSMutableArray array];
                NSMutableArray *blueCols = [NSMutableArray array];
                for (int j = 0; j < cols.count; j++) {
                    NSArray *rgbData = cols[j];
                    [redCols addObject:rgbData[0]];
                    [greenCols addObject:rgbData[1]];
                    [blueCols addObject:rgbData[2]];
                }
                [redData addObject:redCols];
                [greenData addObject:greenCols];
                [blueData addObject:blueCols];
            }
        }
        
        NSString *redResult = [JTCommon resultStrWithData:redData];
        
        NSString *greenResult = [JTCommon resultStrWithData:greenData];
        
        NSString *blueResult = [JTCommon resultStrWithData:blueData];
        
        [animationContent appendString:redResult];
        [animationContent appendString:greenResult];
        [animationContent appendString:blueResult];
        
    }else if([CurrentDeviceType isEqual:@"CoolLEDU"]){
        
        for (int m = 0; m < data.count; m++) {
            
            NSArray *dataFrame = data[m];
            NSMutableString *oneFrame = [NSMutableString string];
            
            for (int i = 0; i < dataFrame.count; i++) {
                NSArray *cols = dataFrame[i];
                
                NSMutableString *colStr = [NSMutableString string];
                for (int j = 0; j < cols.count; j++) {
                    NSArray *rgbData = cols[j];
                    
                    CGFloat red = [rgbData[0] floatValue] ;
                    CGFloat green = [rgbData[1] floatValue];
                    CGFloat blue = [rgbData[2] floatValue];
                    
                    NSString *onePixel = [NSString stringWithFormat:@"%02x%02x%02x", (int)(red * 255), (int)(green * 255), (int)(blue * 255)];
                    [colStr appendString:onePixel];
                }
                [oneFrame appendString:colStr];
            }
            [animationContent appendString:oneFrame];
        }
    }
    
    return animationContent;
}

+(NSArray *)getShareDataFrom:(NSArray *)frameArr{
    NSMutableArray *dataTotalArr = [[NSMutableArray alloc] init];
    NSString *dataTotalString = [JTCommon shareStrFromAnimationArr:frameArr];
    NSData *dataTotalData = [HLUtils stringToData:dataTotalString];
    
    Byte *byteArray = (Byte *)[dataTotalData bytes];
    NSUInteger length = [dataTotalData length];
    
    for (NSUInteger i = 0; i < length; i++) {
        NSInteger num = byteArray[i];
        [dataTotalArr addObject:@(num)];
    }
    
    return [dataTotalArr copy];
}

+(NSString *)getNowTimeTimestamp{
    
    NSDate* dat = [NSDate dateWithTimeIntervalSinceNow:0];
    
    NSTimeInterval a=[dat timeIntervalSince1970];
    
    NSString*timeString = [NSString stringWithFormat:@"%0.f", a];//转为字符型
    
    return timeString;
}

#pragma mark - tool method
+ (NSArray *)resultArrayWithDataArray:(NSArray *)data
{
    NSMutableArray *resultArray = [NSMutableArray array];
    for (int i = 0; i < data.count; i++) {
        // rows 中是涂鸦每一列的数据
        NSArray *rows = data[i];
        
        int n = ceil(rows.count / 8.0);
        for (int j = 0; j < n; j++) {
            int sum = 0;
            for (int k = j * 8; k < (j+1) * 8 && k < rows.count; k++) {
                NSNumber *number = rows[k];
                sum += [number intValue] * (int)pow(2, (j+1) * 8 - 1 -k);
            }
            
            [resultArray addObject:@(sum)];
        }
    }
    return [resultArray copy];
}

+(NSArray *)frameToRGBByte:(NSArray *)animationData{
    // 保存数据
    NSMutableArray *finalData = [NSMutableArray array];
    
    NSMutableArray *redData = [NSMutableArray array];
    NSMutableArray *greenData = [NSMutableArray array];
    NSMutableArray *blueData = [NSMutableArray array];
    
    for (NSArray *frameData in animationData) {
        for (int i = 0; i < frameData.count; i++) {
            NSArray *cols = frameData[i];
            NSMutableArray *redCols = [NSMutableArray array];
            NSMutableArray *greenCols = [NSMutableArray array];
            NSMutableArray *blueCols = [NSMutableArray array];
            for (int j = 0; j < cols.count; j++) {
                NSArray *rgbData = cols[j];
                [redCols addObject:rgbData[0]];
                [greenCols addObject:rgbData[1]];
                [blueCols addObject:rgbData[2]];
            }
            [redData addObject:redCols];
            [greenData addObject:greenCols];
            [blueData addObject:blueCols];
        }
    }
    
    NSArray *redResultData = [JTCommon resultArrayWithDataArray:redData];
    [finalData addObjectsFromArray:redResultData];
    NSArray *greenResultData = [JTCommon resultArrayWithDataArray:greenData];
    [finalData addObjectsFromArray:greenResultData];
    NSArray *blueResultData = [JTCommon resultArrayWithDataArray:blueData];
    [finalData addObjectsFromArray:blueResultData];
    
    return finalData;
}

+ (NSDictionary *)parseGIFWithData:(NSData *)gifData {
    NSMutableArray *frames = [NSMutableArray new];
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)gifData, NULL);
    NSNumber *firstDelayTime;
    NSNumber *delayTime;
    CGFloat animationTime = 0.0f;
    
    if (source) {
        size_t count = CGImageSourceGetCount(source);
        for (size_t i = 0; i < count; i++) {
            CGImageRef image = CGImageSourceCreateImageAtIndex(source, i, NULL);
            if (image) {
                [frames addObject:[UIImage imageWithCGImage:image]];
                CGImageRelease(image);
                
                NSDictionary *properties = (__bridge_transfer NSDictionary *)CGImageSourceCopyPropertiesAtIndex(source, i, NULL);
                NSDictionary *gifProperties = [properties objectForKey:(__bridge NSString *)kCGImagePropertyGIFDictionary];
                delayTime = [gifProperties objectForKey:(__bridge NSString *)kCGImagePropertyGIFDelayTime];
                animationTime += [delayTime floatValue];
                if (firstDelayTime == nil) {
                    firstDelayTime = delayTime;
                }
            }
        }
        CFRelease(source);
    }
    NSDictionary *gifDetail = @{@"frames":frames,@"delayTime":firstDelayTime};
    return gifDetail;
}

NSArray<NSNumber *> *getFrameDurationsFromGIF(UIImage *image) {
    NSMutableArray<NSNumber *> *frameDurations = [NSMutableArray array];
    
    NSData *imageData = UIImagePNGRepresentation(image); // 将 UIImage 转换为 PNG 数据，如果是 GIF 图像，会保留动画信息

    CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, NULL);
    size_t frameCount = CGImageSourceGetCount(imageSource);

    for (size_t i = 0; i < frameCount; i++) {
        CGImageRef frameImageRef = CGImageSourceCreateImageAtIndex(imageSource, i, NULL);
        NSDictionary *frameProperties = (__bridge_transfer NSDictionary *)CGImageSourceCopyPropertiesAtIndex(imageSource, i, NULL);
        NSDictionary *frameGIFProperties = frameProperties[(NSString *)kCGImagePropertyGIFDictionary];
        NSNumber *frameDuration = frameGIFProperties[(NSString *)kCGImagePropertyGIFDelayTime];

        [frameDurations addObject:frameDuration];

        CGImageRelease(frameImageRef);
    }

    CFRelease(imageSource);

    return frameDurations;
}

+(NSData *)makeAnimatedGif:(NSArray *)imgArray withDelayTime:(CGFloat)delayTime {
    NSUInteger kFrameCount = imgArray.count;
    
    NSDictionary *fileProperties = @{
        (__bridge id)kCGImagePropertyGIFDictionary: @{
            (__bridge id)kCGImagePropertyGIFLoopCount: @0, // 0 means loop forever
        }
    };
    
    NSDictionary *frameProperties = @{
        (__bridge id)kCGImagePropertyGIFDictionary: @{
            (__bridge id)kCGImagePropertyGIFDelayTime: @(delayTime), // a float (not double!) in seconds, rounded to centiseconds in the GIF data
        }
    };
    
    NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
    NSURL *fileURL = [documentsDirectoryURL URLByAppendingPathComponent:@"animated.gif"];
    
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL((__bridge CFURLRef)fileURL, kUTTypeGIF, kFrameCount, NULL);
    CGImageDestinationSetProperties(destination, (__bridge CFDictionaryRef)fileProperties);
    
    for (NSUInteger i = 0; i < kFrameCount; i++) {
        @autoreleasepool {
            UIImage *image =[imgArray objectAtIndex:i];  //Here is the change
            CGImageDestinationAddImage(destination, image.CGImage, (__bridge CFDictionaryRef)frameProperties);
        }
    }
    
    if (!CGImageDestinationFinalize(destination)) {
        NSLog(@"failed to finalize image destination");
    }
    CFRelease(destination);
    
    NSLog(@"url=%@", fileURL);
    
    NSData *gifData = [NSData dataWithContentsOfFile:@"animated.gif"];
    gifData = [NSData dataWithContentsOfURL:fileURL];
    
    return gifData;
}

+(void)saveAnimatedGifPhotoAlbum:(NSArray *)imgArray withDelayTime:(CGFloat)delayTime gifName:(NSString *)gifName {
    NSUInteger kFrameCount = imgArray.count;
    
    NSDictionary *fileProperties = @{
        (__bridge id)kCGImagePropertyGIFDictionary: @{
            (__bridge id)kCGImagePropertyGIFLoopCount: @0, // 0 means loop forever
        }
    };
    
    NSDictionary *frameProperties = @{
        (__bridge id)kCGImagePropertyGIFDictionary: @{
            (__bridge id)kCGImagePropertyGIFDelayTime: @(delayTime), // a float (not double!) in seconds, rounded to centiseconds in the GIF data
        }
    };
    
    NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
    NSURL *fileURL = [documentsDirectoryURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.gif",gifName]];
    
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL((__bridge CFURLRef)fileURL, kUTTypeGIF, kFrameCount, NULL);
    CGImageDestinationSetProperties(destination, (__bridge CFDictionaryRef)fileProperties);
    
    for (NSUInteger i = 0; i < kFrameCount; i++) {
        @autoreleasepool {
            UIImage *image =[imgArray objectAtIndex:i];  //Here is the change
            CGImageDestinationAddImage(destination, image.CGImage, (__bridge CFDictionaryRef)frameProperties);
        }
    }
    
    if (!CGImageDestinationFinalize(destination)) {
        NSLog(@"failed to finalize image destination");
    }
    CFRelease(destination);
    
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        PHAssetCreationRequest *request = [PHAssetCreationRequest creationRequestForAsset];
        [request addResourceWithType:PHAssetResourceTypePhoto fileURL:fileURL options:nil];
    } completionHandler:^(BOOL success, NSError *error) {
        if (success) {
            NSLog(@"GIF saved to camera roll");
            showText(@"导入成功");
        } else {
            NSLog(@"Error saving GIF: %@", error);
        }
    }];
}

+(void)saveAnimatedGif:(NSArray *)imgArray withDelayTime:(CGFloat)delayTime gifName:(NSString *)gifName {
    NSUInteger kFrameCount = imgArray.count;
    
    NSDictionary *fileProperties = @{
        (__bridge id)kCGImagePropertyGIFDictionary: @{
            (__bridge id)kCGImagePropertyGIFLoopCount: @0, // 0 means loop forever
        }
    };
    
    NSDictionary *frameProperties = @{
        (__bridge id)kCGImagePropertyGIFDictionary: @{
            (__bridge id)kCGImagePropertyGIFDelayTime: @(delayTime), // a float (not double!) in seconds, rounded to centiseconds in the GIF data
        }
    };
    
    NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
    NSURL *fileURL = [documentsDirectoryURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.gif",gifName]];
    
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL((__bridge CFURLRef)fileURL, kUTTypeGIF, kFrameCount, NULL);
    CGImageDestinationSetProperties(destination, (__bridge CFDictionaryRef)fileProperties);
    
    for (NSUInteger i = 0; i < kFrameCount; i++) {
        @autoreleasepool {
            UIImage *image =[imgArray objectAtIndex:i];  //Here is the change
            CGImageDestinationAddImage(destination, image.CGImage, (__bridge CFDictionaryRef)frameProperties);
        }
    }
    
    if (!CGImageDestinationFinalize(destination)) {
        NSLog(@"failed to finalize image destination");
    }
    CFRelease(destination);
}

+ (UIImage *)createImageFromPixelData:(NSArray *)pixelData width:(NSUInteger)width height:(NSUInteger)height  scale:(CGFloat)scale{
    // Create a CGBitmapContext to manipulate pixel data
    
    NSUInteger scaledWidth = width * scale;
    NSUInteger scaledHeight = height * scale;
    
    size_t bitsPerComponent = 8;
    size_t bytesPerPixel = 4;
    size_t bytesPerRow = bytesPerPixel * scaledWidth;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    unsigned char *rawData = (unsigned char *)malloc(scaledHeight * bytesPerRow);
    for (NSUInteger y = 0; y < scaledHeight; y++) {
        
        for (NSUInteger x = 0; x < scaledWidth; x++) {
            
            NSUInteger originalX = x / scale;
            NSUInteger originalY = y / scale;
            
            NSArray *pixelColor=pixelData[originalX][originalY];
            
            NSUInteger pixelIndex = y * width + x;
            UIColor *color = [UIColor colorWithRed:[pixelColor[0] floatValue] green:[pixelColor[1] floatValue] blue:[pixelColor[2] floatValue] alpha:1];
            
            // Get the components of the color (RGBA)
            CGFloat red, green, blue, alpha;
            [color getRed:&red green:&green blue:&blue alpha:&alpha];
            
            NSUInteger byteIndex = (y * bytesPerRow) + x * bytesPerPixel;
            rawData[byteIndex] = red * 255;    // Red
            rawData[byteIndex + 1] = green * 255;  // Green
            rawData[byteIndex + 2] = blue * 255;   // Blue
            rawData[byteIndex + 3] = alpha * 255;  // Alpha
        }
    }
    
    CGContextRef context = CGBitmapContextCreate(rawData, scaledWidth, scaledHeight, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    CGImageRef cgImage = CGBitmapContextCreateImage(context);
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    
    // Clean up
    CGContextRelease(context);
    CGImageRelease(cgImage);
    CGColorSpaceRelease(colorSpace);
    free(rawData);
    
    return image;
}

+ (UIImage *)createImageFromPixelData:(NSArray *)pixelData width:(NSUInteger)width height:(NSUInteger)height  scale:(CGFloat)scale monochrome:(NSString *)rgbString{
    // Create a CGBitmapContext to manipulate pixel data
    
    NSArray *rgbArray = [rgbString componentsSeparatedByString:@","];
    
    CGFloat red = [rgbArray[0] floatValue];
    CGFloat green = [rgbArray[1] floatValue];
    CGFloat blue = [rgbArray[2] floatValue];
    UIColor *selectColor = [UIColor colorWithRed:red green:green blue:blue alpha:1];
    
    NSUInteger scaledWidth = width * scale;
    NSUInteger scaledHeight = height * scale;
    
    size_t bitsPerComponent = 8;
    size_t bytesPerPixel = 4;
    size_t bytesPerRow = bytesPerPixel * scaledWidth;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    unsigned char *rawData = (unsigned char *)malloc(scaledHeight * bytesPerRow);
    for (NSUInteger y = 0; y < scaledHeight; y++) {
        
        for (NSUInteger x = 0; x < scaledWidth; x++) {
            
            NSUInteger originalX = x / scale;
            NSUInteger originalY = y / scale;
            
            NSNumber *pixelColor=pixelData[originalX][originalY];
            
            NSUInteger pixelIndex = y * width + x;
            UIColor *color = [pixelColor floatValue] ==  0 ? [UIColor colorWithRed:0 green:0 blue:0 alpha:0] : selectColor;
            
            // Get the components of the color (RGBA)
            CGFloat red, green, blue, alpha;
            [color getRed:&red green:&green blue:&blue alpha:&alpha];
            
            NSUInteger byteIndex = (y * bytesPerRow) + x * bytesPerPixel;
            rawData[byteIndex] = red * 255;    // Red
            rawData[byteIndex + 1] = green * 255;  // Green
            rawData[byteIndex + 2] = blue * 255;   // Blue
            rawData[byteIndex + 3] = alpha * 255;  // Alpha
        }
    }
    
    CGContextRef context = CGBitmapContextCreate(rawData, scaledWidth, scaledHeight, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    CGImageRef cgImage = CGBitmapContextCreateImage(context);
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    
    // Clean up
    CGContextRelease(context);
    CGImageRelease(cgImage);
    CGColorSpaceRelease(colorSpace);
    free(rawData);
    
    return image;
}

+ (void)saveImageToPhotoLibrary:(UIImage *)image {
    // Check if the user has authorized photo library access
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // Check the authorization status
            if (status == PHAuthorizationStatusAuthorized) {
                // Save the image to the photo library
                [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                    PHAssetCreationRequest *request = [PHAssetCreationRequest creationRequestForAsset];
                    [request addResourceWithType:PHAssetResourceTypePhoto data:UIImagePNGRepresentation(image) options:nil];
                } completionHandler:^(BOOL success, NSError *error) {
                    if (success) {
                        NSLog(@"Image saved to photo library.");
                    } else {
                        NSLog(@"Error saving image to photo library: %@", error);
                    }
                }];
            } else {
                NSLog(@"User denied access to photo library.");
            }
        });
    }];
}

+(void)saveGIFToPhotoLibrary:(NSData *)gifData{
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        PHAssetCreationRequest *request = [PHAssetCreationRequest creationRequestForAsset];
        [request addResourceWithType:PHAssetResourceTypePhoto data:gifData options:nil];
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        if (success) {
            NSLog(@"GIF saved to photo library.");
        } else {
            NSLog(@"Error saving GIF to photo library: %@", error);
        }
    }];
}

//获取图片的原始Data数据 - Improved version with better pixel averaging
+ (NSArray *)getColorDataDefaultFromImage:(UIImage *)image scale:(CGFloat)scale {
    // Use the image's actual size instead of forcing 160x32
    // This allows displaying images on different sized displays (96x16, 160x32, etc.)
    CGSize newSize = image.size;
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 1.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    if (!resizedImage) {
        NSLog(@"❌ Failed to resize image for LED display");
        return @[];
    }
    
    // Now process the properly resized image
    CGImageRef imageRef = [resizedImage CGImage];
    NSUInteger widthImage = CGImageGetWidth(imageRef);
    NSUInteger heightImage = CGImageGetHeight(imageRef);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char *rawData = (unsigned char*) calloc(heightImage * widthImage * 4, sizeof(unsigned char));
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * widthImage;
    NSUInteger bitsPerComponent = 8;
    
    // Create context and draw image into raw data buffer
    CGContextRef context = CGBitmapContextCreate(rawData, widthImage, heightImage, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    CGContextDrawImage(context, CGRectMake(0, 0, widthImage, heightImage), imageRef);
    
    // Create the data structure the LED matrix expects
    NSMutableArray *pixelData = [NSMutableArray arrayWithCapacity:widthImage];
    
    // Process column by column (which is how the LED matrix expects data)
    for (NSUInteger x = 0; x < widthImage; x++) {
        NSMutableArray *oneColColorArray = [NSMutableArray arrayWithCapacity:heightImage];
        
        // Process each pixel in this column
        for (NSUInteger y = 0; y < heightImage; y++) {
            // Calculate the byte index in the raw data
            NSUInteger byteIndex = (bytesPerRow * y) + (x * bytesPerPixel);
            
            // Ensure we don't exceed array bounds
            if (byteIndex + 3 < heightImage * widthImage * 4) {
                // Get RGB components and normalize to 0.0-1.0 range
                CGFloat red = (CGFloat)rawData[byteIndex] / 255.0f;
                CGFloat green = (CGFloat)rawData[byteIndex + 1] / 255.0f;
                CGFloat blue = (CGFloat)rawData[byteIndex + 2] / 255.0f;
                CGFloat alpha = (CGFloat)rawData[byteIndex + 3] / 255.0f;
                
                // Apply alpha pre-multiplication for transparent pixels
                if (alpha < 1.0) {
                    red *= alpha;
                    green *= alpha;
                    blue *= alpha;
                }
                
                // Round to 4 decimal places for precision
                NSNumber *rNumberValue = [NSNumber numberWithFloat:roundf(red * 10000.0) / 10000.0];
                NSNumber *gNumberValue = [NSNumber numberWithFloat:roundf(green * 10000.0) / 10000.0];
                NSNumber *bNumberValue = [NSNumber numberWithFloat:roundf(blue * 10000.0) / 10000.0];
                
                // Add the RGB values as an array to our column data
                [oneColColorArray addObject:@[rNumberValue, gNumberValue, bNumberValue]];
            } else {
                // Failsafe for any out-of-bounds issues
                NSLog(@"⚠️ Warning: Out of bounds at byte index %lu", (unsigned long)byteIndex);
                [oneColColorArray addObject:@[@0, @0, @0]]; // Black pixel as fallback
            }
        }
        
        // Add this column to our pixel data array
        [pixelData addObject:oneColColorArray];
    }
    
    // Clean up resources
    free(rawData);
    CGContextRelease(context);
    
    NSLog(@"✅ Image processed for LED display: %lu columns × %lu rows", (unsigned long)pixelData.count, pixelData.count > 0 ? (unsigned long)[pixelData[0] count] : 0);
    
    return [pixelData copy];
}

+ (NSArray *)getDataFromFontImage:(UIImage *)image scale:(CGFloat)scale {
    // First create a properly resized image to avoid sampling artifacts
    CGSize newSize = CGSizeMake(160, 32); // Fixed LED matrix size
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 1.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    if (!resizedImage) {
        NSLog(@"❌ Failed to resize font image for LED display");
        return @[];
    }
    
    // Now process the properly resized image
    CGImageRef imageRef = [resizedImage CGImage];
    NSUInteger widthImage = CGImageGetWidth(imageRef);
    NSUInteger heightImage = CGImageGetHeight(imageRef);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char *rawData = (unsigned char*) calloc(heightImage * widthImage * 4, sizeof(unsigned char));
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * widthImage;
    NSUInteger bitsPerComponent = 8;
    
    // Create context and draw image into raw data buffer
    CGContextRef context = CGBitmapContextCreate(rawData, widthImage, heightImage, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    CGContextDrawImage(context, CGRectMake(0, 0, widthImage, heightImage), imageRef);
    
    // Create the data structure the LED matrix expects
    NSMutableArray *pixelData = [NSMutableArray arrayWithCapacity:widthImage];
    
    // Process column by column (which is how the LED matrix expects data)
    for (NSUInteger x = 0; x < widthImage; x++) {
        NSMutableArray *oneColColorArray = [NSMutableArray arrayWithCapacity:heightImage];
        
        // Process each pixel in this column
        for (NSUInteger y = 0; y < heightImage; y++) {
            // Calculate the byte index in the raw data
            NSUInteger byteIndex = (bytesPerRow * y) + (x * bytesPerPixel);
            
            // Get RGB values
            CGFloat red = (CGFloat)rawData[byteIndex] / 255.0f;
            CGFloat green = (CGFloat)rawData[byteIndex + 1] / 255.0f;
            CGFloat blue = (CGFloat)rawData[byteIndex + 2] / 255.0f;
            CGFloat alpha = (CGFloat)rawData[byteIndex + 3] / 255.0f;
            
            // Font image is a special case: we convert to binary values (0 or 1)
            // If any RGB component is non-zero, we consider it "on"
            if (red > 0.1 || green > 0.1 || blue > 0.1) {
                [oneColColorArray addObject:@1]; // Pixel is on
            } else {
                [oneColColorArray addObject:@0]; // Pixel is off
            }
        }
        
        // Add this column to our pixel data array
        [pixelData addObject:oneColColorArray];
    }
    
    // Clean up resources
    free(rawData);
    CGContextRelease(context);
    
    NSLog(@"✅ Font image processed for LED display: %lu columns × %lu rows", (unsigned long)pixelData.count, pixelData.count > 0 ? (unsigned long)[pixelData[0] count] : 0);
    
    return [pixelData copy];
}


+ (NSArray *)showDataArrayWithSendData:(NSArray *)sendData frames:(int)frames cols:(int)cols rows:(int)rows deviceType:(NSInteger)deviceType
{
    NSMutableArray *handledShowArray = [NSMutableArray array];
    
    
    // 1.1 取数据
    NSArray *data = sendData;
    
    int oneFrameCount = 0;
    
    int colBytes = 0;
    switch (rows) {
        case 12:
            colBytes = 3 * 12;
            break;
        case 16:
            colBytes = 3 * 16;
            break;
        case 20:
            colBytes = 3 * 20;
            break;
        case 24:
            colBytes = 3 * 24;
            break;
        case 32:
            colBytes = 3 * 32;
            break;
        case 48:
            colBytes = 3 * 32;
            break;
        default:
            break;
    }
    
    oneFrameCount = cols * colBytes;
    
    for (int i = 0; i < frames; i++) {
        // 2. 取一帧的各种颜色数据
        NSRange range = NSMakeRange(i * oneFrameCount, oneFrameCount);
        // 2.1 取一帧的数据
        NSArray *oneData = [data subarrayWithRange:range];
        // 3.组装每一个点的 rgb 值数据
        NSMutableArray *oneFrameData = [NSMutableArray array];
        
        NSInteger count = oneData.count / 3;
        NSMutableArray *newColArray = [NSMutableArray array];
        for (int j = 0; j < count; j++) {
            // 取出每一列的数据
            NSNumber *firstNumber = oneData[3 * j];
            NSNumber *secondNumber = oneData[3 * j + 1];
            NSNumber *thirdNumber = oneData[3 * j + 2];
            
            // 获取低位
            int red = [firstNumber intValue];
            // 获取高位
            int green  = [secondNumber intValue];
            // 获取低位
            int blue  = [thirdNumber intValue];
            
            
            NSArray *rgbArray = @[[NSNumber numberWithFloat:(red/255.0)], [NSNumber numberWithFloat:(green/255.0)], [NSNumber numberWithFloat:(blue/255.0)]];
            [newColArray addObject:rgbArray];
            
            if(newColArray.count  == rows){
                [oneFrameData addObject:[newColArray copy]];
                [newColArray  removeAllObjects];
            }
        }
        [handledShowArray addObject:[oneFrameData copy]];
        [oneFrameData  removeAllObjects];
    }
    
    return handledShowArray;
}

+(void)shareGraffitiData:(GraffitiModel32 *)graffitiModel32 vc:(UIViewController *)vc view:(UIView *)view{
    
    NSNumber * graffitiType ;
    
    if([CurrentDeviceType isEqual:@"CoolLEDM"]){
        graffitiType = @1;
    }else if ([CurrentDeviceType isEqual:@"CoolLEDU"]){
        graffitiType = @2;
    }
    
    [UIBarButtonItem appearance].tintColor = [UIColor blackColor];
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor blackColor]} forState:UIControlStateNormal];//将title 文字的颜色改为透明
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor blackColor]} forState:UIControlStateHighlighted];//将title 文字的颜色改为透明
    
    NSArray *graffitiData = [JTCommon getShareDataFrom:@[graffitiModel32.dataGraffiti]];
    NSDictionary *dataDict = @{@"graffitiType": graffitiType, @"pixelHeight": @(graffitiModel32.heightDataGraffiti), @"pixelWidth": @(graffitiModel32.widthDataGraffiti), @"speed": @(graffitiModel32.speedDataGraffiti + 239), @"mode": @(graffitiModel32.showModelGraffiti), @"stayTime": @(graffitiModel32.stayTimeGraffiti), @"graffitiData": graffitiData};
    NSDictionary *shareDataDict = @{@"dataType": @1, @"data": dataDict};
    NSArray *jsonArr = @[shareDataDict];
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonArr options:NSJSONWritingFragmentsAllowed error:&error];
    if (error == nil) {
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        
        // 将JSON字符串写入文件
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *filePath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_%@x%@_1_%@.jt",CurrentShareDeviceType,@(graffitiModel32.heightDataGraffiti),@(graffitiModel32.widthDataGraffiti),[JTCommon getNowTimeTimestamp]]];
        if ([jsonString writeToFile:filePath atomically:NO encoding:NSUTF8StringEncoding error:&error]) {
            NSLog(@"JSON file saved.");
            
            // 创建要分享的文件URL
            NSURL *fileURL = [NSURL fileURLWithPath:filePath];
            NSArray *activityItems = @[fileURL];
            UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
            activityVC.completionHandler = ^(NSString *activityType,BOOL completed){
                NSLog(@"activityType :%@", activityType);
                if(completed){
                    NSLog(@"completed");
                }else{
                    NSLog(@"cancel" );
                }
                [UIBarButtonItem appearance].tintColor = [UIColor whiteColor];
                [[UIBarButtonItem appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor clearColor]} forState:UIControlStateNormal];//将title 文字的颜色改为透明
                [[UIBarButtonItem appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor clearColor]} forState:UIControlStateHighlighted];//将title 文字的颜色改为透明
            };
            
            // 设置要排除的应用程序
            //activityVC.excludedActivityTypes = @[UIActivityTypePrint, UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll];
            
            // Set the popover source view or bar button item
            if ([activityVC respondsToSelector:@selector(popoverPresentationController)]) {
                UIPopoverPresentationController *popoverPresentationController = [activityVC popoverPresentationController];
                popoverPresentationController.sourceView = view; // Set the source view to a valid view object
                popoverPresentationController.sourceRect = CGRectMake(0, 0, 350, 500); // Optionally, set the source rect
                popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionAny; // Set the arrow direction of the popover
            }
            
            // 显示分享视图控制器
            [vc presentViewController:activityVC animated:YES completion:nil];
        }else {
            NSLog(@"Error: %@", error.localizedDescription);
        }
    }else {
        NSLog(@"Error: %@", error.localizedDescription);
    }
}


+(void)shareAnimationData:(AnimationModel32 *)animationModel32 vc:(UIViewController *)vc view:(UIView *)view{
    
    NSNumber * aniType ;
    
    if([CurrentDeviceType isEqual:@"CoolLEDM"]){
        aniType = @1;
    }else if ([CurrentDeviceType isEqual:@"CoolLEDU"]){
        aniType = @2;
    }
    
    [UIBarButtonItem appearance].tintColor = [UIColor blackColor];
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor blackColor]} forState:UIControlStateNormal];//将title 文字的颜色改为透明
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor blackColor]} forState:UIControlStateHighlighted];//将title 文字的颜色改为透明
    
    NSArray *aniDataArr = [JTCommon getShareDataFrom:animationModel32.dataAnimation];
    NSDictionary *dataDict = @{@"aniType": aniType, @"pixelHeight": @(animationModel32.heightDataAnimation), @"pixelWidth": @(animationModel32.widthDataAnimation), @"frameNum": @(animationModel32.dataAnimation.count), @"delays": @(animationModel32.timeIntervalAnimation), @"aniData": aniDataArr};
    NSDictionary *shareDataDict = @{@"dataType": @0, @"data": dataDict};
    NSArray *jsonArr = @[shareDataDict];
    
    
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonArr options:NSJSONWritingFragmentsAllowed error:&error];
    if (error == nil) {
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        
        // 将JSON字符串写入文件
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *filePath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_%@x%@_0_%@.jt",CurrentShareDeviceType,@(animationModel32.heightDataAnimation),@(animationModel32.widthDataAnimation),[JTCommon getNowTimeTimestamp]]];
        if ([jsonString writeToFile:filePath atomically:NO encoding:NSUTF8StringEncoding error:&error]) {
            NSLog(@"JSON file saved.");
            
            // 创建要分享的文件URL
            NSURL *fileURL = [NSURL fileURLWithPath:filePath];
            NSArray *activityItems = @[fileURL];
            UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
            activityVC.completionHandler = ^(NSString *activityType,BOOL completed){
                NSLog(@"activityType :%@", activityType);
                if(completed){
                    NSLog(@"completed");
                }else{
                    NSLog(@"cancel" );
                }
                [UIBarButtonItem appearance].tintColor = [UIColor whiteColor];
                [[UIBarButtonItem appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor clearColor]} forState:UIControlStateNormal];//将title 文字的颜色改为透明
                [[UIBarButtonItem appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor clearColor]} forState:UIControlStateHighlighted];//将title 文字的颜色改为透明
            };
            
            // 设置要排除的应用程序
            //activityVC.excludedActivityTypes = @[UIActivityTypePrint, UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll];
            
            // Set the popover source view or bar button item
            if ([activityVC respondsToSelector:@selector(popoverPresentationController)]) {
                UIPopoverPresentationController *popoverPresentationController = [activityVC popoverPresentationController];
                popoverPresentationController.sourceView = view; // Set the source view to a valid view object
                popoverPresentationController.sourceRect = CGRectMake(0, 0, 350, 500); // Optionally, set the source rect
                popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionAny; // Set the arrow direction of the popover
            }
            
            // 显示分享视图控制器
            [vc presentViewController:activityVC animated:YES completion:nil];
        }else {
            NSLog(@"Error: %@", error.localizedDescription);
        }
    }else {
        NSLog(@"Error: %@", error.localizedDescription);
    }
}

//state： 1表示图片，2表示gif type：1表示CoolLEDU设备
+ (NSArray *)getImageNameState:(int)state type:(NSInteger)type cols:(int)cols rows:(int)rows {
    NSArray *imageNameArr = [[NSArray alloc] init];
    switch (state) {
        case 1:
        {
            if(rows == 12 && cols ==12){
                imageNameArr = [self getNamesState:state cols:cols rows:rows count:34];
            }else if(rows == 12 && cols ==36){
                imageNameArr = [self getNamesState:state cols:cols rows:rows count:8];
            }else if(rows == 16 && cols ==16){
                imageNameArr = [self getNamesState:state cols:cols rows:rows count:50];
            }else if(rows == 16 && cols ==32){
                imageNameArr = [self getNamesState:state cols:cols rows:rows count:30];
            }else if(rows == 16 && cols == 64){
                imageNameArr = [self getNamesState:state cols:cols rows:rows count:24];
            }else if(rows == 16 && cols == 96){
                imageNameArr = [self getNamesState:state cols:cols rows:rows count:25];
            }else if(rows == 16 && cols == 128){
                imageNameArr = [self getNamesState:state cols:cols rows:rows count:2];
            }else if(rows == 32 && cols == 32){
                imageNameArr = [self getNamesState:state cols:cols rows:rows count:70];
            }else if(rows == 32 && cols == 64){
                imageNameArr = [self getNamesState:state cols:cols rows:rows count:40];
            }else if(rows == 32 && cols == 96){
                imageNameArr = [self getNamesState:state cols:cols rows:rows count:40];
            }else if(rows == 32 && cols == 128){
                imageNameArr = [self getNamesState:state cols:cols rows:rows count:24];
            }else if(rows == 32 && cols == 160){
                imageNameArr = [self getNamesState:state cols:cols rows:rows count:2];
            }
        }
            break;
        case 2:
        {
            if(rows == 12 && cols == 12){
                imageNameArr = [self getNamesState:state cols:cols rows:rows count:30];
            }else if(rows == 12 && cols == 36){
                imageNameArr = [self getNamesState:state cols:cols rows:rows count:37];
            }else if(rows == 16 && cols ==16){
                imageNameArr = [self getNamesState:state cols:cols rows:rows count:28];
            }else if(rows == 16 && cols ==32){
                imageNameArr = [self getNamesState:state cols:cols rows:rows count:24];
            }else if(rows == 16 && cols == 64){
                imageNameArr = [self getNamesState:state cols:cols rows:rows count:21];
            }else if(rows == 16 && cols == 96){
                imageNameArr = [self getNamesState:state cols:cols rows:rows count:20];
            }else if(rows == 16 && cols == 128){
                imageNameArr = [self getNamesState:state cols:cols rows:rows count:2];
            }else if(rows == 32 && cols == 32){
                imageNameArr = [self getNamesState:state cols:cols rows:rows count:60];
            }else if(rows == 32 && cols == 64){
                imageNameArr = [self getNamesState:state cols:cols rows:rows count:60];
            }else if(rows == 32 && cols == 96){
                imageNameArr = [self getNamesState:state cols:cols rows:rows count:40];
            }else if(rows == 32 && cols == 128){
                imageNameArr = [self getNamesState:state cols:cols rows:rows count:40];
            }else if(rows == 32 && cols == 160){
                imageNameArr = [self getNamesState:state cols:cols rows:rows count:2];
            }
        }
            break;
        default:
            break;
    }
    return imageNameArr;
}

//state： 1表示图片，2表示gif
+(NSArray *)getNamesState:(int)state cols:(int)cols rows:(int)rows count:(NSInteger)count{
    NSMutableArray *arrImage = [[NSMutableArray alloc] init];
    for (int i = 0; i<count; i++) {
        NSString *name;
        switch (state) {
            case 1:
                name = [NSString stringWithFormat:@"%d*%d_static%d",rows,cols,(i+1)];
                break;
            case 2:
                name = [NSString stringWithFormat:@"%d*%d_dynamic%d",rows,cols,(i+1)];
                break;
            default:
                break;
        }
        [arrImage addObject:name];
    }
    return arrImage;
}

+(NSString *)getElementName:(NSString *)index{
    NSDate *currentDate = [NSDate date];
    NSTimeInterval timestamp = [currentDate timeIntervalSince1970] * 1000;
    NSTimeInterval timestampInMilliseconds = round(timestamp);
    NSLog(@"当前时间戳（毫秒）：%f", timestampInMilliseconds);
    NSString *time = [NSString stringWithFormat:@"%ld",(NSInteger)timestampInMilliseconds];
    
    NSString *elementName = [NSString stringWithFormat:@"%@_%@_%@",[ThemManager sharedInstance].itemDeviceIdentify,time,index];
    return elementName;
}

+(void)saveGIFToPhotoAlbumwithAnimationModel32:(AnimationModel32 *) animationModel32{
    NSArray *handleShowDataArray = animationModel32.dataAnimation;
    int interval = animationModel32.timeIntervalAnimation;
    
    NSTimeInterval ti = interval / 1000.0;
    NSMutableArray *imageArr = [[NSMutableArray alloc] init];
    for (int i=0; i<handleShowDataArray.count; i++) {
        NSArray *dataArr = handleShowDataArray[i];
        UIImage * shareImage = [JTCommon createImageFromPixelData:dataArr width:animationModel32.widthDataAnimation height:animationModel32.heightDataAnimation scale:1];
        [imageArr addObject:shareImage];
    }
    NSString *index = [NSString stringWithFormat:@"%d",0];
    NSString *gifName = [JTCommon getElementName:index];
    [JTCommon saveAnimatedGifPhotoAlbum:imageArr withDelayTime:ti gifName:gifName];
}

+(ColorItemModel32 *)saveGIFwithColorItemModel32:(ColorItemModel32 *) colorItemModel32Data{
    //生成GIF图之前，先删除之间生成的gif图，在用data重新生成GIF图
    //1.删除GIF图
    NSArray *animationGIFName32ArrOrigin = colorItemModel32Data.animationGIFName32Arr;
    for (int i = 0; i<animationGIFName32ArrOrigin.count; i++) {
        NSString *gifName = animationGIFName32ArrOrigin[i];
        //读取gif名称，从沙盒中加载gif图片
        NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
        NSURL *fileURL = [documentsDirectoryURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.gif",gifName]];
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *error;
        
        BOOL fileExists = [fileManager fileExistsAtPath:fileURL.path];
        if (fileExists) {
            BOOL success = [fileManager removeItemAtURL:fileURL error:&error];
            if (success) {
                NSLog(@"成功删除 GIF 图像文件");
            } else {
                NSLog(@"删除 GIF 图像文件失败：%@", error.localizedDescription);
            }
        } else {
            NSLog(@"找不到 GIF 图像文件");
        }
    }
    
    //2.生成GIF图
    NSArray *animationModel32Arr = colorItemModel32Data.animationModel32Arr;
    NSMutableArray *animationGIFName32Arr = [[NSMutableArray alloc] init];
    for (int i = 0; i<animationModel32Arr.count; i++) {
        AnimationModel32 *animationModel32 = animationModel32Arr[i];
        NSArray *handleShowDataArray = animationModel32.dataAnimation;
        int interval = animationModel32.timeIntervalAnimation;
        
        NSTimeInterval ti = interval / 1000.0;
        NSMutableArray *imageArr = [[NSMutableArray alloc] init];
        for (int i=0; i<handleShowDataArray.count; i++) {
            NSArray *dataArr = handleShowDataArray[i];
            UIImage * shareImage = [JTCommon createImageFromPixelData:dataArr width:animationModel32.widthDataAnimation height:animationModel32.heightDataAnimation scale:1];
            [imageArr addObject:shareImage];
        }
        NSString *index = [NSString stringWithFormat:@"%d",i];
        NSString *gifName = [JTCommon getElementName:index];
        [JTCommon saveAnimatedGif:imageArr withDelayTime:ti gifName:gifName];
        
        [animationGIFName32Arr addObject:gifName];
        animationModel32.dataAnimation = [[NSArray alloc] init];
    }
    colorItemModel32Data.animationGIFName32Arr = [animationGIFName32Arr copy];
    return colorItemModel32Data;
}

+(ColorItemModel32 *)saveGIFDeleteDataAnimation:(ColorItemModel32 *) colorItemModel32Data{
    NSArray *animationModel32Arr = colorItemModel32Data.animationModel32Arr;
    NSArray *animationGIFName32Arr = colorItemModel32Data.animationGIFName32Arr;
    if(animationGIFName32Arr.count > 0){
        for (int i = 0; i<animationModel32Arr.count; i++) {
            AnimationModel32 *animationModel32 = animationModel32Arr[i];
            animationModel32.dataAnimation = [[NSArray alloc] init];
        }
    }
    return colorItemModel32Data;
}

+(void)deleteGIFwithColorItemModel32:(ColorItemModel32 *) colorItemModel32Data{
    NSArray *animationModel32Arr = colorItemModel32Data.animationModel32Arr;
    NSArray *animationGIFName32Arr = colorItemModel32Data.animationGIFName32Arr;
    if(animationGIFName32Arr.count == 0) return;
    for (int i = 0; i<animationModel32Arr.count; i++) {
        AnimationModel32 *animationModel32 = animationModel32Arr[i];
        NSArray *handleShowDataArray = animationModel32.dataAnimation;
        NSString *gifName = animationGIFName32Arr[i];
        if (handleShowDataArray.count == 0){
            //读取gif名称，从沙盒中加载gif图片
            NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
            NSURL *fileURL = [documentsDirectoryURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.gif",gifName]];
            
            
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSError *error;
            
            BOOL fileExists = [fileManager fileExistsAtPath:fileURL.path];
            if (fileExists) {
                BOOL success = [fileManager removeItemAtURL:fileURL error:&error];
                if (success) {
                    NSLog(@"成功删除 GIF 图像文件");
                } else {
                    NSLog(@"删除 GIF 图像文件失败：%@", error.localizedDescription);
                }
            } else {
                NSLog(@"找不到 GIF 图像文件");
            }
        }
    }
}

+(ColorItemModel32 *)getDataAnimationfromGIF:(ColorItemModel32 *)textModel{
    for (int i = 0; i<textModel.animationModel32Arr.count; i++) {
        AnimationModel32  *animationModel32 = textModel.animationModel32Arr[i];
        if(animationModel32.dataAnimation.count == 0){
            
            NSString *gifName = textModel.animationGIFName32Arr[i];
            NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
            NSURL *fileURL = [documentsDirectoryURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.gif",gifName]];
            NSMutableArray *pixelDataArray = [NSMutableArray array];
            NSDictionary *gifDetail = [JTCommon parseGIFWithData:[NSData dataWithContentsOfURL:fileURL]];
            NSArray *frames = gifDetail[@"frames"];
            NSNumber *delayTime = gifDetail[@"delayTime"];
            for (int j = 0; j<frames.count; j++) {
                UIImage *image = frames[j];
                NSArray *pixelData = [JTCommon getColorDataDefaultFromImage:image scale:1];
                [pixelDataArray addObject:pixelData];
            }
            animationModel32.dataAnimation = [pixelDataArray copy];
        }
    }
    
    return textModel;
}

+(NSData *)gifDecoding:(NSData *)data{
    
    // 假设你已经有一个名为data的NSData对象

    if (data.length >= 32) {
        // 创建一个可变的NSMutableData对象来进行替换操作
        NSMutableData *mutableData = [NSMutableData dataWithData:data];
        
        // 定义异或操作的字节值
        unsigned char xorByte = 0xDA;
        
        // 获取前32个字节的指针
        unsigned char *bytes = (unsigned char *)[mutableData mutableBytes];
        
        // 对前32个字节进行异或操作并替换
        for (NSUInteger i = 0; i < 32; i++) {
            bytes[i] ^= xorByte;
        }
        
        // 创建一个新的NSData对象，以替换后的字节数据
        NSData *replacedData = [NSData dataWithBytes:bytes length:data.length];
        
        // 使用替换后的数据进行后续操作
        // ...
        
        // 返回最新的NSData对象
        return replacedData;
    }
    return [[NSData alloc] init];
}

+(NSData* )enlargeGifPixels:(NSData*) inputData :(CGFloat) scale {
    NSError *error = nil;
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)inputData, NULL);
    if (source == NULL) {
        NSLog(@"Failed to create image source.");
        return nil;
    }
    
    size_t frameCount = CGImageSourceGetCount(source);
    NSMutableArray *frames = [NSMutableArray arrayWithCapacity:frameCount];
    NSMutableArray *delays = [NSMutableArray arrayWithCapacity:frameCount];
    
    for (size_t frameIndex = 0; frameIndex < frameCount; frameIndex++) {
        CGImageRef frameImageRef = CGImageSourceCreateImageAtIndex(source, frameIndex, NULL);
        if (frameImageRef == NULL) {
            NSLog(@"Failed to create frame image at index %zu", frameIndex);
            continue;
        }
        
        size_t imageWidth = CGImageGetWidth(frameImageRef);
        size_t imageHeight = CGImageGetHeight(frameImageRef);
        size_t scaledWidth = imageWidth * scale;
        size_t scaledHeight = imageHeight * scale;
        
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef context = CGBitmapContextCreate(NULL, scaledWidth, scaledHeight, 8, 0, colorSpace, kCGImageAlphaPremultipliedLast);
        CGContextSetInterpolationQuality(context, kCGInterpolationNone);
        CGContextDrawImage(context, CGRectMake(0, 0, scaledWidth, scaledHeight), frameImageRef);
        CGContextSetLineWidth(context, 0.1);

        // Add horizontal lines
        for (size_t y = 0; y < scaledHeight; y += scale) {
            CGContextSetRGBStrokeColor(context, 0, 0, 0, 1); // Set the separator line color to black
            CGContextMoveToPoint(context, 0, y);
            CGContextAddLineToPoint(context, scaledWidth, y);
            CGContextStrokePath(context);
        }
        
        // Add vertical lines
        for (size_t x = 0; x < scaledWidth; x += scale) {
            CGContextSetRGBStrokeColor(context, 0, 0, 0, 1); // Set the separator line color to black
            CGContextMoveToPoint(context, x, 0);
            CGContextAddLineToPoint(context, x, scaledHeight);
            CGContextStrokePath(context);
        }
        
        CGImageRef scaledImageRef = CGBitmapContextCreateImage(context);
        if (scaledImageRef != NULL) {
            [frames addObject:(__bridge id)scaledImageRef];
            CGImageRelease(scaledImageRef);
        }
        
        // Get the delay time for the current frame
        NSDictionary *frameProperties = (__bridge_transfer NSDictionary *)CGImageSourceCopyPropertiesAtIndex(source, frameIndex, NULL);
        NSDictionary *gifProperties = frameProperties[(NSString *)kCGImagePropertyGIFDictionary];
        NSNumber *delayTime = gifProperties[(NSString *)kCGImagePropertyGIFDelayTime];
        if (delayTime == nil) {
            delayTime = @(0.1); // Default delay time if not specified
        }
        [delays addObject:delayTime];
        
        CGContextRelease(context);
        CGColorSpaceRelease(colorSpace);
        CGImageRelease(frameImageRef);
    }
    
    CFRelease(source);
    
    // Create the output GIF data
    NSMutableData *outputData = [NSMutableData data];
    CGImageDestinationRef destination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)outputData, kUTTypeGIF, frameCount, NULL);
    if (destination != NULL) {
        NSDictionary *outputSettings = @{
            (NSString *)kCGImagePropertyGIFDictionary: @{
                (NSString *)kCGImagePropertyGIFLoopCount: @(0)
            }
        };
        CGImageDestinationSetProperties(destination, (__bridge CFDictionaryRef)outputSettings);
        
        for (size_t frameIndex = 0; frameIndex < frames.count; frameIndex++) {
            // Set the delay time for each frame
            NSNumber *delayTime = delays[frameIndex];
            
            NSDictionary *frameProperties = @{
                (NSString *)kCGImagePropertyGIFDictionary: @{
                    (NSString *)kCGImagePropertyGIFDelayTime: delayTime,
                    (NSString *)kCGImagePropertyGIFUnclampedDelayTime: delayTime
                }
            };
            
            CGImageDestinationAddImage(destination, (__bridge CGImageRef)frames[frameIndex], (__bridge CFDictionaryRef)frameProperties);
        }
        
        if (!CGImageDestinationFinalize(destination)) {
            NSLog(@"Failed to finalize the image destination.");
        }
        
CFRelease(destination);
   } else {
        NSLog(@"Failed to create the image destination.");
    }
    
    return [outputData copy];
}

+ (NSArray *)getSendDataFromDic:(NSDictionary *)dic
{
    
    // 保存数据
    NSMutableArray *finalData = [NSMutableArray array];
    
    // 1.预留24个0
    for (int i = 0; i < 24; i++) {
        [finalData addObject:@(0)];
    }
    
    // 2.动画有多少帧
    int frames = (int)[dic[@"frames"] intValue];
    [finalData addObject:@(frames)];
    
    // 3.动画的间隔
    int x = [dic[@"x"] intValue];
    int y = [dic[@"y"] intValue];
    // 先默认 200ms
    [finalData addObject:@(x)];
    [finalData addObject:@(y)];
    
    // 4. 将点阵图转换为数据
    NSMutableArray *redData = [NSMutableArray array];
    NSMutableArray *greenData = [NSMutableArray array];
    NSMutableArray *blueData = [NSMutableArray array];
    
    for (NSArray *frameData in dic[@"handledShowDataArray"]) {
        for (int i = 0; i < frameData.count; i++) {
            NSArray *cols = frameData[i];
            NSMutableArray *redCols = [NSMutableArray array];
            NSMutableArray *greenCols = [NSMutableArray array];
            NSMutableArray *blueCols = [NSMutableArray array];
            for (int j = 0; j < cols.count; j++) {
                NSArray *rgbData = cols[j];
                [redCols addObject:rgbData[0]];
                [greenCols addObject:rgbData[1]];
                [blueCols addObject:rgbData[2]];
            }
            [redData addObject:redCols];
            [greenData addObject:greenCols];
            [blueData addObject:blueCols];
        }
    }
    
    NSArray *redResultData = [JTCommon resultArrayWithDataArray:redData];
    [finalData addObjectsFromArray:redResultData];
    NSArray *greenResultData = [JTCommon resultArrayWithDataArray:greenData];
    [finalData addObjectsFromArray:greenResultData];
    NSArray *blueResultData = [JTCommon resultArrayWithDataArray:blueData];
    [finalData addObjectsFromArray:blueResultData];
    
    return [finalData copy];
}

+ (NSArray *)getCopyFrame:(NSArray *)frame
{
    NSMutableArray *dataCopy = [NSMutableArray array];
    for (int i = 0; i < frame.count; i++) {
        NSMutableArray *data = frame[i];
        NSMutableArray *colsArrayCopy = [[NSMutableArray alloc] init];
        for (int j = 0; j < data.count; j++) {
            NSMutableArray *colsArray = data[j];
            NSMutableArray *valueArrayCopy = [[NSMutableArray alloc] init];
            for (int m = 0; m < colsArray.count; m++) {
                NSNumber *value =colsArray[m];
                NSNumber *valueCopy = @([value intValue]);
                [valueArrayCopy addObject:valueCopy];
            }
            [colsArrayCopy addObject:valueArrayCopy];
        }
        [dataCopy addObject:colsArrayCopy];
    }
    return  [dataCopy copy];
}

//32一列4个字节，16一列2个字节，24一列3个字节
+(float)ratioStringByte:(NSInteger)wordShowHeight{
    float ratio;
    switch (wordShowHeight) {
        case 12:
        case 16:
            ratio = 1.0/4;
            break;
        case 20:
        case 24:
            ratio = 1.0/6;
            break;
        case 32:
            ratio = 1.0/8;
            break;
        case 48:
            ratio = 1.0/12;
            break;
        default:
            break;
    }
    return ratio;
}

+(void)saveDriveStateData:(NSInteger)state data:(ColorItemModel32 *)textModel{
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        ColorItemModel32 *textModelCopy = [JTCommon getNewColorItemModel32From:textModel];
        textModelCopy.timestampInMilliseconds = textModel.timestampInMilliseconds;
        NSString *filePath = [JTCommon filePathDriveStateWithKey:state];
        [NSKeyedArchiver archiveRootObject:textModelCopy toFile:filePath];
    });
    
}

//对文字对象设置默认字体

+(ColorTextModel32 *)getDefaultFontType:(ColorTextModel32 *)colorTextModel32 isLargeEdge:(BOOL)isLargeEdge{
    //判断文字内容是否有边框有边框用14字体，没有边框用16字体
    switch (colorTextModel32.heightData) {
        case 12:
        {
            colorTextModel32.fontDefaultFit = 12;
        }
            break;
        case 16:
        {
            if(colorTextModel32.isEdge || isLargeEdge){
                colorTextModel32.fontDefaultFit = 14;
            }else{
                colorTextModel32.fontDefaultFit = 16;
            }
        }
            break;
        case 20:
        {
            colorTextModel32.fontDefaultFit = 20;
        }
            break;
        case 24:
        {
            colorTextModel32.fontDefaultFit = 24;
        }
            break;
        case 32:
        {
            colorTextModel32.fontDefaultFit = 32;
        }
            break;
        case 48:
        {
            colorTextModel32.fontDefaultFit = 48;
        }
            break;
        default:
            break;
    }

    return colorTextModel32;
}

+(NSArray * )getMaxFontArr:(ColorTextModel32 *)colorTextModel32{
    //判断文字内容是否有边框有边框用14字体，没有边框用16字体
    NSInteger maxFont;
    NSArray *fontArr;
    switch (colorTextModel32.heightData) {
        case 12:
        {
            maxFont = 12;
            fontArr = @[@0,@12];
        }
            break;
        case 16:
        {
            maxFont = 16;
            fontArr = @[@0,@12,@14,@16];
        }
            break;
        case 20:
        {
            maxFont = 20;
            fontArr = @[@0,@12,@14,@16,@20];
        }
            break;
        case 24:
        {
            maxFont = 24;
            fontArr = @[@0,@12,@14,@16,@20,@24];
        }
            break;
        case 32:
        {
            maxFont = 32;
            fontArr = @[@0,@12,@14,@16,@20,@24,@32];
        }
            break;
        case 48:
        {
            maxFont = 48;
            fontArr = @[@0,@12,@14,@16,@20,@24,@32,@48];
        }
            break;
        default:
            break;
    }

    return fontArr;
}

//获取字库类型
+(NSData *)getFontTypeFont:(NSInteger)font bold:(BOOL)bold{
    NSURL *unicodeURL;
    NSData *unicodeData;
    
    switch (font) {
        case 12:
        {
            unicodeURL = [[NSBundle mainBundle] URLForResource:@"UNICODE12" withExtension:nil];
            if (bold) {
                unicodeURL = [[NSBundle mainBundle] URLForResource:@"UNICODE12" withExtension:nil];
            }
            unicodeData = [NSData dataWithContentsOfURL:unicodeURL];
        }
            break;
        case 14:
        {
            unicodeURL = [[NSBundle mainBundle] URLForResource:@"UNICODE14" withExtension:nil];
            if (bold) {
                unicodeURL = [[NSBundle mainBundle] URLForResource:@"UNICODE14_bold" withExtension:nil];
            }
            unicodeData = [NSData dataWithContentsOfURL:unicodeURL];
        }
            break;
        case 16:
        {
            unicodeURL = [[NSBundle mainBundle] URLForResource:@"UNICODE16forCoolEDM" withExtension:nil];
            if (bold) {
                unicodeURL = [[NSBundle mainBundle] URLForResource:@"UNICODE16_boldforCoolEDM" withExtension:nil];
            }
            unicodeData = [NSData dataWithContentsOfURL:unicodeURL];
        }
            break;
        case 20:
        {
            unicodeURL = [[NSBundle mainBundle] URLForResource:@"UNICODE20" withExtension:nil];
            if (bold) {
                unicodeURL = [[NSBundle mainBundle] URLForResource:@"UNICODE20_bold" withExtension:nil];
            }
            unicodeData = [NSData dataWithContentsOfURL:unicodeURL];
        }
            break;
        case 24:
        {
            unicodeURL = [[NSBundle mainBundle] URLForResource:@"UNICODE24" withExtension:nil];
            if (bold) {
                unicodeURL = [[NSBundle mainBundle] URLForResource:@"UNICODE24_bold" withExtension:nil];
            }
            unicodeData = [NSData dataWithContentsOfURL:unicodeURL];
        }
            break;
        case 32:
        {
            unicodeURL = [[NSBundle mainBundle] URLForResource:@"UNICODE32" withExtension:nil];
            if (bold) {
                unicodeURL = [[NSBundle mainBundle] URLForResource:@"UNICODE32_bold" withExtension:nil];
            }
            unicodeData = [NSData dataWithContentsOfURL:unicodeURL];
        }
            break;
        default:
            break;
    }
    
    return unicodeData;
}

+(NSData *)getOriginDataWordShowHeight:(NSInteger)wordShowHeight asciiCode:(int)asciiCode font:(NSInteger)font unicodeData:(NSData *)unicodeData degree:(int)degree{
    int offset;
    NSRange range;
    NSData *originData;
    
    switch (wordShowHeight) {
        case 12:
        {
            switch (font) {
                case 12:
                {
                    offset = asciiCode * 24;
                    range = NSMakeRange(offset, 24);
                    originData = [unicodeData subdataWithRange:range];
                    originData =[HLUtils rotateArrayData:originData font:font degree:degree];
                }
                    break;
                default:
                    break;
            }
        }
            break;
        case 16:
        {
            switch (font) {
                case 12:
                {
                    offset = asciiCode * 24;
                    range = NSMakeRange(offset, 24);
                    originData = [unicodeData subdataWithRange:range];
                    originData =[HLUtils rotateArrayData:originData font:font degree:degree];
                    originData =  [HLUtils iArrayRightShift:originData originColBytes:2 space:2 targetRow:16];
                }
                    break;
                case 14:
                {
                    offset = asciiCode * 28;
                    range = NSMakeRange(offset, 28);
                    originData = [unicodeData subdataWithRange:range];
                    originData =[HLUtils rotateArrayData:originData font:font degree:degree];
                    originData =  [HLUtils iArrayRightShift:originData originColBytes:2 space:1 targetRow:16];
                }
                    break;
                case 16:
                {
                    offset = asciiCode * 32;
                    range = NSMakeRange(offset, 32);
                    originData = [unicodeData subdataWithRange:range];
                    originData =[HLUtils rotateArrayData:originData font:font degree:degree];
                }
                    break;
                default:
                    break;
            }
            
        }
            break;
        case 20:
        {
            switch (font) {
                case 12:
                {
                    offset = asciiCode * 24;
                    range = NSMakeRange(offset, 24);
                    originData = [unicodeData subdataWithRange:range];
                    originData =[HLUtils rotateArrayData:originData font:font degree:degree];
                    originData =  [HLUtils iArrayRightShift:originData originColBytes:2 space:4 targetRow:20];
                }
                    break;
                case 14:
                {
                    offset = asciiCode * 28;
                    range = NSMakeRange(offset, 28);
                    originData = [unicodeData subdataWithRange:range];
                    originData =[HLUtils rotateArrayData:originData font:font degree:degree];
                    originData =  [HLUtils iArrayRightShift:originData originColBytes:2 space:3 targetRow:20];
                    
                }
                    break;
                case 16:
                {
                    offset = asciiCode * 32;
                    range = NSMakeRange(offset, 32);
                    originData = [unicodeData subdataWithRange:range];
                    originData =[HLUtils rotateArrayData:originData font:font degree:degree];
                    originData =  [HLUtils iArrayRightShift:originData originColBytes:2 space:2 targetRow:20];
                }
                    break;
                case 20:
                {
                    offset = asciiCode * 60;
                    range = NSMakeRange(offset, 60);
                    originData = [unicodeData subdataWithRange:range];
                    originData =[HLUtils rotateArrayData:originData font:font degree:degree];
                }
                    break;
                default:
                    break;
            }
        }
            break;
        case 24:
        {
            switch (font) {
                case 12:
                {
                    offset = asciiCode * 24;
                    range = NSMakeRange(offset, 24);
                    originData = [unicodeData subdataWithRange:range];
                    originData =[HLUtils rotateArrayData:originData font:font degree:degree];
                    originData =  [HLUtils iArrayRightShift:originData originColBytes:2 space:6 targetRow:24];
                }
                    break;
                case 14:
                {
                    offset = asciiCode * 28;
                    range = NSMakeRange(offset, 28);
                    originData = [unicodeData subdataWithRange:range];
                    originData =[HLUtils rotateArrayData:originData font:font degree:degree];
                    originData =  [HLUtils iArrayRightShift:originData originColBytes:2 space:5 targetRow:24];
                    
                }
                    break;
                case 16:
                {
                    offset = asciiCode * 32;
                    range = NSMakeRange(offset, 32);
                    originData = [unicodeData subdataWithRange:range];
                    originData =[HLUtils rotateArrayData:originData font:font degree:degree];
                    originData =  [HLUtils iArrayRightShift:originData originColBytes:2 space:4 targetRow:24];
                }
                    break;
                case 20:
                {
                    offset = asciiCode * 60;
                    range = NSMakeRange(offset, 60);
                    originData = [unicodeData subdataWithRange:range];
                    originData =[HLUtils rotateArrayData:originData font:font degree:degree];
                    originData =  [HLUtils iArrayRightShift:originData originColBytes:3 space:2 targetRow:24];
                }
                    break;
                case 24:
                {
                    offset = asciiCode * 72;
                    range = NSMakeRange(offset, 72);
                    originData = [unicodeData subdataWithRange:range];
                    originData =[HLUtils rotateArrayData:originData font:font degree:degree];
                }
                    break;
                default:
                    break;
            }
        }
            break;
        case 32:
        {
            switch (font) {
                case 12:
                {
                    offset = asciiCode * 24;
                    range = NSMakeRange(offset, 24);
                    originData = [unicodeData subdataWithRange:range];
                    originData =[HLUtils rotateArrayData:originData font:font degree:degree];
                    originData =  [HLUtils iArrayRightShift:originData originColBytes:2 space:10 targetRow:32];
                }
                    break;
                case 14:
                {
                    offset = asciiCode * 28;
                    range = NSMakeRange(offset, 28);
                    originData = [unicodeData subdataWithRange:range];
                    originData =[HLUtils rotateArrayData:originData font:font degree:degree];
                    originData =  [HLUtils iArrayRightShift:originData originColBytes:2 space:9 targetRow:32];
    
                }
                    break;
                case 16:
                {
                    offset = asciiCode * 32;
                    range = NSMakeRange(offset, 32);
                    originData = [unicodeData subdataWithRange:range];
                    originData =[HLUtils rotateArrayData:originData font:font degree:degree];
                    originData =  [HLUtils iArrayRightShift:originData originColBytes:2 space:8 targetRow:32];
                }
                    break;
                case 20:
                {
                    offset = asciiCode * 60;
                    range = NSMakeRange(offset, 60);
                    originData = [unicodeData subdataWithRange:range];
                    originData =[HLUtils rotateArrayData:originData font:font degree:degree];
                    originData =  [HLUtils iArrayRightShift:originData originColBytes:3 space:6 targetRow:32];
                }
                    break;
                case 24:
                {
                    offset = asciiCode * 72;
                    range = NSMakeRange(offset, 72);
                    originData = [unicodeData subdataWithRange:range];
                    originData =[HLUtils rotateArrayData:originData font:font degree:degree];
                    originData =  [HLUtils iArrayRightShift:originData originColBytes:3 space:4 targetRow:32];
                }
                    break;
                case 32:
                {
                    offset = asciiCode * 128;
                    range = NSMakeRange(offset, 128);
                    originData = [unicodeData subdataWithRange:range];
                    originData =[HLUtils rotateArrayData:originData font:font degree:degree];
                }
                    break;
                default:
                    break;
            }
        }
            break;
        case 48:
        {
            switch (font) {
                case 12:
                {
                    offset = asciiCode * 24;
                    range = NSMakeRange(offset, 24);
                    originData = [unicodeData subdataWithRange:range];
                    originData =[HLUtils rotateArrayData:originData font:font degree:degree];
                    originData = [HLUtils transferFontData:originData srcSize:12 dstSize:48];
                    
                }
                    break;
                case 14:
                {
                    offset = asciiCode * 28;
                    range = NSMakeRange(offset, 28);
                    originData = [unicodeData subdataWithRange:range];
                    originData =[HLUtils rotateArrayData:originData font:font degree:degree];
                    originData = [HLUtils transferFontData:originData srcSize:14 dstSize:48];
    
                }
                    break;
                case 16:
                {
                    offset = asciiCode * 32;
                    range = NSMakeRange(offset, 32);
                    originData = [unicodeData subdataWithRange:range];
                    originData =[HLUtils rotateArrayData:originData font:font degree:degree];
                    originData = [HLUtils transferFontData:originData srcSize:16 dstSize:48];
                }
                    break;
                case 20:
                {
                    offset = asciiCode * 60;
                    range = NSMakeRange(offset, 60);
                    originData = [unicodeData subdataWithRange:range];
                    originData =[HLUtils rotateArrayData:originData font:font degree:degree];
                    originData = [HLUtils transferFontData:originData srcSize:20 dstSize:48];
                }
                    break;
                case 24:
                {
                    offset = asciiCode * 72;
                    range = NSMakeRange(offset, 72);
                    originData = [unicodeData subdataWithRange:range];
                    originData =[HLUtils rotateArrayData:originData font:font degree:degree];
                    originData = [HLUtils transferFontData:originData srcSize:24 dstSize:48];
                }
                    break;
                case 32:
                {
                    offset = asciiCode * 128;
                    range = NSMakeRange(offset, 128);
                    originData = [unicodeData subdataWithRange:range];
                    originData = [HLUtils transferFontData:originData srcSize:32 dstSize:48];
                }
                    break;
                default:
                    break;
            }
        }
            break;
        default:
            break;
    }
    return originData;
}

+(NSData *)getOriginDataWordShowHeight:(NSInteger)wordShowHeight  font:(NSInteger)font emojiData:(NSData *)emojiData degree:(int)degree{
    NSData *originData;
    
    switch (wordShowHeight) {
        case 12:
        {
            switch (font) {
                case 12:
                {
                    originData = emojiData;
                }
                    break;
                default:
                    break;
            }
        }
            break;
        case 16:
        {
            switch (font) {
                case 12:
                {
                    emojiData =[HLUtils rotateArrayData:emojiData font:font degree:degree];
                    originData =  [HLUtils iArrayRightShift:emojiData originColBytes:2 space:2 targetRow:16];
                }
                    break;
                case 14:
                {
                    emojiData =[HLUtils rotateArrayData:emojiData font:font degree:degree];
                    originData =  [HLUtils iArrayRightShift:emojiData originColBytes:2 space:1 targetRow:16];
                }
                    break;
                case 16:
                {
                    emojiData =[HLUtils rotateArrayData:emojiData font:font degree:degree];
                    originData = emojiData;
                }
                    break;
                default:
                    break;
            }
            
        }
            break;
        case 20:
        {
            switch (font) {
                case 12:
                {
                    originData =  [HLUtils iArrayRightShift:emojiData originColBytes:2 space:4 targetRow:20];
                }
                    break;
                case 14:
                {
                    originData =  [HLUtils iArrayRightShift:emojiData originColBytes:2 space:3 targetRow:20];
                    
                }
                    break;
                case 16:
                {
                    originData =  [HLUtils iArrayRightShift:emojiData originColBytes:2 space:2 targetRow:20];
                }
                    break;
                case 20:
                {
                    originData = emojiData;
                }
                    break;
                default:
                    break;
            }
        }
            break;
        case 24:
        {
            switch (font) {
                case 12:
                {
                    originData =  [HLUtils iArrayRightShift:emojiData originColBytes:2 space:6 targetRow:24];
                }
                    break;
                case 14:
                {
                    originData =  [HLUtils iArrayRightShift:emojiData originColBytes:2 space:5 targetRow:24];
                    
                }
                    break;
                case 16:
                {
                    originData =  [HLUtils iArrayRightShift:emojiData originColBytes:2 space:4 targetRow:24];
                }
                    break;
                case 20:
                {
                    originData =  [HLUtils iArrayRightShift:emojiData originColBytes:3 space:2 targetRow:24];
                }
                    break;
                case 24:
                {
                    originData = emojiData;
                }
                    break;
                default:
                    break;
            }
        }
            break;
        case 32:
        {
            switch (font) {
                case 12:
                {
                    emojiData =[HLUtils rotateArrayData:emojiData font:font degree:degree];
                    originData =  [HLUtils iArrayRightShift:emojiData originColBytes:2 space:10 targetRow:32];
                }
                    break;
                case 14:
                {
                    emojiData =[HLUtils rotateArrayData:emojiData font:font degree:degree];
                    originData =  [HLUtils iArrayRightShift:emojiData originColBytes:2 space:9 targetRow:32];
    
                }
                    break;
                case 16:
                {
                    emojiData =[HLUtils rotateArrayData:emojiData font:font degree:degree];
                    originData =  [HLUtils iArrayRightShift:emojiData originColBytes:2 space:8 targetRow:32];
                }
                    break;
                case 20:
                {
                    emojiData =[HLUtils rotateArrayData:emojiData font:font degree:degree];
                    originData =  [HLUtils iArrayRightShift:emojiData originColBytes:3 space:6 targetRow:32];
                }
                    break;
                case 24:
                {
                    emojiData =[HLUtils rotateArrayData:emojiData font:font degree:degree];
                    originData =  [HLUtils iArrayRightShift:emojiData originColBytes:3 space:4 targetRow:32];
                }
                    break;
                case 32:
                {
                    emojiData =[HLUtils rotateArrayData:emojiData font:font degree:degree];
                    originData = emojiData;
                }
                    break;
                default:
                    break;
            }
        }
            break;
        case 48:
        {
            switch (font) {
                case 12:
                {
                    emojiData =[HLUtils rotateArrayData:emojiData font:font degree:degree];
                    originData = [HLUtils transferFontData:emojiData srcSize:12 dstSize:48];
                }
                    break;
                case 14:
                {
                    emojiData =[HLUtils rotateArrayData:emojiData font:font degree:degree];
                    originData = [HLUtils transferFontData:emojiData srcSize:14 dstSize:48];
    
                }
                    break;
                case 16:
                {
                    emojiData =[HLUtils rotateArrayData:emojiData font:font degree:degree];
                    originData = [HLUtils transferFontData:emojiData srcSize:16 dstSize:48];
                }
                    break;
                case 20:
                {
                    emojiData =[HLUtils rotateArrayData:emojiData font:font degree:degree];
                    originData = [HLUtils transferFontData:emojiData srcSize:20 dstSize:48];
                }
                    break;
                case 24:
                {
                    emojiData =[HLUtils rotateArrayData:emojiData font:font degree:degree];
                    originData = [HLUtils transferFontData:emojiData srcSize:24 dstSize:48];
                }
                    break;
                case 32:
                {
                    emojiData =[HLUtils rotateArrayData:emojiData font:font degree:degree];
                    originData = [HLUtils transferFontData:emojiData srcSize:32 dstSize:48];
                }
                    break;
                case 48:
                {
                    emojiData =[HLUtils rotateArrayData:emojiData font:font degree:degree];
                    originData = emojiData;
                }
                    break;
                default:
                    break;
            }
        }
            break;
        default:
            break;
    }
    return originData;
}

+(NSArray *)getEmojiArrTransformShowHeight:(NSInteger)wordShowHeight  font:(NSInteger)font emojiArr:(NSArray *)emojiArr degree:(int)degree{
    NSArray *originArr;
    
    switch (wordShowHeight) {
        case 16:
        {
            switch (font) {
                case 12:
                {
                    emojiArr = [HLUtils rotateArray:emojiArr degree:degree];
                    originArr =  [HLUtils iArrayRightShift:emojiArr space:2];
                }
                    break;
                case 14:
                {
                    emojiArr = [HLUtils rotateArray:emojiArr degree:degree];
                    originArr =  [HLUtils iArrayRightShift:emojiArr space:1];
                }
                    break;
                case 16:
                {
                    emojiArr = [HLUtils rotateArray:emojiArr degree:degree];
                    originArr = emojiArr;
                }
                    break;
                default:
                    break;
            }
            
        }
            break;
        default:
            break;
    }
    return originArr;
}


+(FLAnimatedImage *)getGIFWithName:(NSString *)gifName{
    //读取gif名称，从沙盒中加载gif图片
    NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
    NSURL *fileURL = [documentsDirectoryURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.gif",gifName]];
    
    NSData *gifData = [NSData dataWithContentsOfURL:fileURL];
    
    FLAnimatedImage *image =  [FLAnimatedImage animatedImageWithGIFData:gifData];
    
    return image;
}



@end
