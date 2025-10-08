//
//  NSString+QCExtension.m
//  JotusStripEnd
//
//  Created by 陈立华 on 16/10/8.
//  Copyright © 2016年 陈立华. All rights reserved.
//

#import "NSString+QCExtension.h"

@implementation NSString (QCExtension)

+ (NSString*)convertStringToRed:(CGFloat)red Green:(CGFloat)green Blue:(CGFloat)blue{
    
    NSLog(@"red%d green %d blue %d",(int)(red * 255),(int)(green * 255),(int)(blue * 255));
    NSString *hex = [NSString stringWithFormat:@"%@%@%@",[self ToHex:(int)(red * 255)],[self ToHex:(int)(green * 255)],[self ToHex:(int)(blue * 255)]];
    return hex;
}
//十进制转十六进制
+ (NSString *)ToHex:(int)tmpid
{
    NSMutableString *endtmp=[NSMutableString string];
    NSString *nLetterValue;
    NSString *nStrat;
    int ttmpig=tmpid%16;
    int tmp=tmpid/16;
    switch (ttmpig)
    {
        case 10:
            nLetterValue =@"A";break;
        case 11:
            nLetterValue =@"B";break;
        case 12:
            nLetterValue =@"C";break;
        case 13:
            nLetterValue =@"D";break;
        case 14:
            nLetterValue =@"E";break;
        case 15:
            nLetterValue =@"F";break;
        default:nLetterValue=[[NSString alloc]initWithFormat:@"%i",ttmpig];
            
    }
    switch (tmp)
    {
        case 10:
            nStrat =@"A";break;
        case 11:
            nStrat =@"B";break;
        case 12:
            nStrat =@"C";break;
        case 13:
            nStrat =@"D";break;
        case 14:
            nStrat =@"E";break;
        case 15:
            nStrat =@"F";break;
        default:nStrat=[[NSString alloc]initWithFormat:@"%i",tmp];
            
    }
    [endtmp appendString:nStrat];
    [endtmp appendString:nLetterValue];
    return endtmp;
}

+ (NSInteger)numberWithHexString:(NSString *)hexString
{
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    unsigned long long longlongValue;
    [scanner scanHexLongLong:&longlongValue];
    NSInteger value = (NSInteger)longlongValue;
    return value;
}

+ (NSString *)checkedStringWithLatticeArray:(NSArray *)finalArray
{
    NSString *checkedString = @"";
    for (int i = 0; i < finalArray.count; i++) {
        // rows 中是涂鸦每一列的数据
        NSArray *rows = finalArray[i];
        
        int n = ceil(rows.count / 8.0);
        for (int j = 0; j < n; j++) {
            int sum = 0;
            for (int k = j * 8; k < (j+1) * 8 && k < rows.count; k++) {
                NSNumber *number = rows[k];
                sum += [number intValue] * (int)pow(2, (j+1) * 8 - 1 -k);
            }
            
            checkedString = [checkedString stringByAppendingFormat:@"%02x", sum];
        }
    }
    
    return checkedString;
}

+ (NSString *)checkedStringWithLatticeArrayRGB:(NSArray *)finalArray index:(int)index
{
    NSString *checkedString = @"";
    for (int i = 0; i < finalArray.count; i++) {
        // rows 中是涂鸦每一列的数据
        NSArray *rows = finalArray[i];
        
        int n = ceil(rows.count / 8.0);
        for (int j = 0; j < n; j++) {
            int sum = 0;
            for (int k = j * 8; k < (j+1) * 8 && k < rows.count; k++) {
                NSArray *rgb = rows[k];
                NSNumber *number = rgb[index];
                sum += [number intValue] * (int)pow(2, (j+1) * 8 - 1 -k);
            }
            
            checkedString = [checkedString stringByAppendingFormat:@"%02x", sum];
        }
    }
    
    return checkedString;
}

