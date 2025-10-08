//
//  HLUtils.m
//  CoolLED1248
//
//  Created by Harvey on 2022/4/3.
//  Copyright © 2022 Haley. All rights reserved.
//

#import "HLUtils.h"
#import "JTCommon.h"
#import "UIDevice+FATExtension.h"
#import "HLTextAttachment.h"
#import "Const_Header.h"
#import "ThemManager.h"
#import "DNApplication.h"


@implementation HLUtils

+ (NSString *)documentPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath = [paths objectAtIndex:0];
    
    return documentPath;
}

+ (UIViewController *)topVC
{
    //获取根控制器
    UIViewController *rootVC = [[UIApplication sharedApplication].delegate window].rootViewController;
    
    UIViewController *parent = rootVC;
    //遍历 如果是presentViewController
    while ((parent = rootVC.presentedViewController) != nil ) {
        rootVC = parent;
    }
    
    if ([rootVC isKindOfClass:[UITabBarController class]]) {
        rootVC = [(UITabBarController *)rootVC selectedViewController];
    }
    
    while ([rootVC isKindOfClass:[UINavigationController class]]) {
        rootVC = [(UINavigationController *)rootVC topViewController];
    }
    return rootVC;
}

+ (void)sendEmailToUs
{
    NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *systemVersion = [UIDevice currentDevice].systemVersion;
    NSString *modeName = [UIDevice currentDevice].deviceMode;
    NSString *deviceName = [[NSUserDefaults standardUserDefaults] objectForKey:kLastConnectedDeviceName]?:@"";
    NSString *subject = [appName stringByAppendingFormat:@"_%@_%@_iOS_%@_%@", appVersion, deviceName, systemVersion, modeName];
    
    // 方式1：
    NSMutableString *mailUrl = [[NSMutableString alloc] init];
    [mailUrl appendFormat:@"mailto:%@", kEmail];
    [mailUrl appendFormat:@"?cc=%@", kRecipientEmail];
    [mailUrl appendFormat:@"&subject=%@", subject];
    NSString *emailPath = [mailUrl stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:emailPath]];
}

+ (BOOL)isLiuHaiScreen
{
    BOOL result = NO;
    if (UIDevice.currentDevice.userInterfaceIdiom != UIUserInterfaceIdiomPhone) {
        return result;
    }
    
    if ((kDeviceHeight == 812.0
         || kDeviceHeight == 896.0
         || kDeviceHeight == 926.0
         || kDeviceHeight == 844.0
         || kDeviceHeight == 780.0)) {
        return YES;
    }
    
    return NO;
}

+ (UIEdgeInsets)safeEdgeInset
{
    if (@available(iOS 11.0, *)) {
        UIWindow *mainWindow = [[[UIApplication sharedApplication] delegate] window];
        return mainWindow.safeAreaInsets;
    }
    
    return UIEdgeInsetsMake(20, 0, 0, 0);
}

+ (CGFloat)navigateHeight
{
    //    return 44 + [HLUtils safeEdgeInset].top;
    return 44 + [HLUtils statusHeight];
}

+ (CGFloat)statusHeight
{
    CGFloat statusBarHeight = 0;
    if (@available(iOS 13.0, *)) {
        statusBarHeight = [UIApplication sharedApplication].windows.firstObject.windowScene.statusBarManager.statusBarFrame.size.height;
    } else {
        statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    }
    return statusBarHeight;
}

// 涂鸦页面(横屏页面)的导航栏高度
+ (CGFloat)graffNavigateHeight
{
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        return 44 + [HLUtils safeEdgeInset].top;
    }
    
    CGFloat height = 34;
    if ([HLUtils isLiuHaiScreen]) {
        height = 34;
        return height;
    }
    
    if (kIsPlus) {
        height = 44;
        return height;
    }
    
    return height;
}

/// 将文字的二进制数据转换位点阵数据
+ (NSArray *)arrayWithOriginData:(NSData *)originData
{
    if (originData.length == 0) {
        return nil;
    }
    
    Byte *keyBytes = (Byte *)[originData bytes];
    int dataLength = (int)originData.length;
    
    NSMutableArray *originArray = [NSMutableArray array];
    for (int i = 0; i < dataLength; i++) {
        [originArray addObject:@(keyBytes[i])];
    }
    
    NSArray *showArray = [self showArrayWithData:originArray];
    
    return showArray;
}

// 32屏幕将文字的二进制数据转换位点阵数据
+ (NSArray *)arrayWithOriginData:(NSData *)originData wordShowHeight:(NSInteger)wordShowHeight
{
    if (originData.length == 0) {
        return nil;
    }
    
    Byte *keyBytes = (Byte *)[originData bytes];
    int dataLength = (int)originData.length;
    
    NSMutableArray *originArray = [NSMutableArray array];
    for (int i = 0; i < dataLength; i++) {
        [originArray addObject:@(keyBytes[i])];
    }
    
    NSArray *showArray = [self showArrayWithData:originArray wordShowHeight:wordShowHeight];
    
    return showArray;
}

/// 文字的二进制数据转换为点阵数据，旋转后，再次转换二进制数据
+ (NSData *)dataWithOriginData:(NSData *)originData degree:(int)degree
{
    if (degree == 0 || degree == 360) {
        return originData;
    }
    
    Byte *keyBytes = (Byte *)[originData bytes];
    int dataLength = (int)originData.length;
    
    NSMutableArray *originArray = [NSMutableArray array];
    for (int i = 0; i < dataLength; i++) {
        [originArray addObject:@(keyBytes[i])];
    }
    
    NSArray *showArray = [self showArrayWithData:originArray];
    NSArray *finalArray = [self rotateArray:showArray degree:degree];
    
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
            
            keyBytes[2*i + j] = sum;
        }
    }
    NSData *result = [NSData dataWithBytes:keyBytes length:dataLength];
    
    return result;
}

+ (NSData *)dataWithLatticeArray:(NSArray *)latticeArray
{
    NSInteger dataLength = latticeArray.count * 2;
    Byte keyBytes[dataLength];
    for (int i = 0; i < latticeArray.count; i++) {
        // rows 中是涂鸦每一列的数据
        NSArray *rows = latticeArray[i];
        
        int n = ceil(rows.count / 8.0);
        for (int j = 0; j < n; j++) {
            int sum = 0;
            for (int k = j * 8; k < (j+1) * 8 && k < rows.count; k++) {
                NSNumber *number = rows[k];
                sum += [number intValue] * (int)pow(2, (j+1) * 8 - 1 -k);
            }
            
            dataLength++;
            keyBytes[2*i + j] = sum;
        }
    }
    NSData *result = [NSData dataWithBytes:keyBytes length:dataLength];
    
    return result;
}

/// 将图案的数据数组转换为点阵图，旋转后，再次转换为数据数组
+ (NSArray *)arrayWithOriginArray:(NSArray *)originArray degree:(int)degree
{
    if (degree == 0 || degree == 360) {
        return originArray;
    }
    
    NSArray *showArray = [self showArrayWithData:originArray];
    NSArray *finalArray = [self rotateArray:showArray degree:degree];
    
    NSMutableArray *resultM = [NSMutableArray arrayWithArray:originArray];
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
            
            resultM[2*i + j] = @(sum);
        }
    }
    
    return resultM;
}

+ (NSArray *)showArrayWithData:(NSArray *)showData font:(NSInteger)font
{
    NSMutableArray *showArray = [NSMutableArray array];
    switch (font) {
        case 12:
        {
            NSInteger count = showData.count / 2;
            for (int i = 0; i < count; i++) {
                NSNumber *firstNumber = showData[2 * i];
                NSNumber *secondNumber = showData[2 * i + 1];
                NSString *originString = @"00000000";
                NSString *firstResult = [self turn10to2:[firstNumber intValue]];
                NSRange firstRange = NSMakeRange(originString.length - firstResult.length, firstResult.length);
                firstResult =  [originString stringByReplacingCharactersInRange:firstRange withString:firstResult];
                
                NSString *secondResult = [self turn10to2:[secondNumber intValue]];
                NSRange secondRange = NSMakeRange(originString.length - secondResult.length, secondResult.length);
                secondResult = [originString stringByReplacingCharactersInRange:secondRange withString:secondResult];
                
                NSString *result = [firstResult stringByAppendingString:secondResult];
                result = [result substringToIndex:12];
                
                NSMutableArray *eachColArray = [NSMutableArray array];
                for (int i = 0; i < result.length; i++) {
                    NSString *eachString = [result substringWithRange:NSMakeRange(i, 1)];
                    NSNumber *number = @([eachString intValue]);
                    [eachColArray addObject:number];
                }
                [showArray addObject:eachColArray];
            }
        }
            break;
        case 14:
        {
            NSInteger count = showData.count / 2;
            for (int i = 0; i < count; i++) {
                NSNumber *firstNumber = showData[2 * i];
                NSNumber *secondNumber = showData[2 * i + 1];
                NSString *originString = @"00000000";
                NSString *firstResult = [self turn10to2:[firstNumber intValue]];
                NSRange firstRange = NSMakeRange(originString.length - firstResult.length, firstResult.length);
                firstResult =  [originString stringByReplacingCharactersInRange:firstRange withString:firstResult];
                
                NSString *secondResult = [self turn10to2:[secondNumber intValue]];
                NSRange secondRange = NSMakeRange(originString.length - secondResult.length, secondResult.length);
                secondResult = [originString stringByReplacingCharactersInRange:secondRange withString:secondResult];
                
                NSString *result = [firstResult stringByAppendingString:secondResult];
                result = [result substringToIndex:14];
                
                NSMutableArray *eachColArray = [NSMutableArray array];
                for (int i = 0; i < result.length; i++) {
                    NSString *eachString = [result substringWithRange:NSMakeRange(i, 1)];
                    NSNumber *number = @([eachString intValue]);
                    [eachColArray addObject:number];
                }
                [showArray addObject:eachColArray];
            }
        }
            break;
        case 16:
        {
            NSInteger count = showData.count / 2;
            for (int i = 0; i < count; i++) {
                NSNumber *firstNumber = showData[2 * i];
                NSNumber *secondNumber = showData[2 * i + 1];
                NSString *originString = @"00000000";
                NSString *firstResult = [self turn10to2:[firstNumber intValue]];
                NSRange firstRange = NSMakeRange(originString.length - firstResult.length, firstResult.length);
                firstResult =  [originString stringByReplacingCharactersInRange:firstRange withString:firstResult];
                
                NSString *secondResult = [self turn10to2:[secondNumber intValue]];
                NSRange secondRange = NSMakeRange(originString.length - secondResult.length, secondResult.length);
                secondResult = [originString stringByReplacingCharactersInRange:secondRange withString:secondResult];
                
                NSString *result = [firstResult stringByAppendingString:secondResult];
                result = [result substringToIndex:16];
                
                NSMutableArray *eachColArray = [NSMutableArray array];
                for (int i = 0; i < result.length; i++) {
                    NSString *eachString = [result substringWithRange:NSMakeRange(i, 1)];
                    NSNumber *number = @([eachString intValue]);
                    [eachColArray addObject:number];
                }
                [showArray addObject:eachColArray];
            }
        }
            break;
        case 20:
        {
            NSInteger count = showData.count / 3;
            for (int i = 0; i < count; i++) {
                NSNumber *firstNumber = showData[3 * i];
                NSNumber *secondNumber = showData[3 * i + 1];
                NSNumber *thirdNumber = showData[3 * i + 2];
                NSString *originString = @"00000000";
                NSString *firstResult = [self turn10to2:[firstNumber intValue]];
                NSRange firstRange = NSMakeRange(originString.length - firstResult.length, firstResult.length);
                firstResult =  [originString stringByReplacingCharactersInRange:firstRange withString:firstResult];
                
                NSString *secondResult = [self turn10to2:[secondNumber intValue]];
                NSRange secondRange = NSMakeRange(originString.length - secondResult.length, secondResult.length);
                secondResult = [originString stringByReplacingCharactersInRange:secondRange withString:secondResult];
                
                NSString *thirdResult = [self turn10to2:[thirdNumber intValue]];
                NSRange thirdRange = NSMakeRange(originString.length - thirdResult.length, thirdResult.length);
                thirdResult = [originString stringByReplacingCharactersInRange:thirdRange withString:thirdResult];
                
                NSString *result = [firstResult stringByAppendingString:secondResult];
                result = [result stringByAppendingString:thirdResult];
                result = [result substringToIndex:20];
                
                NSMutableArray *eachColArray = [NSMutableArray array];
                for (int i = 0; i < result.length; i++) {
                    NSString *eachString = [result substringWithRange:NSMakeRange(i, 1)];
                    NSNumber *number = @([eachString intValue]);
                    [eachColArray addObject:number];
                }
                [showArray addObject:eachColArray];
            }
        }
            break;
        case 24:
        {
            NSInteger count = showData.count / 3;
            for (int i = 0; i < count; i++) {
                NSNumber *firstNumber = showData[3 * i];
                NSNumber *secondNumber = showData[3 * i + 1];
                NSNumber *thirdNumber = showData[3 * i + 2];
                NSString *originString = @"00000000";
                NSString *firstResult = [self turn10to2:[firstNumber intValue]];
                NSRange firstRange = NSMakeRange(originString.length - firstResult.length, firstResult.length);
                firstResult =  [originString stringByReplacingCharactersInRange:firstRange withString:firstResult];
                
                NSString *secondResult = [self turn10to2:[secondNumber intValue]];
                NSRange secondRange = NSMakeRange(originString.length - secondResult.length, secondResult.length);
                secondResult = [originString stringByReplacingCharactersInRange:secondRange withString:secondResult];
                
                NSString *thirdResult = [self turn10to2:[thirdNumber intValue]];
                NSRange thirdRange = NSMakeRange(originString.length - thirdResult.length, thirdResult.length);
                thirdResult = [originString stringByReplacingCharactersInRange:thirdRange withString:thirdResult];
                
                NSString *result = [firstResult stringByAppendingString:secondResult];
                result = [result stringByAppendingString:thirdResult];
                result = [result substringToIndex:24];
                
                NSMutableArray *eachColArray = [NSMutableArray array];
                for (int i = 0; i < result.length; i++) {
                    NSString *eachString = [result substringWithRange:NSMakeRange(i, 1)];
                    NSNumber *number = @([eachString intValue]);
                    [eachColArray addObject:number];
                }
                [showArray addObject:eachColArray];
            }
        }
            break;
        case 32:
        {
            NSInteger count = showData.count / 4;
            for (int i = 0; i < count; i++) {
                NSNumber *firstNumber = showData[4 * i];
                NSNumber *secondNumber = showData[4 * i + 1];
                NSNumber *thirdNumber = showData[4 * i + 2];
                NSNumber *fourthNumber = showData[4 * i + 3];
                NSString *originString = @"00000000";
                NSString *firstResult = [self turn10to2:[firstNumber intValue]];
                NSRange firstRange = NSMakeRange(originString.length - firstResult.length, firstResult.length);
                firstResult =  [originString stringByReplacingCharactersInRange:firstRange withString:firstResult];
                
                NSString *secondResult = [self turn10to2:[secondNumber intValue]];
                NSRange secondRange = NSMakeRange(originString.length - secondResult.length, secondResult.length);
                secondResult = [originString stringByReplacingCharactersInRange:secondRange withString:secondResult];
                
                NSString *thirdResult = [self turn10to2:[thirdNumber intValue]];
                NSRange thirdRange = NSMakeRange(originString.length - thirdResult.length, thirdResult.length);
                thirdResult = [originString stringByReplacingCharactersInRange:thirdRange withString:thirdResult];
                
                NSString *fourthResult = [self turn10to2:[fourthNumber intValue]];
                NSRange fourthRange = NSMakeRange(originString.length - fourthResult.length, fourthResult.length);
                fourthResult = [originString stringByReplacingCharactersInRange:fourthRange withString:fourthResult];
                
                NSString *result = [firstResult stringByAppendingString:secondResult];
                result = [result stringByAppendingString:thirdResult];
                result = [result stringByAppendingString:fourthResult];
                result = [result substringToIndex:32];
                
                NSMutableArray *eachColArray = [NSMutableArray array];
                for (int i = 0; i < result.length; i++) {
                    NSString *eachString = [result substringWithRange:NSMakeRange(i, 1)];
                    NSNumber *number = @([eachString intValue]);
                    [eachColArray addObject:number];
                }
                [showArray addObject:eachColArray];
            }
        }
            break;
        case 48:
        {
            NSInteger count = showData.count / 6;
            for (int i = 0; i < count; i++) {
                NSNumber *firstNumber = showData[6 * i];
                NSNumber *secondNumber = showData[6 * i + 1];
                NSNumber *thirdNumber = showData[6 * i + 2];
                NSNumber *fourthNumber = showData[6 * i + 3];
                NSNumber *fivethNumber = showData[6 * i + 4];
                NSNumber *sixthNumber = showData[6 * i + 5];
                NSString *originString = @"00000000";
                NSString *firstResult = [self turn10to2:[firstNumber intValue]];
                NSRange firstRange = NSMakeRange(originString.length - firstResult.length, firstResult.length);
                firstResult =  [originString stringByReplacingCharactersInRange:firstRange withString:firstResult];
                
                NSString *secondResult = [self turn10to2:[secondNumber intValue]];
                NSRange secondRange = NSMakeRange(originString.length - secondResult.length, secondResult.length);
                secondResult = [originString stringByReplacingCharactersInRange:secondRange withString:secondResult];
                
                NSString *thirdResult = [self turn10to2:[thirdNumber intValue]];
                NSRange thirdRange = NSMakeRange(originString.length - thirdResult.length, thirdResult.length);
                thirdResult = [originString stringByReplacingCharactersInRange:thirdRange withString:thirdResult];
                
                NSString *fourthResult = [self turn10to2:[fourthNumber intValue]];
                NSRange fourthRange = NSMakeRange(originString.length - fourthResult.length, fourthResult.length);
                fourthResult = [originString stringByReplacingCharactersInRange:fourthRange withString:fourthResult];
                
                NSString *fivethResult = [self turn10to2:[fivethNumber intValue]];
                NSRange fivethRange = NSMakeRange(originString.length - fivethResult.length, fivethResult.length);
                fivethResult = [originString stringByReplacingCharactersInRange:fivethRange withString:fivethResult];
                
                NSString *sixthResult = [self turn10to2:[sixthNumber intValue]];
                NSRange sixthRange = NSMakeRange(originString.length - sixthResult.length, sixthResult.length);
                sixthResult = [originString stringByReplacingCharactersInRange:sixthRange withString:sixthResult];
                
                NSString *result = [firstResult stringByAppendingString:secondResult];
                result = [result stringByAppendingString:thirdResult];
                result = [result stringByAppendingString:fourthResult];
                result = [result stringByAppendingString:fivethResult];
                result = [result stringByAppendingString:sixthResult];
                result = [result substringToIndex:48];
                
                NSMutableArray *eachColArray = [NSMutableArray array];
                for (int i = 0; i < result.length; i++) {
                    NSString *eachString = [result substringWithRange:NSMakeRange(i, 1)];
                    NSNumber *number = @([eachString intValue]);
                    [eachColArray addObject:number];
                }
                [showArray addObject:eachColArray];
            }
        }
            break;
        default:
            break;
    }
    return showArray;
}

+ (NSData *)rotateArrayData:(NSData *)originData font:(NSInteger)font degree:(int)degree
{
    
    if (originData.length == 0) {
        return nil;
    }
    
    Byte *keyBytes = (Byte *)[originData bytes];
    int dataLength = (int)originData.length;
    
    NSMutableArray *originArray = [NSMutableArray array];
    for (int i = 0; i < dataLength; i++) {
        [originArray addObject:@(keyBytes[i])];
    }
    
    // 1.1 如果旋转度数为90度或270度，要将内容居中
    NSArray *array = [self showArrayWithData:originArray font:font];
    
    if (degree == 90 || degree == 270) {
        array = [HLUtils centerOptArrayWithLatticeArray:array];
    }
    
    // 2.将点阵数据旋转角度，得到新的点阵数据
    array = [HLUtils rotateArray:array degree:degree];
    
    NSString *redResult = @"";
    NSData *dataTotalData = [[NSData alloc] init];
    
    if (degree == 0 || degree == 360) {
        
        redResult = [JTCommon resultStrWithData:array];
        dataTotalData = [HLUtils stringToData:redResult];
        return dataTotalData;
    }
    
    int n = (int)array.count;
    NSArray *arr0 = array[0];
    int p =(int)arr0.count;
    
    NSMutableArray *resultArray = [NSMutableArray array];
    if (degree == 90) {
        for (int i = 0; i < n; i++) {
            NSMutableArray *targetColData = [NSMutableArray array];
            for (int j = 0; j < n; j++) {
                [targetColData addObject:array[n-1-j][i]];
            }
            [resultArray addObject:targetColData];
        }
        
        redResult = [JTCommon resultStrWithData:array];
        dataTotalData = [HLUtils stringToData:redResult];
        return dataTotalData;
    }
    
    if (degree == 180) {
        for (int i = 0; i < n; i++) {
            NSMutableArray *targetColData = [NSMutableArray array];
            for (int j = 0; j < p; j++) {
                [targetColData addObject:array[n-1-i][p-1-j]];
            }
            [resultArray addObject:targetColData];
        }
        redResult = [JTCommon resultStrWithData:array];
        dataTotalData = [HLUtils stringToData:redResult];
        return dataTotalData;
    }
    
    if (degree == 270) {
        for (int i = 0; i < n; i++) {
            NSMutableArray *targetColData = [NSMutableArray array];
            for (int j = 0; j < n; j++) {
                [targetColData addObject:array[j][n-1-i]];
            }
            [resultArray addObject:targetColData];
        }
        
        redResult = [JTCommon resultStrWithData:array];
        dataTotalData = [HLUtils stringToData:redResult];
        return dataTotalData;
    }
    
    return dataTotalData;
}