+ (NSString *)checkedStringWithData:(NSData *)data
{
    NSString *checkedString = @"";
    Byte *keyBytes = (Byte *)[data bytes];
    int dataLength = (int)data.length;
    
    int copyLength = -1;
    // 1. 从数组最后向前遍历，直到该列不是空列
    for (int i = dataLength - 1; i > 0; i -= 2) {
        if (keyBytes[i] != 0 || keyBytes[i-1] != 0) {
            copyLength = i + 1;
            break;
        }
    }
    
    // 2.所有数据不全为0，则添加一个空列做为间隔
    if (copyLength > 0) {
        for (int j = 0; j < copyLength; j++) {
            NSString *hexStr = [NSString stringWithFormat:@"%02x",keyBytes[j]];
            checkedString = [checkedString stringByAppendingString:hexStr];
        }
        checkedString = [checkedString stringByAppendingString:@"0000"];
        return checkedString;
    }
    
    // 3.如果全部为0，则可能全部为空列，则显示6列空白即可
    if (copyLength < 0) {
        for (int j = 0; j < dataLength * 0.5; j++) {
            NSString *hexStr = [NSString stringWithFormat:@"%02x",0];
            checkedString = [checkedString stringByAppendingString:hexStr];
        }
    }

    return checkedString;
}

+ (NSString *)packageStringWith:(NSString *)dataString
                    totalLength:(int)totalLength
                  currentLength:(int)currentLength
                      packageId:(int)packageId
{
    // 默认类型
    NSString *package = @"00";
    // 拼接数据总长度
    package = [package stringByAppendingFormat:@"%04x",totalLength];
    // 拼接包ID
    package = [package stringByAppendingFormat:@"%04x",packageId];
    // 拼接当前数据包长度
    package = [package stringByAppendingFormat:@"%02x",currentLength];
    // 拼接当前包数据
    package = [package stringByAppendingString:dataString];
    // 拼接获取校验码
    NSString *verifyString = [NSString verifyStringWith:package];
    // 拼接校验码
    package = [package stringByAppendingString:verifyString];
    
    return package;
}

+ (NSString *)packageStringWith:(NSString *)dataString
                    totalLength:(int)totalLength
                  currentLength:(int)currentLength
                      packageId:(int)packageId fontsType:(int)fontsType
{
    // 默认类型
    NSString *package = @"00";
    // 拼接数据总长度
    package = [package stringByAppendingFormat:@"%08x",totalLength];
    // 拼接包ID
    package = [package stringByAppendingFormat:@"%04x",packageId];
    // 拼接当前数据包长度
    package = [package stringByAppendingFormat:@"%04x",currentLength];
    // 拼接当前包数据
    package = [package stringByAppendingString:dataString];
    // 拼接获取校验码
    NSString *verifyString = [NSString verifyStringWith:package];
    // 拼接校验码
    package = [package stringByAppendingString:verifyString];
    
    return package;
}