+ (NSArray *)rotateArray:(NSArray *)array degree:(int)degree
{
    if (degree == 0 || degree == 360) {
        return array;
    }
    
    int n = (int)array.count;
    NSArray *arr0 = array[0];
    int p =(int)arr0.count;
    
    NSMutableArray *resultArray = [NSMutableArray array];
    if (degree == 90) {
        for (int i = 0; i < n; i++) {
            NSMutableArray *targetColData = [NSMutableArray array];
            for (int j = 0; j < n; j++) {
                [targetColData addObject:array[n-1-j][i]];
            }
            [resultArray addObject:targetColData];
        }
        return resultArray;
    }
    
    if (degree == 180) {
        for (int i = 0; i < n; i++) {
            NSMutableArray *targetColData = [NSMutableArray array];
            for (int j = 0; j < p; j++) {
                [targetColData addObject:array[n-1-i][p-1-j]];
            }
            [resultArray addObject:targetColData];
        }
        return resultArray;
    }
    
    if (degree == 270) {
        for (int i = 0; i < n; i++) {
            NSMutableArray *targetColData = [NSMutableArray array];
            for (int j = 0; j < n; j++) {
                [targetColData addObject:array[j][n-1-i]];
            }
            [resultArray addObject:targetColData];
        }
        return resultArray;
    }
    
    return array;
}

+ (NSArray *)centerOptArrayWithLatticeArray:(NSArray *)latticeArray
{
    int dataLength = (int)latticeArray.count;
    if (dataLength == 0) {
        return nil;
    }
    
    int startIndex = 0;
    for (int i = 0; i < dataLength; i++) {
        NSArray *colData = latticeArray[i];
        for (NSNumber *number in colData) {
            if (number.intValue != 0) {
                startIndex = i;
                goto quit;
            }
        }
    }
    
quit:{
    
}
    
    int endIndex = dataLength - 1;
    for (int j = dataLength - 1; j > 0; j --) {
        NSArray *colData = latticeArray[j];
        for (NSNumber *number in colData) {
            if (number.intValue != 0) {
                endIndex = j;
                goto exit;
            }
        }
    }
    
exit:{
    
}
    
    int validCols = endIndex - (startIndex -1);
    int total = (dataLength - validCols);
    int left = total / 2;
    int right = total - left;
    
    NSMutableArray *result = [NSMutableArray array];
    for (int i = 0; i < left; i++) {
        NSArray *EmptyCol = [self emptyColArrayWith:@(0) rows:dataLength];
        [result addObject:EmptyCol];
    }
    
    for (int i = startIndex; i <= endIndex; i++) {
        NSArray *colData = latticeArray[i];
        [result addObject:colData];
    }
    
    for (int i = 0; i < right; i++) {
        NSArray *EmptyCol = [self emptyColArrayWith:@(0) rows:dataLength];
        [result addObject:EmptyCol];
    }
    
    return [result copy];
}

+ (NSArray *) optArrayWithLatticeArray:(NSArray *)latticeArray
{
    int dataLength = (int)latticeArray.count;
    if (dataLength == 0) {
        return nil;
    }
    
    NSArray *resultArray = [[NSArray alloc] init];
    int copyLength = -1;
    // 1. 从数组最后向前遍历，直到该列不是空列
    for (int i = dataLength - 1; i > 0; i --) {
        NSArray *colData = latticeArray[i];
        for (NSNumber *number in colData) {
            if (number.intValue != 0) {
                copyLength = i + 1;
                goto quit;
            }
        }
    }
    
quit:{
    
}
    
    // 2.再去除前面的空列，并在最后添加一个空列
    NSMutableArray *arrayM = [NSMutableArray array];
    if (copyLength > 0) {
        for (int j = 0; j < copyLength; j++) {
            NSArray *colData = latticeArray[j];
            [arrayM addObject:colData];
        }
        NSArray *EmptyCol = [self emptyColArrayWith:@(0) rows:16];
        [arrayM addObject:EmptyCol];
        resultArray= [arrayM copy];
        
        //针对90度、180度、270度点阵前面有空列的情况
        int beginLength = -1;
        //  从数组最前向后遍历，直到该列不是空列
        for (int i = 0; i < dataLength; i ++) {
            NSArray *colData = resultArray[i];
            for (NSNumber *number in colData) {
                if (number.intValue != 0) {
                    beginLength = i ;
                    goto quitBegin;
                }
            }
        }
        
    quitBegin:{
        
    }
        
        // 再去除前面的空列ß
        NSMutableArray *arrayBeginM = [NSMutableArray array];
        if (beginLength > -1) {
            for (int j = beginLength; j < resultArray.count; j++) {
                NSArray *colData = resultArray[j];
                [arrayBeginM addObject:colData];
            }
            resultArray= [arrayBeginM copy];
        }
        return resultArray;
    }
    
    // 3.如果全部为0，则可能全部为空列，则显示6列空白即可
    if (copyLength < 0) {
        for (int j = 0; j < 6; j++) {
            NSArray *EmptyCol = [self emptyColArrayWith:@(0) rows:16];
            [arrayM addObject:EmptyCol];
        }
    }
    
    return arrayM;
}

+ (NSArray *)optArrayWithLatticeArray:(NSArray *)latticeArray wordShowHeight:(NSInteger)wordShowHeight
{
    int deviceRow = wordShowHeight;
    
    int dataLength = (int)latticeArray.count;
    if (dataLength == 0) {
        return nil;
    }
    
    NSArray *resultArray = [[NSArray alloc] init];
    int copyLength = -1;
    // 1. 从数组最后向前遍历，直到该列不是空列
    for (int i = dataLength - 1; i > 0; i --) {
        NSArray *colData = latticeArray[i];
        for (NSNumber *number in colData) {
            if (number.intValue != 0) {
                copyLength = i + 1;
                goto quit;
            }
        }
    }
    
quit:{
    
}
    
    // 2.再去除前面的空列，并在最后添加二个空列
    NSMutableArray *arrayM = [NSMutableArray array];
    if (copyLength > 0) {
        for (int j = 0; j < copyLength; j++) {
            NSArray *colData = latticeArray[j];
            [arrayM addObject:colData];
        }
        NSArray *EmptyCol1 = [self emptyColArrayWith:@(0) rows:deviceRow];
        [arrayM addObject:EmptyCol1];
        //[arrayM addObject:EmptyCol2];
        resultArray= [arrayM copy];
        
        //针对90度、180度、270度点阵前面有空列的情况
        int beginLength = -1;
        //  从数组最前向后遍历，直到该列不是空列
        for (int i = 0; i < dataLength; i ++) {
            NSArray *colData = resultArray[i];
            for (NSNumber *number in colData) {
                if (number.intValue != 0) {
                    beginLength = i ;
                    goto quitBegin;
                }
            }
        }
        
    quitBegin:{
        
    }
        
        // 再去除前面的空列ß
        NSMutableArray *arrayBeginM = [NSMutableArray array];
        if (beginLength > -1) {
            for (int j = beginLength; j < resultArray.count; j++) {
                NSArray *colData = resultArray[j];
                [arrayBeginM addObject:colData];
            }
            resultArray= [arrayBeginM copy];
        }
        return resultArray;
    }
    
    // 3.如果全部为0，则可能全部为空列，则显示6列空白即可
    if (copyLength < 0) {
        for (int j = 0; j < 16; j++) {
            NSArray *EmptyCol = [self emptyColArrayWith:@(0) rows:deviceRow];
            [arrayM addObject:EmptyCol];
        }
    }
    
    return arrayM;
}


+ (NSArray *) optArrayWithLatticeArray:(NSArray *)latticeArray fontSpace:(int)fontSpace fontSize:(int)fontSize
{
    int dataLength = (int)latticeArray.count;
    if (dataLength == 0) {
        return nil;
    }
    
    NSArray *resultArray = [[NSArray alloc] init];
    int copyLength = -1;
    // 1. 从数组最后向前遍历，直到该列不是空列
    for (int i = dataLength - 1; i > 0; i --) {
        NSArray *colData = latticeArray[i];
        for (NSNumber *number in colData) {
            if (number.intValue != 0) {
                copyLength = i + 1;
                goto quit;
            }
        }
    }
    
quit:{
    
}
    
    // 2.再去除前面的空列，并在最后添加一个空列
    NSMutableArray *arrayM = [NSMutableArray array];
    if (copyLength > 0) {
        for (int j = 0; j < copyLength; j++) {
            NSArray *colData = latticeArray[j];
            [arrayM addObject:colData];
        }
        for (int i = 0; i<fontSpace; i++) {
            NSArray *EmptyCol = [self emptyColArrayWith:@(0) rows:16];
            [arrayM addObject:EmptyCol];
        }
        resultArray= [arrayM copy];
        
        //针对90度、180度、270度点阵前面有空列的情况
        int beginLength = -1;
        //  从数组最前向后遍历，直到该列不是空列
        for (int i = 0; i < dataLength; i ++) {
            NSArray *colData = resultArray[i];
            for (NSNumber *number in colData) {
                if (number.intValue != 0) {
                    beginLength = i ;
                    goto quitBegin;
                }
            }
        }
        
    quitBegin:{
        
    }
        
        // 再去除前面的空列ß
        NSMutableArray *arrayBeginM = [NSMutableArray array];
        if (beginLength > -1) {
            for (int j = beginLength; j < resultArray.count; j++) {
                NSArray *colData = resultArray[j];
                [arrayBeginM addObject:colData];
            }
            resultArray= [arrayBeginM copy];
        }
        return resultArray;
    }
    
    // 3.如果全部为0，则可能全部为空列，则显示6列空白即可
    if (copyLength < 0) {
         for (int j = 0; j < (fontSize/2); j++) {
            NSArray *EmptyCol = [self emptyColArrayWith:@(0) rows:16];
            [arrayM addObject:EmptyCol];
        }
    }
    
    return arrayM;
}

+ (NSArray *)optArrayWithLatticeArray:(NSArray *)latticeArray wordShowHeight:(NSInteger)wordShowHeight fontSpace:(int)fontSpace fontSize:(int)fontSize
{
    int deviceRow = wordShowHeight;
    
    int dataLength = (int)latticeArray.count;
    if (dataLength == 0) {
        return nil;
    }
    
    NSArray *resultArray = [[NSArray alloc] init];
    int copyLength = -1;
    // 1. 从数组最后向前遍历，直到该列不是空列
    for (int i = dataLength - 1; i > 0; i --) {
        NSArray *colData = latticeArray[i];
        for (NSNumber *number in colData) {
            if (number.intValue != 0) {
                copyLength = i + 1;
                goto quit;
            }
        }
    }
    
quit:{
    
}
    
    // 2.再去除前面的空列，并在最后添加二个空列
    NSMutableArray *arrayM = [NSMutableArray array];
    if (copyLength > 0) {
        for (int j = 0; j < copyLength; j++) {
            NSArray *colData = latticeArray[j];
            [arrayM addObject:colData];
        }
        for (int i = 0; i<fontSpace; i++) {
            NSArray *EmptyCol1 = [self emptyColArrayWith:@(0) rows:deviceRow];
            [arrayM addObject:EmptyCol1];
        }
        //[arrayM addObject:EmptyCol2];
        resultArray= [arrayM copy];
        
        //针对90度、180度、270度点阵前面有空列的情况
        int beginLength = -1;
        //  从数组最前向后遍历，直到该列不是空列
        for (int i = 0; i < dataLength; i ++) {
            NSArray *colData = resultArray[i];
            for (NSNumber *number in colData) {
                if (number.intValue != 0) {
                    beginLength = i ;
                    goto quitBegin;
                }
            }
        }
        
    quitBegin:{
        
    }
        
        // 再去除前面的空列ß
        NSMutableArray *arrayBeginM = [NSMutableArray array];
        if (beginLength > -1) {
            for (int j = beginLength; j < resultArray.count; j++) {
                NSArray *colData = resultArray[j];
                [arrayBeginM addObject:colData];
            }
            resultArray= [arrayBeginM copy];
        }
        return resultArray;
    }
    
    // 3.如果全部为0，则可能全部为空列，则显示6列空白即可
    if (copyLength < 0) {
        for (int j = 0; j < (fontSize/2); j++) {
            NSArray *EmptyCol = [self emptyColArrayWith:@(0) rows:deviceRow];
            [arrayM addObject:EmptyCol];
        }
    }
    
    return arrayM;
}

+ (NSArray *)colorArrayWithLatticeArray:(NSArray *)latticeArray rgbArray:(NSArray *)rgbArray
{
    if (!latticeArray || !rgbArray) {
        return nil;
    }
    
    NSMutableArray *colorArray = [NSMutableArray array];
    for (NSArray *oneColArray in latticeArray) {
        NSMutableArray *oneColColorArray = [NSMutableArray array];
        for (NSNumber *number in oneColArray) {
            if (number.intValue == 0) {
                [oneColColorArray addObject:@[@"0", @"0", @"0"]];
            } else {
                [oneColColorArray addObject:rgbArray];
            }
        }
        [colorArray addObject:oneColColorArray];
    }
    
    return colorArray;
}

+ (NSArray *)colorArrayWithLatticeNumArray:(NSArray *)latticeArray rgbArray:(NSArray *)rgbArray
{
    if (!latticeArray || !rgbArray) {
        return nil;
    }
    
    NSMutableArray *colorArray = [NSMutableArray array];
    for (NSArray *oneColArray in latticeArray) {
        NSMutableArray *oneColColorArray = [NSMutableArray array];
        for (NSNumber *number in oneColArray) {
            if (number.intValue == 0) {
                [oneColColorArray addObject:@[@0, @0, @0]];
            } else {
                [oneColColorArray addObject:rgbArray];
            }
        }
        [colorArray addObject:oneColColorArray];
    }
    
    return colorArray;
}

+ (NSArray *)showArrayWithData:(NSArray *)showData
{
    NSMutableArray *showArray = [NSMutableArray array];
    NSInteger count = showData.count / 2;
    for (int i = 0; i < count; i++) {
        NSNumber *firstNumber = showData[2 * i];
        NSNumber *secondNumber = showData[2 * i + 1];
        NSString *originString = @"00000000";
        NSString *firstResult = [self turn10to2:[firstNumber intValue]];
        NSRange firstRange = NSMakeRange(originString.length - firstResult.length, firstResult.length);
        firstResult =  [originString stringByReplacingCharactersInRange:firstRange withString:firstResult];
        
        NSString *secondResult = [self turn10to2:[secondNumber intValue]];
        NSRange secondRange = NSMakeRange(originString.length - secondResult.length, secondResult.length);
        secondResult = [originString stringByReplacingCharactersInRange:secondRange withString:secondResult];
        
        NSString *result = [firstResult stringByAppendingString:secondResult];
        result = [result substringToIndex:16];
        
        NSMutableArray *eachColArray = [NSMutableArray array];
        for (int i = 0; i < result.length; i++) {
            NSString *eachString = [result substringWithRange:NSMakeRange(i, 1)];
            NSNumber *number = @([eachString intValue]);
            [eachColArray addObject:number];
        }
        [showArray addObject:eachColArray];
    }
    
    return showArray;
}

+ (NSArray *)showArrayWithData:(NSArray *)showData wordShowHeight:(NSInteger)wordShowHeight
{
    NSMutableArray *showArray = [NSMutableArray array];
    switch (wordShowHeight) {
        case 12:
        {
            NSInteger count = showData.count / 2;
            for (int i = 0; i < count; i++) {
                NSNumber *firstNumber = showData[2 * i];
                NSNumber *secondNumber = showData[2 * i + 1];
                NSString *originString = @"00000000";
                NSString *firstResult = [self turn10to2:[firstNumber intValue]];
                NSRange firstRange = NSMakeRange(originString.length - firstResult.length, firstResult.length);
                firstResult =  [originString stringByReplacingCharactersInRange:firstRange withString:firstResult];
                
                NSString *secondResult = [self turn10to2:[secondNumber intValue]];
                NSRange secondRange = NSMakeRange(originString.length - secondResult.length, secondResult.length);
                secondResult = [originString stringByReplacingCharactersInRange:secondRange withString:secondResult];
                
                NSString *result = [firstResult stringByAppendingString:secondResult];
                result = [result substringToIndex:12];
                
                NSMutableArray *eachColArray = [NSMutableArray array];
                for (int i = 0; i < result.length; i++) {
                    NSString *eachString = [result substringWithRange:NSMakeRange(i, 1)];
                    NSNumber *number = @([eachString intValue]);
                    [eachColArray addObject:number];
                }
                [showArray addObject:eachColArray];
            }
        }
            break;
        case 16:
            
            break;
        case 20:
        {
            NSInteger count = showData.count / 3;
            for (int i = 0; i < count; i++) {
                NSNumber *firstNumber = showData[3 * i];
                NSNumber *secondNumber = showData[3 * i + 1];
                NSNumber *thirdNumber = showData[3 * i + 2];
                NSString *originString = @"00000000";
                NSString *firstResult = [self turn10to2:[firstNumber intValue]];
                NSRange firstRange = NSMakeRange(originString.length - firstResult.length, firstResult.length);
                firstResult =  [originString stringByReplacingCharactersInRange:firstRange withString:firstResult];
                
                NSString *secondResult = [self turn10to2:[secondNumber intValue]];
                NSRange secondRange = NSMakeRange(originString.length - secondResult.length, secondResult.length);
                secondResult = [originString stringByReplacingCharactersInRange:secondRange withString:secondResult];
                
                NSString *thirdResult = [self turn10to2:[thirdNumber intValue]];
                NSRange thirdRange = NSMakeRange(originString.length - thirdResult.length, thirdResult.length);
                thirdResult = [originString stringByReplacingCharactersInRange:thirdRange withString:thirdResult];
                
                NSString *result = [firstResult stringByAppendingString:secondResult];
                result = [result stringByAppendingString:thirdResult];
                result = [result substringToIndex:20];
                
                NSMutableArray *eachColArray = [NSMutableArray array];
                for (int i = 0; i < result.length; i++) {
                    NSString *eachString = [result substringWithRange:NSMakeRange(i, 1)];
                    NSNumber *number = @([eachString intValue]);
                    [eachColArray addObject:number];
                }
                [showArray addObject:eachColArray];
            }
        }
            break;
        case 24:
        {
            NSInteger count = showData.count / 3;
            for (int i = 0; i < count; i++) {
                NSNumber *firstNumber = showData[3 * i];
                NSNumber *secondNumber = showData[3 * i + 1];
                NSNumber *thirdNumber = showData[3 * i + 2];
                NSString *originString = @"00000000";
                NSString *firstResult = [self turn10to2:[firstNumber intValue]];
                NSRange firstRange = NSMakeRange(originString.length - firstResult.length, firstResult.length);
                firstResult =  [originString stringByReplacingCharactersInRange:firstRange withString:firstResult];
                
                NSString *secondResult = [self turn10to2:[secondNumber intValue]];
                NSRange secondRange = NSMakeRange(originString.length - secondResult.length, secondResult.length);
                secondResult = [originString stringByReplacingCharactersInRange:secondRange withString:secondResult];
                
                NSString *thirdResult = [self turn10to2:[thirdNumber intValue]];
                NSRange thirdRange = NSMakeRange(originString.length - thirdResult.length, thirdResult.length);
                thirdResult = [originString stringByReplacingCharactersInRange:thirdRange withString:thirdResult];
                
                NSString *result = [firstResult stringByAppendingString:secondResult];
                result = [result stringByAppendingString:thirdResult];
                result = [result substringToIndex:24];
                
                NSMutableArray *eachColArray = [NSMutableArray array];
                for (int i = 0; i < result.length; i++) {
                    NSString *eachString = [result substringWithRange:NSMakeRange(i, 1)];
                    NSNumber *number = @([eachString intValue]);
                    [eachColArray addObject:number];
                }
                [showArray addObject:eachColArray];
            }
        }
            break;
        case 32:
        {
            NSInteger count = showData.count / 4;
            for (int i = 0; i < count; i++) {
                NSNumber *firstNumber = showData[4 * i];
                NSNumber *secondNumber = showData[4 * i + 1];
                NSNumber *thirdNumber = showData[4 * i + 2];
                NSNumber *fourthNumber = showData[4 * i + 3];
                NSString *originString = @"00000000";
                NSString *firstResult = [self turn10to2:[firstNumber intValue]];
                NSRange firstRange = NSMakeRange(originString.length - firstResult.length, firstResult.length);
                firstResult =  [originString stringByReplacingCharactersInRange:firstRange withString:firstResult];
                
                NSString *secondResult = [self turn10to2:[secondNumber intValue]];
                NSRange secondRange = NSMakeRange(originString.length - secondResult.length, secondResult.length);
                secondResult = [originString stringByReplacingCharactersInRange:secondRange withString:secondResult];
                
                NSString *thirdResult = [self turn10to2:[thirdNumber intValue]];
                NSRange thirdRange = NSMakeRange(originString.length - thirdResult.length, thirdResult.length);
                thirdResult = [originString stringByReplacingCharactersInRange:thirdRange withString:thirdResult];
                
                NSString *fourthResult = [self turn10to2:[fourthNumber intValue]];
                NSRange fourthRange = NSMakeRange(originString.length - fourthResult.length, fourthResult.length);
                fourthResult = [originString stringByReplacingCharactersInRange:fourthRange withString:fourthResult];
                
                NSString *result = [firstResult stringByAppendingString:secondResult];
                result = [result stringByAppendingString:thirdResult];
                result = [result stringByAppendingString:fourthResult];
                result = [result substringToIndex:32];
                
                NSMutableArray *eachColArray = [NSMutableArray array];
                for (int i = 0; i < result.length; i++) {
                    NSString *eachString = [result substringWithRange:NSMakeRange(i, 1)];
                    NSNumber *number = @([eachString intValue]);
                    [eachColArray addObject:number];
                }
                [showArray addObject:eachColArray];
            }
        }
            break;
        case 48:
        {
            NSInteger count = showData.count / 6;
            for (int i = 0; i < count; i++) {
                NSNumber *firstNumber = showData[6 * i];
                NSNumber *secondNumber = showData[6 * i + 1];
                NSNumber *thirdNumber = showData[6 * i + 2];
                NSNumber *fourthNumber = showData[6 * i + 3];
                NSNumber *fivethNumber = showData[6 * i + 4];
                NSNumber *sixthNumber = showData[6 * i + 5];
                NSString *originString = @"00000000";
                NSString *firstResult = [self turn10to2:[firstNumber intValue]];
                NSRange firstRange = NSMakeRange(originString.length - firstResult.length, firstResult.length);
                firstResult =  [originString stringByReplacingCharactersInRange:firstRange withString:firstResult];
                
                NSString *secondResult = [self turn10to2:[secondNumber intValue]];
                NSRange secondRange = NSMakeRange(originString.length - secondResult.length, secondResult.length);
                secondResult = [originString stringByReplacingCharactersInRange:secondRange withString:secondResult];
                
                NSString *thirdResult = [self turn10to2:[thirdNumber intValue]];
                NSRange thirdRange = NSMakeRange(originString.length - thirdResult.length, thirdResult.length);
                thirdResult = [originString stringByReplacingCharactersInRange:thirdRange withString:thirdResult];
                
                NSString *fourthResult = [self turn10to2:[fourthNumber intValue]];
                NSRange fourthRange = NSMakeRange(originString.length - fourthResult.length, fourthResult.length);
                fourthResult = [originString stringByReplacingCharactersInRange:fourthRange withString:fourthResult];
                
                NSString *fivethResult = [self turn10to2:[fivethNumber intValue]];
                NSRange fivethRange = NSMakeRange(originString.length - fivethResult.length, fivethResult.length);
                fivethResult = [originString stringByReplacingCharactersInRange:fivethRange withString:fivethResult];
                
                NSString *sixthResult = [self turn10to2:[sixthNumber intValue]];
                NSRange sixthRange = NSMakeRange(originString.length - sixthResult.length, sixthResult.length);
                sixthResult = [originString stringByReplacingCharactersInRange:sixthRange withString:sixthResult];
                
                NSString *result = [firstResult stringByAppendingString:secondResult];
                result = [result stringByAppendingString:thirdResult];
                result = [result stringByAppendingString:fourthResult];
                result = [result stringByAppendingString:fivethResult];
                result = [result stringByAppendingString:sixthResult];
                result = [result substringToIndex:48];
                
                NSMutableArray *eachColArray = [NSMutableArray array];
                for (int i = 0; i < result.length; i++) {
                    NSString *eachString = [result substringWithRange:NSMakeRange(i, 1)];
                    NSNumber *number = @([eachString intValue]);
                    [eachColArray addObject:number];
                }
                [showArray addObject:eachColArray];
            }
        }
            break;
        default:
            break;
    }
    return showArray;
}