+ (NSArray *)getPackageCommandsWithDataString:(NSString *)dataString type:(int)type
{
    NSInteger totalLength = [dataString length] * 0.5;
    
    NSInteger n = (totalLength / 128);
    NSInteger mol = totalLength % 128;
    
    if (n == 0 && mol == 0) {
        // 如果总数据为0
        return nil;
    }
    
    if (n == 0) {
        NSString *packageString = [NSString packageStringWith:dataString
                                                  totalLength:(int)totalLength
                                                currentLength:(int)mol
                                                    packageId:0];
        NSString *eachSendData = [NSString stringWithFormat:@"%02x", type];
        eachSendData = [eachSendData stringByAppendingString:packageString];
        
        int length = (int)(eachSendData.length/2 + 1);
        
        NSString *hexString = [NSString stringWithFormat:@"%04x",length];
        hexString = [hexString stringByAppendingString:eachSendData];
        NSString *sendString = [NSString finalDataWith:hexString];
        NSArray *packageCommads = @[sendString];
        return packageCommads;
    }
    
    NSMutableArray *packageCommands = [NSMutableArray array];
    for (int i = 0; i < n; i ++) {
        NSRange range = NSMakeRange(i * 128 * 2, 128 * 2);
        NSString *subString = [dataString substringWithRange:range];
        NSString *packageString = [NSString packageStringWith:subString
                                                  totalLength:(int)totalLength
                                                currentLength:128
                                                    packageId:i];
        NSString *eachSendData = [NSString stringWithFormat:@"%02x", type];
        eachSendData = [eachSendData stringByAppendingString:packageString];
        
        int length = (int)(eachSendData.length/2 + 1);
        
        NSString *hexString = [NSString stringWithFormat:@"%04x",length];
        hexString = [hexString stringByAppendingString:eachSendData];
        NSString *sendString = [NSString finalDataWith:hexString];
        [packageCommands addObject:sendString];
    }
    
    if (mol != 0) {
        NSRange range = NSMakeRange(n * 128 * 2, mol * 2);
        NSString *subString = [dataString substringWithRange:range];
        NSString *packageString = [NSString packageStringWith:subString
                                                  totalLength:(int)totalLength
                                                currentLength:(int)mol
                                                    packageId:(int)n];
        NSString *eachSendData = [NSString stringWithFormat:@"%02x", type];
        eachSendData = [eachSendData stringByAppendingString:packageString];
        
        int totalLength = (int)(eachSendData.length/2 + 1);
        
        NSString *hexString = [NSString stringWithFormat:@"%04x",totalLength];
        hexString = [hexString stringByAppendingString:eachSendData];
        NSString *sendString = [NSString finalDataWith:hexString];
        [packageCommands addObject:sendString];
    }
    return packageCommands;
}

//针对32设备数据总长度4个字节
+ (NSArray *)getPackageCommandsWithDataString:(NSString *)dataString type:(int)type fontsType:(int)fontsType
{
    NSInteger totalLength = [dataString length] * 0.5;
    
    NSInteger n = (totalLength / 1024);
    NSInteger mol = totalLength % 1024;
    
    if (n == 0 && mol == 0) {
        // 如果总数据为0
        return nil;
    }
    
    if (n == 0) {
        NSString *packageString = [NSString packageStringWith:dataString
                                                  totalLength:(int)totalLength
                                                currentLength:(int)mol
                                                    packageId:0 fontsType:32];
        NSString *eachSendData = [NSString stringWithFormat:@"%02x", type];
        eachSendData = [eachSendData stringByAppendingString:packageString];
        
        int length = (int)(eachSendData.length/2);
        
        NSString *hexString = [NSString stringWithFormat:@"%04x%@",length,eachSendData];
        NSString *sendString = [NSString finalDataWith:hexString];
        NSArray *packageCommads = @[sendString];
        return packageCommads;
    }
    
    NSMutableArray *packageCommands = [NSMutableArray array];
    for (int i = 0; i < n; i ++) {
        NSRange range = NSMakeRange(i * 1024 * 2, 1024 * 2);
        NSString *subString = [dataString substringWithRange:range];
        NSString *packageString = [NSString packageStringWith:subString
                                                  totalLength:(int)totalLength
                                                currentLength:1024
                                                    packageId:i fontsType:32];
        NSString *eachSendData = [NSString stringWithFormat:@"%02x", type];
        eachSendData = [eachSendData stringByAppendingString:packageString];
        
        int length = (int)(eachSendData.length/2 );
        
        NSString *hexString = [NSString stringWithFormat:@"%04x",length];
        hexString = [hexString stringByAppendingString:eachSendData];
        NSString *sendString = [NSString finalDataWith:hexString];
        [packageCommands addObject:sendString];
    }
    
    if (mol != 0) {
        NSRange range = NSMakeRange(n * 1024 * 2, mol * 2);
        NSString *subString = [dataString substringWithRange:range];
        NSString *packageString = [NSString packageStringWith:subString
                                                  totalLength:(int)totalLength
                                                currentLength:(int)mol
                                                    packageId:(int)n fontsType:32];
        NSString *eachSendData = [NSString stringWithFormat:@"%02x", type];
        eachSendData = [eachSendData stringByAppendingString:packageString];
        
        int totalLength = (int)(eachSendData.length/2);
        
        NSString *hexString = [NSString stringWithFormat:@"%04x",totalLength];
        hexString = [hexString stringByAppendingString:eachSendData];
        NSString *sendString = [NSString finalDataWith:hexString];
        [packageCommands addObject:sendString];
    }
    return packageCommands;
}