+ (NSArray *)emptyColArrayWith:(NSObject *)element rows:(int)rows
{
    if (!element) {
        return nil;
    }
    
    NSMutableArray *arrayM = [NSMutableArray array];
    for (int i = 0; i < rows; i++) {
        [arrayM addObject:element];
    }
    return [arrayM copy];
}

+ (NSString *)turn10to2:(int)orginNumber
{
    int num = orginNumber;
    
    NSMutableString * result = [[NSMutableString alloc]init];
    while (num > 0) {
        NSString * reminder = [NSString stringWithFormat:@"%d",num % 2];
        [result insertString:reminder atIndex:0];
        num = num / 2;
    }
    return result;
}

+(NSData *)stringToData:(NSString *)originString {
    // 计算预期的 NSData 大小
    originString=[[originString uppercaseString] stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSUInteger length = originString.length / 2;
    NSMutableData *data = [NSMutableData dataWithCapacity:length];

    // 每次处理两个字符
    for (NSUInteger i = 0; i < originString.length; i += 2) {
        // 确保有足够的字符
        if (i + 1 >= originString.length) {
            return nil; // 无效的十六进制字符串
        }

        // 获取第一个十六进制字符
        unichar hex_char1 = [originString characterAtIndex:i];
        int int_ch1;
        if(hex_char1 >= '0' && hex_char1 <='9')
            int_ch1 = (hex_char1-48)*16;   //// 0 的Ascll - 48
        else if(hex_char1 >= 'A' && hex_char1 <='F')
            int_ch1 = (hex_char1-55)*16; //// A 的Ascll - 65
        else
            return nil;

        // 获取第二个十六进制字符
        unichar hex_char2 = [originString characterAtIndex:i + 1];
        int int_ch2;
        if(hex_char2 >= '0' && hex_char2 <='9')
            int_ch2 = (hex_char2-48); //// 0 的Ascll - 48
        else if(hex_char2 >= 'A' && hex_char2 <='F')
            int_ch2 = hex_char2-55; //// A 的Ascll - 65
        else
            return nil;

        // 组合字节并添加到数据中
        Byte byte = (Byte)(int_ch1 + int_ch2);
        [data appendBytes:&byte length:1];
    }
    return [data copy]; // 返回不可变的 NSData
}

+ (NSData *)stringToByte:(NSString*)string
{
    NSString *hexString=[[string uppercaseString] stringByReplacingOccurrencesOfString:@" " withString:@""];
    if ([hexString length]%2!=0) {
        return nil;
    }
    Byte tempbyt[1]={0};
    NSMutableData* bytes=[NSMutableData data];
    for(int i=0;i<[hexString length];i++)
    {
        unichar hex_char1 = [hexString characterAtIndex:i]; ////两位16进制数中的第一位(高位*16)
        int int_ch1;
        if(hex_char1 >= '0' && hex_char1 <='9')
            int_ch1 = (hex_char1-48)*16;   //// 0 的Ascll - 48
        else if(hex_char1 >= 'A' && hex_char1 <='F')
            int_ch1 = (hex_char1-55)*16; //// A 的Ascll - 65
        else
            return nil;
        i++;
        
        unichar hex_char2 = [hexString characterAtIndex:i]; ///两位16进制数中的第二位(低位)
        int int_ch2;
        if(hex_char2 >= '0' && hex_char2 <='9')
            int_ch2 = (hex_char2-48); //// 0 的Ascll - 48
        else if(hex_char2 >= 'A' && hex_char2 <='F')
            int_ch2 = hex_char2-55; //// A 的Ascll - 65
        else
            return nil;
        
        tempbyt[0] = int_ch1+int_ch2;  ///将转化后的数放入Byte数组里
        [bytes appendBytes:tempbyt length:1];
    }
    return bytes;
}

//将data转换成一个长字符串进行存储
+ (NSString *)dataToString:(NSData*)data{
    Byte *resultByte = (Byte*)[data bytes];//取出字节数组
    NSMutableString *result = [NSMutableString string];
    
    for (int i = 0; i < data.length; i++) {
        int number = (int)resultByte[i];
        
        NSString *numberStr = [NSString stringWithFormat:@"%02x",number];
        [result appendString:numberStr];
    }
    return result;
}

//将NSArray转换成一个长字符串进行存储
+ (NSString *)arrToString:(NSArray*)arr{
    NSMutableString *result = [[NSMutableString alloc] init];

    for (int i = 0; i < arr.count; i++) {
        int number = [arr[i] intValue];
        
        NSString *numberStr = [NSString stringWithFormat:@"%02x", number];
        [result appendString:numberStr]; // 使用 NSMutableString 的 appendString 方法
    }
    return result;
}

/// 将文字的二进制数据向下移位
+ (NSData *)iArrayRightShift:(NSData *)originData colBytes:(int)colBytes
{
    if (originData.length == 0) {
        return nil;
    }
    
    Byte *keyBytes = (Byte *)[originData bytes];
    int dataLength = (int)originData.length;
    
    int j = 0;
    
    for (int i = 0; i < dataLength; i += colBytes)
    {
        j = colBytes - 1;
        for (; j > 0; j--)
        {
            keyBytes[i+j] = (keyBytes[i + j] >> 1) | ((keyBytes[i + j -1] & 0x01) << 7); // 注意要用不带符号的右移
        }
        
        keyBytes[i + j] >>= 1;
    }
    
    NSData *showData = [[NSData alloc] initWithBytes:keyBytes length:dataLength];
    
    return showData;
}

/// 将colBytes个字节向下移动space位
+ (NSData *)iArrayRightShift:(NSData *)originData originColBytes:(int)colBytes space:(NSInteger)space targetRow:(int)targetRow
{
    if (originData.length == 0) {
        return nil;
    }
    NSData *showData;
    
    switch (targetRow) {
        case 16:
        {
            
            Byte *keyBytes = (Byte *)[originData bytes];
            int dataLength = (int)originData.length;
            
            int newDataLength = (int)dataLength;
            Byte *newKeyBytes = (Byte *)malloc(newDataLength * sizeof(Byte));
            
            int j = 0;
            
            for (int i = 0; i < dataLength; i += colBytes)
            {
                
                j = colBytes - 1;
                for (; j > 0; j--)
                {
                    Byte mask = (1 << space) - 1;
                    Byte byte = keyBytes[i + j -1];
                    
                    // 使用位与运算提取位的值
                    Byte extractedValue = byte & mask;
                    newKeyBytes[i+j] = (keyBytes[i + j] >> space) | (extractedValue << (8-space)); // 注意要用不带符号的右移
                }
                
                newKeyBytes[i + j] = keyBytes[i + j] >> space;
            }
            
            showData = [[NSData alloc] initWithBytes:newKeyBytes length:newDataLength];
        }
            break;
        case 20:
        {
            
            Byte *keyBytes = (Byte *)[originData bytes];
            int dataLength = (int)originData.length;
            
            int newDataLength = (int)dataLength * 1.5;
            Byte *newKeyBytes = (Byte *)malloc(newDataLength * sizeof(Byte));
            
            int j = 0;
            
            for (int i = 0; i < dataLength; i += colBytes)
            {
                newKeyBytes[3*(i/2)] = 0;
                newKeyBytes[3*(i/2)+1] = 0;
                newKeyBytes[3*(i/2)+2] = 0;
                
                j = colBytes - 1;
                for (; j > 0; j--)
                {
                    Byte mask = (1 << space) - 1;
                    Byte down= keyBytes[i + j];
                    newKeyBytes[3*(i/2)+2] = ((down & mask) << (8 - space));
                    
                    Byte up = keyBytes[i + j -1];
                    // 使用位与运算提取位的值
                    Byte extractedValue = up & mask;
                    newKeyBytes[3*(i/2)+1] = (down >> space) | (extractedValue << (8 - space)); // 注意要用不带符号的右移
                }
                
                newKeyBytes[3*(i/2)] = keyBytes[i + j] >> space;
            }
            
            showData = [[NSData alloc] initWithBytes:newKeyBytes length:newDataLength];
        }
            break;
        case 24:
        {
            if(colBytes == 2){
                
                Byte *keyBytes = (Byte *)[originData bytes];
                int dataLength = (int)originData.length;
                
                int newDataLength = (int)dataLength * 1.5;
                Byte *newKeyBytes = (Byte *)malloc(newDataLength * sizeof(Byte));
                
                int j = 0;
                
                for (int i = 0; i < dataLength; i += colBytes)
                {
                    newKeyBytes[3*(i/2)] = 0;
                    newKeyBytes[3*(i/2)+1] = 0;
                    newKeyBytes[3*(i/2)+2] = 0;
                    
                    j = colBytes - 1;
                    for (; j > 0; j--)
                    {
                        Byte mask = (1 << space) - 1;
                        Byte down= keyBytes[i + j];
                        newKeyBytes[3*(i/2)+2] = ((down & mask) << (8 - space));
                        
                        Byte up = keyBytes[i + j -1];
                        // 使用位与运算提取位的值
                        Byte extractedValue = up & mask;
                        newKeyBytes[3*(i/2)+1] = (down >> space) | (extractedValue << (8 - space)); // 注意要用不带符号的右移
                    }
                    
                    newKeyBytes[3*(i/2)] = keyBytes[i + j] >> space;
                }
                
                showData = [[NSData alloc] initWithBytes:newKeyBytes length:newDataLength];
                
            }else if(colBytes == 3){
                
                Byte *keyBytes = (Byte *)[originData bytes];
                int dataLength = (int)originData.length;
                
                int newDataLength = (int)dataLength;
                Byte *newKeyBytes = (Byte *)malloc(newDataLength * sizeof(Byte));
                
                int j = 0;
                
                for (int i = 0; i < dataLength; i += colBytes)
                {
                    newKeyBytes[i] = 0;
                    newKeyBytes[i+1] = 0;
                    newKeyBytes[i+2] = 0;
                    
                    j = colBytes - 1;
                    for (; j > 0; j--)
                    {
                        Byte mask = (1 << space) - 1;
                       Byte byte = keyBytes[i + j -1];
                       
                       // 使用位与运算提取位的值
                       Byte extractedValue = byte & mask;
                       newKeyBytes[i+j] = (keyBytes[i + j] >> space) | (extractedValue << (8-space)); // 注意要用不带符号的右移
                    }
                    
                    newKeyBytes[i] = keyBytes[i + j] >> space;
                }
                
                showData = [[NSData alloc] initWithBytes:newKeyBytes length:newDataLength];
                
            }
        }
            break;
        case 32:
        {
            if(colBytes == 2){
                
                if (space > 8) {
                    space = space - 8;
                    
                    Byte *keyBytes = (Byte *)[originData bytes];
                    int dataLength = (int)originData.length;
                    
                    int newDataLength = (int)dataLength * 2;
                    Byte *newKeyBytes = (Byte *)malloc(newDataLength * sizeof(Byte));
                    
                    int j = 0;
                    for (int i = 0; i < dataLength; i += colBytes)
                    {
                        newKeyBytes[4*(i/2)] = 0;
                        newKeyBytes[4*(i/2)+1] = 0;
                        newKeyBytes[4*(i/2)+2] = 0;
                        newKeyBytes[4*(i/2)+3] = 0;
                        
                        j = colBytes - 1;
                        for (; j > 0; j--)
                        {
                            Byte byte = keyBytes[i + j -1];
                            Byte mask = (1 << space) - 1;
                            
                            // 使用位与运算提取位的值
                            Byte extractedValue = byte & mask;
                            newKeyBytes[4*(i/2)+2] = (keyBytes[i + j] >> space) | (extractedValue << (8 - space)); //
                        }
                        
                        newKeyBytes[4*(i/2)+1] = keyBytes[i + j] >> space;;
                    }
                    
                    showData = [[NSData alloc] initWithBytes:newKeyBytes length:newDataLength];
                }else if (space == 8) {
                    space = space - 8;
                    
                    Byte *keyBytes = (Byte *)[originData bytes];
                    int dataLength = (int)originData.length;
                    
                    int newDataLength = (int)dataLength * 2;
                    Byte *newKeyBytes = (Byte *)malloc(newDataLength * sizeof(Byte));
                    
                    int j = 0;
                    
                    for (int i = 0; i < dataLength; i += colBytes)
                    {
                        newKeyBytes[4*(i/2)] = 0;
                        newKeyBytes[4*(i/2)+1] = 0;
                        newKeyBytes[4*(i/2)+2] = 0;
                        newKeyBytes[4*(i/2)+3] = 0;
                        
                        j = colBytes - 1;
                        for (; j > 0; j--)
                        {
                            newKeyBytes[4*(i/2)+2] = keyBytes[i+j];
                        }
                        newKeyBytes[4*(i/2)+1] = keyBytes[i + j];
                    }
                    
                    showData = [[NSData alloc] initWithBytes:newKeyBytes length:newDataLength];
                }
                
            }else if(colBytes == 3){
                if(space < 8){
                    
                    Byte *keyBytes = (Byte *)[originData bytes];
                    int dataLength = (int)originData.length;
                    
                    int newDataLength = (int)dataLength / 3 * 4;
                    Byte *newKeyBytes = (Byte *)malloc(newDataLength * sizeof(Byte));
                    
                    int j = 0;
                    
                    for (int i = 0; i < dataLength; i += colBytes)
                    {
                        
                        newKeyBytes[4*(i/3)] = 0;
                        newKeyBytes[4*(i/3)+1] = 0;
                        newKeyBytes[4*(i/3)+2] = 0;
                        newKeyBytes[4*(i/3)+3] = 0;
                        
                        j = colBytes - 1;
                        for (; j > 0; j--)
                        {
                            Byte mask = (1 << space) - 1;
                            Byte down= keyBytes[i + j];
                            if(j == (colBytes - 1))newKeyBytes[4*(i/3)+(j+1)] = ((down & mask) << (8 - space));
                            
                            Byte up = keyBytes[i + j -1];
                            // 使用位与运算提取位的值
                            Byte extractedValue = up & mask;
                            newKeyBytes[4*(i/3)+j] = (down >> space) | (extractedValue << (8 - space)); // 注意要用不带符号的右移
                        }
                        
                        newKeyBytes[4*(i/3)] = keyBytes[i + j] >> space;
                    }
                    
                    showData = [[NSData alloc] initWithBytes:newKeyBytes length:newDataLength];
                }
            }
        }
            break;
        default:
            break;
    }

    return showData;
}

//二维数组上下增加space数据
+ (NSArray *)iArrayRightShift:(NSArray *)originArr space:(NSInteger)space{
    NSMutableArray *pixelRGBArr = [[NSMutableArray alloc] init];
    for (int col = 0; col < originArr.count; col++) {
        NSMutableArray *rowPixelRGBArr = [[NSMutableArray alloc] init];
        NSArray *rowArr = originArr[col];
        
        for (int i = 0; i < space; i++) {
            NSArray *rgbArray = @[@0,@0,@0];
            [rowPixelRGBArr addObject:rgbArray];
        }
        
        for (int row = 0; row < rowArr.count; row++) {
            NSArray *rgbArray = rowArr[row];
            [rowPixelRGBArr addObject:rgbArray];
        }
        
        for (int i = 0; i < space; i++) {
            NSArray *rgbArray = @[@0,@0,@0];
            [rowPixelRGBArr addObject:rgbArray];
        }
        
        [pixelRGBArr addObject:rowPixelRGBArr];
    }
    return pixelRGBArr;
}

+ (NSData *)arrayToByte:(NSArray *)intArray
{
    // 计算字节数组的长度
    NSUInteger byteCount = intArray.count;
    
    // 创建字节数组缓冲区
    Byte *byteBuffer = (Byte *)malloc(byteCount);
    
    // 将整数数组转换为字节数组
    for (NSUInteger i = 0; i < intArray.count; i++) {
        int number = [intArray[i] intValue];
        byteBuffer[i] = number;
    }
    
    // 将字节数组封装成NSData对象
    NSData *data = [NSData dataWithBytes:byteBuffer length:byteCount];
    return data;
}

+ (NSArray *)byteToArray:(NSData *)data
{
    // 计算整数数组的长度
    NSUInteger intCount = data.length;
    
    // 创建整数数组
    NSMutableArray *intArray = [NSMutableArray arrayWithCapacity:intCount];
    
    // 从字节数组中提取整数值
    const Byte *byteBuffer = data.bytes;
    for (NSUInteger i = 0; i < intCount; i++) {
        int number = byteBuffer[i];
        [intArray addObject:@(number)];
    }
    return [intArray copy];
}

+(void)setFLAnimatedImageView:(FLAnimatedImageView *)gif name:(NSString *)name{
    NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:@"gif"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    FLAnimatedImage *image = [FLAnimatedImage animatedImageWithGIFData:data];
    gif.animatedImage = image;
}

+(UIImage *)getNewImage:(UIImage *)image color:(UIColor *)newColor{
    // 使用 Core Graphics 创建图形上下文
    UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // 将图像绘制到图形上下文中
    [image drawAtPoint:CGPointZero];
    
    // 设置混合模式和颜色
    CGContextSetBlendMode(context, kCGBlendModeSourceIn);
    CGContextSetFillColorWithColor(context, newColor.CGColor);
    
    // 填充整个图像区域
    CGContextFillRect(context, CGRectMake(0, 0, image.size.width, image.size.height));
    
    // 从图形上下文中获取新图像
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // 结束图形上下文
    UIGraphicsEndImageContext();
    return newImage;
}

+ (NSMutableAttributedString *)attributedStringWith:(ColorItemModel32 *)textModel
{
    NSArray *colorTextModel32Arr = textModel.colorTextModel32Arr;
    ColorTextModel32 *ctm;

    // CRITICAL DEBUG: Log the array count before switch
    NSLog(@"[HLUtils] attributedStringWith: colorTextModel32Arr.count = %lu", (unsigned long)colorTextModel32Arr.count);

    switch (colorTextModel32Arr.count) {
        case 0:
            NSLog(@"[HLUtils] Switch case 0: returning nil");
            return nil;
            break;
        case 1:
            NSLog(@"[HLUtils] Switch case 1: using colorTextModel32Arr[0]");
            ctm = colorTextModel32Arr[0];
            break;
        case 3:
        {
            NSLog(@"[HLUtils] Switch case 3: selecting between colorTextModel32Arr[0] and [1]");
            ColorTextModel32 *ctm1= colorTextModel32Arr[0];
            ColorTextModel32 *ctm2= colorTextModel32Arr[1];
            if(ctm1.textItems.count != 0){
                ctm = ctm1;
            }else{
                ctm = ctm2;
            }
        }
            break;
        default:
            NSLog(@"[HLUtils] Switch default case: unexpected count = %lu", (unsigned long)colorTextModel32Arr.count);
            // Handle unexpected count by using the first element if available
            if (colorTextModel32Arr.count > 0) {
                ctm = colorTextModel32Arr[0];
            } else {
                return nil;
            }
            break;
    }
    
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] init];
    UIFont *font = [UIFont systemFontOfSize:15.0];
    for (HLColorTextItem *textItem in ctm.textItems) {
        if (textItem.itemType == HLTextItemTypeText) {
            NSArray *rgbArray = [textItem.rgbString componentsSeparatedByString:@","];
            
            CGFloat red = [rgbArray[0] floatValue];
            CGFloat green = [rgbArray[1] floatValue];
            CGFloat blue = [rgbArray[2] floatValue];
            UIColor *selectColor = [UIColor colorWithRed:red green:green blue:blue alpha:1];
            
            NSMutableAttributedString *attrSting = [[NSMutableAttributedString alloc] initWithString:textItem.text];
            [attrSting setAttributes:@{NSForegroundColorAttributeName:selectColor,NSFontAttributeName:font} range:NSMakeRange(0, 1)];
            [attributedText appendAttributedString:attrSting];
        } else {
            
            if ([[ThemManager sharedInstance].peripheralName isEqualToString:@"CoolLEDMX"] || [[ThemManager sharedInstance].peripheralName isEqualToString:@"CoolLEDUX"]) {
                
            }else{
                
                HLTextAttachment *attachment = [[HLTextAttachment alloc] init];
                attachment.emoji_text = textItem.text;
                //            NSString *imageName = textItem.emojiDict[@"png"];
                //            attachment.image = [UIImage imageNamed:imageName];
                
                NSString *json = textItem.emojiDict[@"json3232"];
                NSString *jsonPath = [[NSBundle mainBundle] pathForResource:json ofType:@"json"];
                NSData *emojiData = [[NSData alloc] initWithContentsOfFile:jsonPath];
                
                NSDictionary *localDict = [NSJSONSerialization JSONObjectWithData:emojiData options:0 error:nil];
                NSArray *animationData = localDict[@"animationData"];
                int length = (int)(animationData.count);
                // 处理红色数据
                NSArray *redArray = [animationData subarrayWithRange:NSMakeRange(0, length)];
                NSArray *latticeArray = [HLUtils showArrayWithData:redArray wordShowHeight:32];
                UIImage *newImage = [JTCommon createImageFromPixelData:latticeArray width:32 height:32 scale:1 monochrome:textItem.rgbString];
                
                attachment.image = newImage;
                attachment.emojiDict = textItem.emojiDict;
                attachment.bounds = CGRectMake(0, font.descender, font.lineHeight, font.lineHeight);
                
                NSAttributedString *emojiAttributeString = [NSAttributedString attributedStringWithAttachment:attachment];
                [attributedText appendAttributedString:emojiAttributeString];
                
            }
            
        }
    }
    
    return attributedText;
}

+ (int)colorExchangeFloat:(float)colorValue{
    float convertedValue = colorValue * 255;
    int trueValue;
    if (convertedValue >= 238) {
        trueValue = 15;
    }else if (convertedValue <= 30) {
        trueValue = 0;
    }else{
        trueValue = (int)((convertedValue - 30)/15) + 1;
    }
    
    return trueValue;
}

+(NSString *)getIconGraffitikey{
    NSString *graffitiKey;
    switch (DeviceRow) {
        case 12:
        {
            graffitiKey = Graffiti12;
        }
            break;
        case 16:
        {
            if([CurrentDeviceType isEqual:@"CoolLEDM"]){
                
                graffitiKey = Graffiti16;
                
            }else if ([CurrentDeviceType isEqual:@"CoolLEDU"]){
                
                graffitiKey = CoolLEDUGraffiti16;
                
            }
        }
            break;
        case 20:
        {
            if([CurrentDeviceType isEqual:@"CoolLEDM"]){
                
                graffitiKey = Graffiti20;
                
            }else if ([CurrentDeviceType isEqual:@"CoolLEDU"]){
                
                graffitiKey = CoolLEDUGraffiti20;
                
            }
        }
            break;
        case 24:
        {
            if([CurrentDeviceType isEqual:@"CoolLEDM"]){
                
                graffitiKey = Graffiti24;
                
            }else if ([CurrentDeviceType isEqual:@"CoolLEDU"]){
                
                graffitiKey = CoolLEDUGraffiti24;
                
            }
        }
            break;
        case 32:
        {
            if([CurrentDeviceType isEqual:@"CoolLEDM"]){
                
                graffitiKey = Graffiti32;
                
            }else if ([CurrentDeviceType isEqual:@"CoolLEDU"]){
                
                graffitiKey = CoolLEDUGraffiti32;
                
            }
        }
            break;
        default:
            break;
    }
    return graffitiKey;
}