+ (NSString *)verifyStringWith:(NSString *)dataString
{
    if (dataString.length == 0) {
        return @"00";
    }
    
    int xorResult;
    NSString *ch = nil;
    NSString *condition = dataString;
    if (condition.length <= 2) {
        ch = [condition substringToIndex:condition.length];
        xorResult = (int)[NSString numberWithHexString:ch];
        xorResult ^= 0x00;
        NSString *result = [NSString stringWithFormat:@"%02x", xorResult];
        return result;
    }
    
    ch = [condition substringToIndex:2];
    condition = [condition substringFromIndex:2];
    xorResult = (int)[NSString numberWithHexString:ch];
    xorResult ^= 0x00;
    
    while (condition.length > 2) {
        ch = [condition substringToIndex:2];
        condition = [condition substringFromIndex:2];
        
        int orgin = (int)[NSString numberWithHexString:ch];
        xorResult ^= orgin;
    }
    ch = condition;
    int origin = (int)[NSString numberWithHexString:ch];
    xorResult ^= origin;
    
    NSString *result = [NSString stringWithFormat:@"%02x", xorResult];
    return result;
}

// 将数据强制转换，没有拼接01 和03
+ (NSString *)translationWith:(NSString *)dataString
{
    if (dataString.length == 0) {
        return nil;
    }
    
    NSString *result = @"";
    NSString *ch = nil;
    NSString *condition = dataString;
    while (condition.length > 2) {
        ch = [condition substringToIndex:2];
        condition = [condition substringFromIndex:2];
        result = [result stringByAppendingString:[self getData:ch]];
    }
    ch = condition;
    result = [result stringByAppendingString:[self getData:ch]];
    
    return result;
}

// 将数据强制转换,已拼接01 和03
+ (NSString *)finalDataWith:(NSString *)dataString
{
    if (dataString.length == 0) {
        return nil;
    }
    
    NSMutableString *result = [NSMutableString string];
    NSString *ch = nil;
    NSString *condition = dataString;
    while (condition.length > 2) {
        ch = [condition substringToIndex:2];
        condition = [condition substringFromIndex:2];
        [result appendString:[self getData:ch]];
    }
    ch = condition;
    [result appendString:[self getData:ch]];
    
    NSString *finalString = [@"01" stringByAppendingString:result];
    finalString = [finalString stringByAppendingString:@"03"];
    
    return finalString;
}

// 将强制转换后的数据反解析
+ (NSArray *)decodeResultWith:(NSString *)dataString
{
    if (![dataString hasPrefix:@"01"] || ![dataString hasSuffix:@"03"]) {
        // 数据格式不对
        return nil;
    }
    
    // 先去掉 01
    NSString *originString = [dataString substringFromIndex:2];
    // 再去掉03
    originString = [originString substringToIndex:originString.length - 2];
    
    NSString *temp = nil;
    NSString *condition = originString;
    NSMutableArray *array = [NSMutableArray array];
    BOOL isXOR = NO;
    for (int i = 0; i < condition.length; i += 2) {
        temp = [condition substringWithRange:NSMakeRange(i, 2)];
        if ([temp isEqualToString:@"02"] && !isXOR) {
            isXOR = YES;
            continue;
        }
        NSInteger intValue = [self numberWithHexString:temp];
        if (isXOR) {
            intValue ^= 0x04;
            NSNumber *number = [NSNumber numberWithInteger:intValue];
            [array addObject:number];
        } else {
            NSNumber *number = [NSNumber numberWithInteger:intValue];
            [array addObject:number];
        }
        isXOR = NO;
    }
    if(array.count <= 2) return [[NSArray alloc] init];
    NSArray *result = [array subarrayWithRange:NSMakeRange(2, array.count - 2)];
    return result;
}

// 判断字符串是否包含中文
+ (BOOL)hasChinese:(NSString *)originString
{
    for (int i=0; i<originString.length; i++) {
        unichar ch = [originString characterAtIndex:i];
        if (0x4E00 <= ch  && ch <= 0x9FA5) {
            return YES;
        }
    }
    return NO;
}

+ (BOOL)isNumber:(NSString *)originString
{
    originString = [originString stringByTrimmingCharactersInSet:[NSCharacterSet decimalDigitCharacterSet]];
    if(originString.length > 0) {
        return NO;
    }
    return YES;
}

+ (NSString *)getData:(NSString *)ch
{
    NSMutableString *outString = [NSMutableString string];
    int origin = (int)[NSString numberWithHexString:ch];
    if (origin > 0x00 && origin < 0x04) {
        [outString appendString:@"02"];
        origin ^= 0x04;
    }
    [outString appendString:[NSString ToHex:origin]];
    
    return outString;
}

//+ (NSInteger)numberWithHexString:(NSString *)hexString
//{
//    const char *hexChar = [hexString cStringUsingEncoding:NSUTF8StringEncoding];
//    
//    int hexNumber;
//    
//    sscanf(hexChar, "%x", &hexNumber);
//    
//    return (NSInteger)hexNumber;
//}

- (NSArray *)rgbArray
{
    if ([self isEqualToString:@"FF0000"]) {
        return @[@(1),@(0),@(0)];
    } else if ([self isEqualToString:@"FF00FF"]) {
        return @[@(1),@(0),@(1)];
    } else if ([self isEqualToString:@"FFFF00"]) {
        return @[@(1),@(1),@(0)];
    } else if ([self isEqualToString:@"00FF00"]) {
        return @[@(0),@(1),@(0)];
    } else if ([self isEqualToString:@"00FFFF"]) {
        return @[@(0),@(1),@(1)];
    } else if ([self isEqualToString:@"0000FF"]) {
        return @[@(0),@(0),@(1)];
    } else if ([self isEqualToString:@"FFFFFF"]) {
        return @[@(1),@(1),@(1)];
    } else if ([self isEqualToString:@"000000"]) {
        return @[@(0),@(0),@(0)];
    } else {
        return @[@(0),@(0),@(0)];
    }
}

- (NSMutableAttributedString *)attributeStringWithRgbsArray:(NSArray *)rgbsArray
{
    if (self.length == 0) {
        return nil;
    }
    
    NSMutableAttributedString *attributeString = [[NSMutableAttributedString alloc] initWithString:self];
    for (int i = 0; i < self.length; i++) {
        UIColor *color = [UIColor blackColor];
        if (i < rgbsArray.count) {
            NSArray *rgbArray = rgbsArray[i];
            float red = [rgbArray[0] floatValue];
            float green = [rgbArray[1] floatValue];
            float blue = [rgbArray[2] floatValue];
            color = [UIColor colorWithRed:red green:green blue:blue alpha:1];
        }
        
        NSDictionary *attributes = @{
                                     NSForegroundColorAttributeName : color,
                                     NSFontAttributeName : [UIFont systemFontOfSize:20.f]
                                     };
        [attributeString setAttributes:attributes range:NSMakeRange(i, 1)];
    }
    return attributeString;
}

@end