+(NSString *)getIconAnimationkey{
    NSString *animationKey;
    switch (DeviceRow) {
        case 12:
        {
            animationKey = Animation12;
        }
            break;
        case 16:
        {
            if([CurrentDeviceType isEqual:@"CoolLEDM"]){
                
                animationKey = Animation16;
                
            }else if ([CurrentDeviceType isEqual:@"CoolLEDU"]){
                
                animationKey = CoolLEDUAnimation16;
                
            }
        }
            break;
        case 20:
        {
            if([CurrentDeviceType isEqual:@"CoolLEDM"]){
                
                animationKey = Animation20;
                
            }else if ([CurrentDeviceType isEqual:@"CoolLEDU"]){
                
                animationKey = CoolLEDUAnimation20;
                
            }
        }
            break;
        case 24:
        {
            if([CurrentDeviceType isEqual:@"CoolLEDM"]){
                
                animationKey = Animation24;
                
            }else if ([CurrentDeviceType isEqual:@"CoolLEDU"]){
                
                animationKey = CoolLEDUAnimation24;
                
            }
        }
            break;
        case 32:
        {
            if([CurrentDeviceType isEqual:@"CoolLEDM"]){
                
                animationKey = Animation32;
                
            }else if ([CurrentDeviceType isEqual:@"CoolLEDU"]){
                
                animationKey = CoolLEDUAnimation32;
                
            }
        }
            break;
        default:
            break;
    }
    return animationKey;
}

+ (BOOL)isThaiCompositeCharacter:(NSString *)character{
    // 泰语合成字符的Unicode范围
    NSCharacterSet *thaiCompositeSet = [NSCharacterSet characterSetWithRange:NSMakeRange(0x0E00, 0x0E7F - 0x0E00 + 1)];
    return [character rangeOfCharacterFromSet:thaiCompositeSet].location != NSNotFound;
}

+ (BOOL)isHindiCompositeCharacter:(NSString *)character{
    // 印地语合成字符的Unicode范围
    NSCharacterSet *hindiCharacterSet = [NSCharacterSet characterSetWithRange:NSMakeRange(0x0900, 0x097F - 0x0900 + 1)];
    return [character rangeOfCharacterFromSet:hindiCharacterSet].location != NSNotFound;
}

+ (BOOL)isArabicCompositeCharacter:(NSString *)character{
    // 阿拉伯语合成字符的Unicode范围
    NSCharacterSet *arabicCompositeSet = [NSCharacterSet characterSetWithRange:NSMakeRange(0x0600, 0x06FF - 0x0600 + 1)];
    return [character rangeOfCharacterFromSet:arabicCompositeSet].location != NSNotFound;
}

+(NSArray *)generateDataFromImageFont:(int )row text:(NSString *)text fontSize:(int)fontSize languageType:(int)languageTyp isBold:(int)isBold{
    UIImage *image;
 
    CGSize imageSize = CGSizeMake(row, row);
    // 设置文字样式
    UIFont *font =[UIFont fontWithName:@"NSimSun" size:fontSize];
    if(languageTyp == 1){
        font =[UIFont fontWithName:@"NSimSun" size:fontSize];
    }else{
        font =[UIFont fontWithName:@"ArialMT" size:fontSize];
    }
    
//    // 获取所有可用的字体名称
//    NSArray *fontFamilies = [UIFont familyNames];
//    // 遍历字体家族并打印每个字体
//    for (NSString *fontFamily in fontFamilies) {
//        NSArray *fontNames = [UIFont fontNamesForFamilyName:fontFamily];
//
//        NSLog(@"Font Family: %@", fontFamily);
//        for (NSString *fontName in fontNames) {
//            NSLog(@"    %@", fontName);
//        }
//        NSLog(@"\n");
//    }
    
    CGSize textSize = [text sizeWithAttributes:@{NSFontAttributeName: font}];
    //对特殊文字进行适配，文字的宽度大于画布的宽度
    if(textSize.width > imageSize.width) imageSize = CGSizeMake(textSize.width, row);
    CGPoint textOrigin = CGPointMake((imageSize.width - textSize.width) / 2, (imageSize.height - textSize.height) / 2);
    
    CGFloat scale = [[UIScreen mainScreen] scale];
    
    // 开始绘制
    UIGraphicsBeginImageContextWithOptions(imageSize, NO, 1.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // 关闭抗锯齿效果 (如果需要)
    CGContextSetShouldAntialias(context, NO);
    CGContextSetInterpolationQuality(context, kCGInterpolationLow);
    
    // 绘制背景
    [[UIColor blackColor] set];
    CGContextFillRect(context, CGRectMake(0, 0, imageSize.width, imageSize.height));
    
    
    UIColor *textColor = [UIColor redColor];
    CGContextSetLineWidth(context, 1.0); // 设置线宽为 3 个像素
    CGContextSetLineJoin(context, kCGLineJoinMiter);
    CGContextSetLineCap(context, kCGLineCapButt);
    if (!isBold) {
        CGContextSetTextDrawingMode(context, kCGTextFill); // 设置绘制模式为描边
    }else{
        CGContextSetTextDrawingMode(context, kCGTextFillStroke); // 设置绘制模式为描边
    }
    
    [text drawAtPoint:textOrigin withAttributes:@{NSFontAttributeName: font, NSForegroundColorAttributeName: textColor}];
    
    // 获取绘制好的图片
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
        
    NSArray *pixelData = [JTCommon getDataFromFontImage:image scale:1];
    return pixelData;
}

 /**
  *  把输入文字的数据转换为指定大小的文字数据进行输出
  * @param input 输入文字的显示数据
  * @param srcSize 输入文字的大小
  * @param dstSize 输出文字的大小
  * @return 转换后的文字显示数据
  */
// + (NSData *)transferFontData:(NSData *)input srcSize:(NSInteger)srcSize dstSize:(NSInteger)dstSize {
//     if (srcSize >= dstSize) {
//         return input;
//     }
//
//     NSMutableData *data = [NSMutableData dataWithLength:((dstSize + 7) / 8) * dstSize];
//     unsigned char *dataBytes = (unsigned char *)[data mutableBytes];
//     const unsigned char *inputBytes = (const unsigned char *)[input bytes];
//
//     long long temp = 0; // 8字节，可以表示64行了，如果想要支持更大的分辨率，建议用数组，可以任意扩展。
//     for (NSInteger i = 0; i < [input length] / ((srcSize + 7) / 8); i++) {
//         temp = 0;
//
//         // 现在最大分辨率为32，一个int类型够了，不会溢出，如果需要支持更大分辨率的，用long long就好了。
//         for (NSInteger j = 0; j < (srcSize + 7) / 8; j++) {
//             temp <<= 8;
//             temp |= (inputBytes[i * (srcSize + 7) / 8 + j] & 0xFF); // 注意byte有符号，通过于上0xFF变成一个无符号的整数
//         }
//
//         temp <<= ((dstSize - (srcSize + 7) / 8 * 8 - ((srcSize + 7) / 8 * 8 - srcSize)) / 2);
//
//         for (NSInteger j = 0; j < (dstSize + 7) / 8; j++) {
//             dataBytes[i * (dstSize + 7) / 8 + j] = (unsigned char)((temp >> ((dstSize / 8 - 1 - j) * 8)) & 0xFF);
//         }
//     }
//
//     return data;
// }

+ (NSData *)transferFontData:(NSData *)input srcSize:(NSInteger)srcSize dstSize:(NSInteger)dstSize {
    // 输入数据有效性检查
    if (!input || srcSize == 0 || dstSize == 0) {
        return nil; // 或抛出异常
    }

    // 如果目标大小小于等于原始大小，直接返回
    if (srcSize >= dstSize) {
        return input;
    }

    // 计算字节数和预计算值
    NSUInteger srcBytesPerRow = (srcSize + 7) / 8;
    NSUInteger dstBytesPerRow = (dstSize + 7) / 8;

    // 创建输出数据
    NSMutableData *outputData = [NSMutableData dataWithLength:dstBytesPerRow * dstSize];
    uint8_t *outputBytes = (uint8_t *)[outputData mutableBytes];

    // 逐行处理数据
    const uint8_t *inputBytes = (const uint8_t *)[input bytes];
    uint64_t temp = 0;
    for (NSUInteger i = 0; i < [input length] / srcBytesPerRow; i++) {
        temp = 0; // 使用 uint64_t 存储一行数据

        // 读取一行数据
        for (NSUInteger j = 0; j < srcBytesPerRow; j++) {
            temp <<= 8;
            temp |= (inputBytes[i * srcBytesPerRow + j] & 0xFF);
            // 注意byte有符号，通过于上0xFF变成一个无符号的整数
        }

        // 调整对齐
        NSUInteger shiftOffset = ((dstSize - srcBytesPerRow * 8) - (srcBytesPerRow * 8 - srcSize)) / 2;
        temp <<= shiftOffset;

        // 写入一行数据
        for (NSUInteger j = 0; j < dstBytesPerRow; j++) {
            outputBytes[i * dstBytesPerRow + j] = (uint8_t)((temp >> ((dstSize / 8 - 1 - j) * 8)) & 0xFF);
        }
    }

    return outputData;
}

+(NSString *)getTimeTag{
    NSDate *currentDate = [NSDate date];
    NSTimeInterval timestamp = [currentDate timeIntervalSince1970] * 1000; // 转换为毫秒
    NSString *timestampString = [NSString stringWithFormat:@"%.0f", timestamp];
    return timestampString;
}

+(int)getUcolor:(NSArray *)rgbData{
    
    CGFloat red = [rgbData[0] floatValue] ;
    CGFloat green = [rgbData[1] floatValue];
    CGFloat blue = [rgbData[2] floatValue];
    
    int onePixel = [HLUtils colorExchangeFloat:red] * 256 +  [HLUtils colorExchangeFloat:green] * 16 + [HLUtils colorExchangeFloat:blue];

    return onePixel;
}

+(NSArray *)getEmojiDataWith:(NSString *)gifName{
    
    NSURL *urlDefault = [[NSBundle mainBundle] URLForResource:gifName withExtension:@"gif"];
    NSData *gifData = [NSData dataWithContentsOfURL:urlDefault];
    
    NSMutableArray *pixelDataArray = [NSMutableArray array];
    NSDictionary *gifDetail = [JTCommon parseGIFWithData:gifData];
    NSArray *frames = gifDetail[@"frames"];
    NSNumber *delayTime = gifDetail[@"delayTime"];
    for (int j = 0; j<frames.count; j++) {
        UIImage *image = frames[j];
        NSArray *pixelData = [JTCommon getColorDataDefaultFromImage:image scale:1];
        [pixelDataArray addObject:pixelData];
    }
    
    return pixelDataArray[0];
}

+(NSMutableArray *)getPixelRGBArr:(NSArray *)emojiArr{
    NSMutableArray *pixelRGBArr = [[NSMutableArray alloc] init];
    for (int col = 0; col < emojiArr.count; col++) {
        NSMutableArray *rowPixelRGBArr = [[NSMutableArray alloc] init];
        NSArray *rowArr = emojiArr[col];
        for (int row = 0; row < rowArr.count; row++) {
            NSArray *rgbArray = rowArr[row];
            PixelRGB *pixelRGB = [[PixelRGB alloc] init];
            pixelRGB.rgbArr = rgbArray;
            [rowPixelRGBArr addObject:pixelRGB];
        }
        [pixelRGBArr addObject:rowPixelRGBArr];
    }
    return pixelRGBArr;
}

+(NSMutableArray *)getPixelArr:(NSArray *)emojiArr{
    NSMutableArray *pixelRGBArr = [[NSMutableArray alloc] init];
    for (int col = 0; col < emojiArr.count; col++) {
        NSMutableArray *rowPixelRGBArr = [[NSMutableArray alloc] init];
        NSArray *rowArr = emojiArr[col];
        for (int row = 0; row < rowArr.count; row++) {
            NSArray *rgbArray = rowArr[row];
            int isColor = 0;
            for (NSNumber *item in rgbArray) {
                if ([item floatValue] != 0) {
                    isColor = 1;
                    break;
                }
            }
            [rowPixelRGBArr addObject:@(isColor)];
        }
        [pixelRGBArr addObject:rowPixelRGBArr];
    }
    return pixelRGBArr;
}


+(AnimationModel32 *)getBgDataWith:(NSString *)gifNameDefault{
    
    NSURL *urlDefault = [[NSBundle mainBundle] URLForResource:gifNameDefault withExtension:@"gif"];
    NSData *gifData = [NSData dataWithContentsOfURL:urlDefault];
    
    NSMutableArray *pixelDataArray = [NSMutableArray array];
    NSDictionary *gifDetail = [JTCommon parseGIFWithData:gifData];
    NSArray *frames = gifDetail[@"frames"];
    NSNumber *delayTime = gifDetail[@"delayTime"];
    for (int j = 0; j<frames.count; j++) {
        UIImage *image = frames[j];
        NSArray *pixelData = [JTCommon getColorDataDefaultFromImage:image scale:1];
        [pixelDataArray addObject:pixelData];
    }
    
    NSArray *handleShowDataArray =[pixelDataArray copy];
    NSDictionary *dict = @{@"sendData":@[],@"sendDataType":@4,@"showData":@[],@"isChinese":@(NO),@"describe":@""};
    NSMutableDictionary *handleDict = [NSMutableDictionary dictionaryWithDictionary:dict];
    [handleDict setValue:handleShowDataArray forKey:@"handledShowDataArray"];
    [handleDict setValue:@(frames.count) forKey:@"frames"];
    [handleDict setValue:gifNameDefault forKey:@"gifName"];
    // 动画的间隔
    int factValue = (int)([delayTime floatValue] * 1000) ;
    int x = factValue / 256;
    int y = factValue % 256;
    [handleDict setValue:@(x) forKey:@"x"];
    [handleDict setValue:@(y) forKey:@"y"];
    
    NSDictionary *dic = [handleDict copy];
    int timeIntervalAnimation = 256 * x + y;
    
    //生成动画点阵节目对象
    NSMutableArray *animationModel32Arr = [[NSMutableArray alloc] init];
    
    int startCol = 0;
    int widthData = 0;
    int offset = 0;
    
    if (DeviceRow == 16) {
      if (DeviceCol <= 96){
            
          startCol = 0;
          widthData = DeviceCol;
          
      }else{
          
          offset = (DeviceCol - 96)/2;
          startCol = offset;
          widthData = 96;
          
      }
    }

        
    AnimationModel32 *animationModel32 = [JTCommon getAnimationModel32WithCoverType:1 startRow:0 startCol:startCol widthData:widthData heightData:DeviceRow];
    animationModel32.dataAnimation = handleShowDataArray;
    animationModel32.timeIntervalAnimation = timeIntervalAnimation;
    [animationModel32Arr addObject:animationModel32];
    
    return animationModel32;
}

+(NSDictionary *)getDicDetailWithFileName:(NSString *)fileName{
    NSString *jsonPath = [[NSBundle mainBundle] pathForResource:fileName ofType:@"jt"];
    NSData *fileData = [[NSData alloc] initWithContentsOfFile:jsonPath];
    NSArray *jsonArr = [NSJSONSerialization JSONObjectWithData:fileData options:0 error:nil];
    
    NSDictionary *shareDataDict = [[NSDictionary alloc] init];
    for (int i = 0; i < jsonArr.count; i++) {
        shareDataDict = jsonArr[0];
        NSNumber *dataType = shareDataDict[@"dataType"];
        
        if([dataType intValue] == 0){
            //动画
            NSDictionary *dataDict = shareDataDict[@"data"];
            NSNumber *aniType = dataDict[@"aniType"];
            NSNumber *pixelHeight = dataDict[@"pixelHeight"];
            NSNumber *pixelWidth = dataDict[@"pixelWidth"];
            NSNumber *frameNum = dataDict[@"frameNum"];
            NSNumber *delays = dataDict[@"delays"];
            NSArray *aniData = dataDict[@"aniData"];
            
        }
    }
    return shareDataDict;
}

+ (uint8_t)combineBits:(BOOL[8])bits {
    uint8_t byte = 0;
    for (int i = 0; i < 8; i++) {
        if (bits[i]) {
            byte |= (1 << i); // 将相应的比特位置为 1
        }
    }
    return byte;
}

+ (NSArray *)horizontalMirror:(NSArray *)matrix {
    NSMutableArray *mirroredMatrix = [NSMutableArray arrayWithCapacity:matrix.count];
    
    for (NSArray *row in matrix) {
        NSArray *mirroredRow = [[row reverseObjectEnumerator] allObjects];
        [mirroredMatrix addObject:mirroredRow];
    }
    
    return [mirroredMatrix copy];
}

+ (NSArray *)verticalMirror:(NSArray *)matrix {
    return [[matrix reverseObjectEnumerator] allObjects];
}

+ (NSArray *)generateNumbersUpTo:(NSInteger)max withMultiple:(NSInteger)m {
    NSMutableArray *resultArray = [NSMutableArray array];
    
    for (NSInteger i = max; i >= 1; i--) {
        if (i == 1 || i == max) {
            [resultArray addObject:@(i)]; // 添加 1 和 max
        }
        if (i % m == 0) {
            [resultArray addObject:@(i)]; // 添加 m 的倍数
        }
    }
    
    // 去重
    NSSet *uniqueSet = [NSSet setWithArray:resultArray];
    NSArray *uniqueArray = [uniqueSet allObjects];
    
    // 倒序排序
    NSArray *sortedArray = [uniqueArray sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj2 compare:obj1]; // 倒序比较
    }];
    
    return sortedArray;
}

//promptItemType用于标识发送节目提示0、默认，1、同步状态，2、发送
+(void)showPromptItemRank:(int)itemRank{
    // For Mobill app from Claude Code, skip showing HUD as it interferes with the new UI flow
    if ([[NSBundle mainBundle].bundleIdentifier containsString:@"mobill"]) {
        NSLog(@"🚫 Skipping HUD for Mobill app");
        return;
    }
    
    if(applicationSelf.notificationKey == NotificationKeySetView32){
        [HLHUDHelper showLoadingWithTitle:[NSString stringWithFormat:@"%@",showText(@"发送")] detailText:@"0%"];
    }else{
        switch ([ThemManager sharedInstance].promptItemType) {
            case 0:
                [HLHUDHelper showLoadingWithTitle:[NSString stringWithFormat:@"%@%@%d ",showText(@"发送"),showText(@"节目"),itemRank + 1] detailText:@"0%"];
                break;
            case 1:
                [HLHUDHelper showLoadingWithTitle:[NSString stringWithFormat:@"%@",showText(@"同步状态中...")] detailText:@"0%"];
                break;
            case 2:
                [HLHUDHelper showLoadingWithTitle:[NSString stringWithFormat:@"%@",showText(@"发送")] detailText:@"0%"];
                break;
            default:
                break;
        }
    }
}

+(NSString *)reverseAndSwapPairs:(NSString *)input{
    NSMutableString *result = [NSMutableString string];
    NSInteger length = input.length;
    
    // 确保输入字符串长度是偶数，否则提示错误或处理最后一位
    if (length % 2 != 0) {
        NSLog(@"输入字符串长度不是偶数，无法正确处理！");
        return nil;
    }
    
    // 每两个字符一组，从后往前遍历
    for (NSInteger i = length - 2; i >= 0; i -= 2) {
        NSString *twoChars = [input substringWithRange:NSMakeRange(i, 2)];
        [result appendString:twoChars];
    }
    
    return result;
}

+(NSString *)reverseStringByFourCharacters:(NSString *)input {
    NSMutableString *result = [NSMutableString string];
    NSInteger length = input.length;
    
    // 确保输入字符串长度是4的倍数
    if (length % 4 != 0) {
        NSLog(@"输入字符串长度不是4的倍数，无法正确处理！");
        return nil;
    }
    
    // 每四个字符一组，从后往前遍历
    for (NSInteger i = length - 4; i >= 0; i -= 4) {
        NSString *fourChars = [input substringWithRange:NSMakeRange(i, 4)];
        [result appendString:fourChars];
    }
    
    return result;
}

@end
