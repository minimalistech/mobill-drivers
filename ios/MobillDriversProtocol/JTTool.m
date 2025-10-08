//
//  JTTool.m
//  CoolLED1248
//
//  Created by 君同 on 2023/3/13.
//  Copyright © 2023 Haley. All rights reserved.
//

#import "JTTool.h"

@implementation JTTool

#pragma mark - 拼接节目命令

#pragma mark - 发送命令

//开始设置节目内容
+(void)startItemContentCommand:(ColorItemModel32 *)colorItemModel32 itemRank:(int)itemRank itemTotalCount:(int)itemTotalCount onDevice:(GWPeripheral *)peripheralModel{
    //1.设置节目内容
    NSString *sendItem = [JTTool getItemTotalContent:colorItemModel32];
    
    //未经过压缩之前的数据
    NSData *sendItemData = [HLUtils stringToData:sendItem];
    
    //2.发送开始设置节目内容命令
    [JTTool startItemContentCommand:sendItemData lenght:(int)(sendItem.length/2) itemRank:itemRank itemTotalCount:itemTotalCount itemShowTime:colorItemModel32.itemShowTime onDevice:peripheralModel];
}

//开始设置行驶内容
+(void)startDriveItemContentCommand:(ColorItemModel32 *)colorItemModel32 state:(int)state  onDevice:(GWPeripheral *)peripheralModel{
    //1.设置节目内容
    NSString *sendItem = [JTTool getItemTotalContent:colorItemModel32];
    
    //未经过压缩之前的数据
    NSData *sendItemData = [HLUtils stringToData:sendItem];
    
    //2.发送开始设置节目内容命令
    [JTTool startItemContentCommand:sendItemData lenght:(int)(sendItem.length/2) state:state  onDevice:peripheralModel];
}

//设置节目内容
+(void)setItemContentCommand:(ColorItemModel32 *)colorItemModel32 itemRank:(int)itemRank VCType:(int)VCType onDevice:(GWPeripheral *)peripheralModel{
    //1.设置节目内容
    NSString *sendItem = [JTTool getItemTotalContent:colorItemModel32];
    
    //未经过压缩之前的数据
    NSData *sendItemData = [HLUtils stringToData:sendItem];
    
    //3.发送设置节目内容命令
    [JTTool sendSetItemContentCommand:sendItemData itemRank:itemRank VCType:(int)VCType onDevice:peripheralModel];
}

//拼接命令-开始设置节目内容命令
+(void)startItemContentCommand:(NSData *)sendItemData lenght:(int)lenght itemRank:(int)itemRank itemTotalCount:(int)itemTotalCount itemShowTime:(int)itemShowTime onDevice:(GWPeripheral *)peripheralModel{
    NSDate *currentDate = [NSDate date];
    NSTimeInterval timestamp = [currentDate timeIntervalSince1970] * 1000; // 转换为毫秒
    NSString *timestampString = [NSString stringWithFormat:@"%.0f", timestamp];
    
    NSString *setSendItem = @"";
    
    // 1.拼接4个字节节目数据的 32 位 CRC校验值（未经过压缩之前的的校验值）
    setSendItem = [setSendItem stringByAppendingFormat:@"%08x",[Crc32Algorithm getCrc32CheckCode:sendItemData]];
    
    // 2.拼接4个字节节目数据的长度（未经过压缩之前的长度）
    setSendItem = [setSendItem stringByAppendingFormat:@"%08x",lenght];
    
    // 3.拼接1个字节当前节目在本次需要发送的节目列表中的顺序位置
    setSendItem = [setSendItem stringByAppendingFormat:@"%02x",itemRank];
    
    // 4.拼接1个字节总共会发送多少个节目
    setSendItem = [setSendItem stringByAppendingFormat:@"%02x",itemTotalCount];
    
    //发送开始设置节目内容的命令
    NSString *lengthString = @"";
    if ([[ThemManager sharedInstance].peripheralName isEqualToString:@"CoolLEDUX"]) {
        // 5.拼接1个字节节目播放次数，在有多个节目的情况下，显示多少次后切换到下一个节目
        setSendItem = [setSendItem stringByAppendingFormat:@"%02x",itemShowTime];
        //发送开始设置节目内容的命令
        lengthString = @"000C";
    }else{
        lengthString = @"000B";
    }
    
    NSString *dataString = [NSString stringWithFormat:@"%@02%@",lengthString,setSendItem];
    NSString *setSendItemCommond = [NSString finalDataWith:dataString];
    [[HLBluetoothManager standardManager] writeCommand:setSendItemCommond onDevice:peripheralModel];
    
    NSDate *currentDateEnd = [NSDate date];
    NSTimeInterval timestampEnd = [currentDateEnd timeIntervalSince1970] * 1000; // 转换为毫秒
    NSString *timestampStringEnd = [NSString stringWithFormat:@"%.0f", timestampEnd];
}

//拼接命令-开始设置行驶内容
+(void)startItemContentCommand:(NSData *)sendItemData lenght:(int)lenght state:(int)state  onDevice:(GWPeripheral *)peripheralModel{
    
    NSString *setSendItem = @"";
    
    // 1.拼接4个字节节目数据的 32 位 CRC校验值（未经过压缩之前的的校验值）
    setSendItem = [setSendItem stringByAppendingFormat:@"%08x",[Crc32Algorithm getCrc32CheckCode:sendItemData]];
    
    // 2.拼接4个字节节目数据的长度（未经过压缩之前的长度）
    setSendItem = [setSendItem stringByAppendingFormat:@"%08x",lenght];
    
    // 3.拼接1个字节需要修改的行驶内容对应的状态
    setSendItem = [setSendItem stringByAppendingFormat:@"%02x",state];
    
    //发送开始设置节目内容的命令
    NSString *lengthString = @"000A";
    NSString *dataString = [NSString stringWithFormat:@"%@1A%@",lengthString,setSendItem];
    NSString *setSendItemCommond = [NSString finalDataWith:dataString];
    [[HLBluetoothManager standardManager] writeCommand:setSendItemCommond onDevice:peripheralModel];
}

//发送设置节目内容命令
+(void)sendSetItemContentCommand:(NSData *)sendItemData itemRank:(int)itemRank VCType:(int)VCType onDevice:(GWPeripheral *)peripheralModel{
    //采用Less算法对该数据先进行压缩
    LzssAlgorithm *lzssAlgorithm = [[LzssAlgorithm alloc] init];
    
    NSData *resultData = [lzssAlgorithm lzssEncode:sendItemData];
    
    //压缩后把Data转化为string
    NSString *result = [HLUtils dataToString:resultData];
    
    
    int type = 3;
    NSArray *packageCommands = [NSString getPackageCommandsWithDataString:result type:type fontsType:32];
    if (packageCommands.count == 0) {
        return;
    }
    
    [GWPeripheral sendPackageCommands:packageCommands itemRank:itemRank VCType:VCType onDevice:peripheralModel];
}

//OTA 开始升级
+(void)StartFirmwareUpgrade:(NSData *)sendItemData lenght:(int)lenght  onDevice:(GWPeripheral *)peripheralModel{
    
    NSString *setSendItem = @"";
    
    // 1.拼接4个字节节目数据的 32 位 CRC校验值（未经过压缩之前的的校验值）
    setSendItem = [setSendItem stringByAppendingFormat:@"%08x",[Crc32Algorithm getCrc32CheckCode:sendItemData]];
    
    // 2.拼接4个字节节目数据的长度（未经过压缩之前的长度）
    setSendItem = [setSendItem stringByAppendingFormat:@"%08x",lenght];
    
    //发送开始设置节目内容的命令
    if ([[ThemManager sharedInstance].peripheralName isEqualToString:@"CoolLEDU"]){
        
        NSString *lengthString = @"0009";
        NSString *dataString = [NSString stringWithFormat:@"%@FE%@",lengthString,setSendItem];
        NSString *setSendItemCommond = [NSString finalDataWith:dataString];
        [[HLBluetoothManager standardManager] writeCommand:setSendItemCommond onDevice:peripheralModel];
          
    }else if([[ThemManager sharedInstance].peripheralName isEqualToString:@"CoolLEDUX"]){
        
       
        NSString *fileNameStr = [[NSUserDefaults standardUserDefaults] objectForKey:JTScreenfileNameStrOTA];

        NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject;
        NSURL *binURL = [NSURL URLWithString:[NSString stringWithFormat:@"file://%@/%@/%@",path,fileNameStr,fileNameStr]];
        NSData *binData = [NSData dataWithContentsOfURL:binURL];
        
        NSUInteger length = MIN(64, binData.length);
        const unsigned char *bytes = binData.bytes;

        // 创建一个字节数组并填充数据
        NSString *byteStr = @"";
        NSMutableArray *byteArray = [NSMutableArray arrayWithCapacity:length];
        for (NSUInteger i = 0; i < length; i++) {
            [byteArray addObject:@(bytes[i])];
            byteStr = [byteStr stringByAppendingFormat:@"%02x",bytes[i]];
        }
        // 3.拼接1个字节OTA 升级文件开头的指定字节数
        setSendItem = [setSendItem stringByAppendingFormat:@"%02x",64];
        // 4.拼接64个字节OTA 升级文件开头的指定字节数据
        setSendItem = [setSendItem stringByAppendingString:byteStr];
        
        NSString *lengthString = @"004A";
        NSString *dataString = [NSString stringWithFormat:@"%@FE%@",lengthString,setSendItem];
        NSString *setSendItemCommond = [NSString finalDataWith:dataString];
        [[HLBluetoothManager standardManager] writeCommand:setSendItemCommond onDevice:peripheralModel];
        
    }
    
}

//OTA 传输数据
+(void)firmwareUpgrade:(NSData *)sendItemData itemRank:(int)itemRank VCType:(int)VCType onDevice:(GWPeripheral *)peripheralModel{
    
    //采用Less算法对该数据先进行压缩
    LzssAlgorithm *lzssAlgorithm = [[LzssAlgorithm alloc] init];
    
    NSData *resultData = [lzssAlgorithm lzssEncode:sendItemData];
    
    //压缩后把Data转化为string
    NSString *result = [HLUtils dataToString:resultData];
    
    
    int type = 0xFF;
    NSArray *packageCommands = [NSString getPackageCommandsWithDataString:result type:type fontsType:32];
    if (packageCommands.count == 0) {
        return;
    }
    
    [GWPeripheral sendPackageCommands:packageCommands itemRank:itemRank VCType:VCType onDevice:peripheralModel];
}

+(void)saveGifFromServer:(NSString *)gifName fileName:(NSString *)fileName data:(NSData *)gifData{
    // 获取Documents目录路径
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    
    NSString *folderPath = [documentsDirectory stringByAppendingPathComponent:fileName];
    

    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDirectory;
    BOOL folderExists = [fileManager fileExistsAtPath:folderPath isDirectory:&isDirectory];

    if (folderExists && isDirectory) {
        NSError *error;
        folderPath = [folderPath stringByAppendingPathComponent:gifName];
        BOOL success = [gifData writeToFile:folderPath options:NSDataWritingAtomic error:&error];
        if (success) {
        }else {
        }
    } else {

        // 创建文件夹
        NSError *error = nil;
        
        [[NSFileManager defaultManager] createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:&error];

        if (error) {
        } else {
            
            // 将NSData写入文件
            NSError *error;
            folderPath = [folderPath stringByAppendingPathComponent:gifName];
            BOOL success = [gifData writeToFile:folderPath options:NSDataWritingAtomic error:&error];
            if (success) {
            } else {
            }
        }
    }
}

//A.设置节目内容-文字内容数据格式
+(NSDictionary *)getItemWordContent:(ColorTextModel32 *)textModel deviceCols:(int)deviceCols isLargeEdge:(BOOL)isLargeEdge{


    int wordsLenght; // 拼接2个字节所有文字所占宽度之和
    NSString *wordsWidth = @""; // 拼接n个字节每个文字所占宽度的集合
    NSString *wordsColor = @""; // 拼接n个字节每个文字的颜色集合
    
    // N 个文字所占宽度,
    //第 N 个文字的类型标识( 0-表示为单色文字， 1-表示为多色文字表情 ),
    //第 N 个文字的显示数据,如果为单色文字，只需要显示数据,如果为多色文字（表情）， 则按照涂鸦方式表示该文字数据。
    NSMutableArray *wideN = [[NSMutableArray alloc] init]; //宽度数组
    NSMutableArray *typeN = [[NSMutableArray alloc] init]; //标识数组
    NSMutableArray *dataN = [[NSMutableArray alloc] init]; //显示数据数组
    
    NSString *wideTypeDataTotal = @"";
    
    
    NSArray *textItems = textModel.textItems;
    
    if (textModel.fontSpace == 0) textModel.fontSpace = 1;
    
    textModel = [JTCommon getDefaultFontType:textModel isLargeEdge:isLargeEdge];
    int currentFont = textModel.font == 0 ?  textModel.fontDefaultFit : textModel.font;
    NSData *unicodeData = [JTCommon getFontTypeFont:currentFont bold:textModel.bold];
    
    // 0-2.旋转的度数
    int degree = textModel.degree * 90;
    
    int modeType = textModel.showModel;
    // 0-3 是否需要优化文字，解决文字截断问题
    BOOL needOpt = YES;
    if (modeType == 2 || modeType == 3) {
        needOpt = NO;
    }
    
    // 文字点阵数据
    NSString *sumCheckedString = @"";
    
    int currentDeviceCols = deviceCols ;
    int sumCols = 0;
    
    // 单个数据点阵
    NSString *checkedString = @"";
    NSMutableArray *checkedSumM = [NSMutableArray array];

    // Use index-based iteration instead of fast enumeration to avoid modification issues
    for (NSInteger textItemIndex = 0; textItemIndex < textItems.count; textItemIndex++) {
        HLColorTextItem *textItem = textItems[textItemIndex];
        NSMutableArray *dataS = [[NSMutableArray alloc] init]; //单个数据，单色为1个元素、多色多维数组
        //32设备只支持文字
        
        if(![textItem.text isEqual:@"\n"]){

            NSArray *latticeArray = [[NSArray alloc] init];

            if (textItem.itemType == HLTextItemTypeText) {
                //取文字
                if (textModel.heightData == 48 && currentFont == 48) {
                    //大屏48采用绘制文字
                    //测试通用采取绘制字库
                    latticeArray = [HLUtils generateDataFromImageFont:textModel.heightData text:textItem.text fontSize:currentFont languageType:textItem.languageType isBold:textModel.bold];
                    int n = (int)latticeArray.count;
                    NSArray *arr0 = latticeArray[0];
                    int p =(int)arr0.count;
                    if(n > p && (degree == 90 || degree == 270))degree = 0;
                    latticeArray = [HLUtils rotateArray:latticeArray degree:degree];
                }else{
                    //采取字库
                    if (textItem.languageType == 0) {
                        int asciiCode = [textItem.text characterAtIndex:0];
                        NSData *originData = [JTCommon getOriginDataWordShowHeight:textModel.heightData asciiCode:asciiCode font:currentFont unicodeData:unicodeData degree:degree];

                        // Safety check for empty font data
                        if (originData.length == 0) {
                            // Create a minimal fallback data or skip this character
                            latticeArray = @[]; // Empty array as fallback
                        } else {
                            // 1.将文字数据转换为点阵数据
                            latticeArray = textModel.heightData == 16 ? [HLUtils arrayWithOriginData:originData]: [HLUtils arrayWithOriginData:originData wordShowHeight:textModel.heightData] ;
                        }
                    }else{
                        //以及部分多语言适配
                        int row  = textModel.heightData;
                        latticeArray = [HLUtils generateDataFromImageFont:row text:textItem.text fontSize:currentFont languageType:textItem.languageType isBold:NO];
                        int n = (int)latticeArray.count;
                        NSArray *arr0 = latticeArray[0];
                        int p =(int)arr0.count;
                        if(n > p && (degree == 90 || degree == 270))degree = 0;
                        latticeArray = [HLUtils rotateArray:latticeArray degree:degree];
                    }
                    
                }

                // Safety check for empty latticeArray before processing
                if (latticeArray.count == 0) {
                    continue; // Skip this character and move to next one
                }


                // Add safety check for latticeArray structure
                if (latticeArray.count > 0) {
                    id firstElement = latticeArray[0];
                    if ([firstElement isKindOfClass:[NSArray class]]) {
                        NSArray *firstRow = (NSArray *)firstElement;
                    } else {
                    }
                }

                // 3.优化点阵数据，加空列，或返回6个空列
                @try {
                    latticeArray = textModel.heightData == 16 ? [HLUtils optArrayWithLatticeArray:latticeArray fontSpace:textModel.fontSpace fontSize:currentFont] : [HLUtils optArrayWithLatticeArray:latticeArray wordShowHeight:textModel.heightData fontSpace:textModel.fontSpace fontSize:currentFont];
                } @catch (NSException *exception) {
                    // Use a fallback - empty lattice array
                    latticeArray = @[];
                }

                @try {
                    checkedString = [NSString checkedStringWithLatticeArray:latticeArray];
                } @catch (NSException *exception) {
                    // Use a fallback - empty string
                    checkedString = @"";
                }
                

                [typeN addObject:@"00"];

                [dataS addObject:checkedString];

                [dataN addObject:dataS];
                
            }else{
                
                
                if ([[ThemManager sharedInstance].peripheralName isEqualToString:@"CoolLEDMX"]) {
                    
                    //取表情
                    NSDictionary *emojiDict = textItem.emojiDict;
                    NSString *json;
                    switch (currentFont) {
                        case 12:
                            json = emojiDict[@"json1212"];
                            break;
                        case 14:
                            json = emojiDict[@"json1414"];
                            break;
                        case 16:
                            json = emojiDict[@"json"];
                            break;
                        default:
                            break;
                    }
                    NSString *jsonPath = [[NSBundle mainBundle] pathForResource:json ofType:@"json"];
                    NSData *emojiData = [[NSData alloc] initWithContentsOfFile:jsonPath];
                    NSDictionary *localDict = [NSJSONSerialization JSONObjectWithData:emojiData options:0 error:nil];
                    NSArray *animationData = localDict[@"animationData"];

                    int length = (int)(animationData.count / 3);
                    // 处理红色数据
                    NSArray *redArray = [animationData subarrayWithRange:NSMakeRange(0, length)];
                    // 处理绿色数据
                    NSArray *greenArray = [animationData subarrayWithRange:NSMakeRange(length, length)];
                    // 处理蓝色数据
                    NSArray *blueArray = [animationData subarrayWithRange:NSMakeRange(length * 2, length)];
                
                    NSData *reddata = [HLUtils arrayToByte:redArray];
                    reddata = [JTCommon getOriginDataWordShowHeight:textModel.heightData font:currentFont emojiData:reddata degree:degree];
                    NSArray *redLatticeArray = textModel.heightData == 16 ? [HLUtils arrayWithOriginData:reddata]: [HLUtils arrayWithOriginData:reddata wordShowHeight:textModel.heightData] ;
                    
                    // 3.优化点阵数据，加空列，或返回6个空列
                    NSArray *emptyColArray = [HLUtils emptyColArrayWith:@(0) rows:textModel.heightData];
                    for (int i = 0; i < textModel.fontSpace; i++) {
                        redLatticeArray = [redLatticeArray arrayByAddingObject:emptyColArray];
                    }
                    
                    NSData *greendata = [HLUtils arrayToByte:greenArray];
                    greendata = [JTCommon getOriginDataWordShowHeight:textModel.heightData font:currentFont emojiData:greendata degree:degree];
                    NSArray *greenLatticeArray = textModel.heightData == 16 ? [HLUtils arrayWithOriginData:greendata]: [HLUtils arrayWithOriginData:greendata wordShowHeight:textModel.heightData] ;
                    
                    // 3.优化点阵数据，加空列，或返回6个空列
                    for (int i = 0; i < textModel.fontSpace; i++) {
                        greenLatticeArray = [greenLatticeArray arrayByAddingObject:emptyColArray];
                    }
                    
                    NSData *bluedata = [HLUtils arrayToByte:blueArray];
                    bluedata = [JTCommon getOriginDataWordShowHeight:textModel.heightData font:currentFont emojiData:bluedata degree:degree];
                    NSArray *blueLatticeArray = textModel.heightData == 16 ? [HLUtils arrayWithOriginData:bluedata]: [HLUtils arrayWithOriginData:bluedata wordShowHeight:textModel.heightData] ;
                    
                    // 3.优化点阵数据，加空列，或返回6个空列
                    for (int i = 0; i < textModel.fontSpace; i++) {
                        blueLatticeArray = [blueLatticeArray arrayByAddingObject:emptyColArray];
                    }
                    
                    checkedString = [NSString checkedStringWithLatticeArray:redLatticeArray];
                    
                    NSString *checkedRedString = [NSString checkedStringWithLatticeArray:redLatticeArray];
                    NSString *checkedgreenString = [NSString checkedStringWithLatticeArray:greenLatticeArray];
                    NSString *checkedBlueString = [NSString checkedStringWithLatticeArray:blueLatticeArray];
                    
                    [typeN addObject:@"01"];
                    [dataS addObject:checkedRedString];
                    [dataS addObject:checkedgreenString];
                    [dataS addObject:checkedBlueString];
                    [dataN addObject:dataS];
                }else if ([[ThemManager sharedInstance].peripheralName isEqualToString:@"CoolLEDUX"]) {
                    
                    //取表情
                    NSDictionary *emojiDict = textItem.emojiDict;
                    NSString *gifName;
                    switch (currentFont) {
                        case 12:
                            gifName = emojiDict[@"json1212"];
                            break;
                        case 14:
                            gifName = emojiDict[@"json1414"];
                            break;
                        case 16:
                            gifName = emojiDict[@"json"];
                            break;
                        default:
                            break;
                    }
                    NSArray *emojiArr= [HLUtils getEmojiDataWith:gifName];
                    
                    NSMutableArray *pixelRGBArr =[HLUtils getPixelRGBArr:emojiArr];
                    
                    emojiArr = [JTCommon getEmojiArrTransformShowHeight:textModel.heightData font:currentFont emojiArr:emojiArr degree:degree];
                    
                    // 3.优化点阵数据，加空列，或返回6个空列
                    NSArray *emptyColArray = [HLUtils emptyColArrayWith:@[@0,@0,@0] rows:textModel.heightData];
                    for (int i = 0; i < textModel.fontSpace; i++) {
                        emojiArr = [emojiArr arrayByAddingObject:emptyColArray];
                    }
                    
                    NSArray *latticeArray = [HLUtils getPixelArr:emojiArr];
                    
                    checkedString = [NSString checkedStringWithLatticeArray:latticeArray];
                    
                    NSString *emojiStr = @"";
                    
                    for (int i = 0; i < emojiArr.count; i++) {
                        NSArray *cols = emojiArr[i];
                        
                        NSString *colStr = @"";
                        for (int j = 0; j < cols.count; j++) {
                            NSArray *rgbData = cols[j];
                            
                            CGFloat red = [rgbData[0] floatValue] ;
                            CGFloat green = [rgbData[1] floatValue];
                            CGFloat blue = [rgbData[2] floatValue];
                            
                            NSString *onePixel = @"";
                            onePixel = [onePixel stringByAppendingFormat:@"%02x", [HLUtils colorExchangeFloat:red]];
                            onePixel = [onePixel stringByAppendingFormat:@"%02x", [HLUtils colorExchangeFloat:green]* 16 + [HLUtils colorExchangeFloat:blue]];
                            
                            colStr = [colStr stringByAppendingString:onePixel];
                        }
                        emojiStr = [emojiStr stringByAppendingString:colStr];
                    }
                    
                    [typeN addObject:@"01"];
                    [dataS addObject:emojiStr];
                    [dataN addObject:dataS];
                }else{
                    
                    NSDictionary *emojiDict = textItem.emojiDict;
                    NSString *json;
                    switch (currentFont) {
                        case 12:
                            json = emojiDict[@"json1212"];
                            break;
                        case 14:
                            json = emojiDict[@"json1414"];
                            break;
                        case 16:
                            json = emojiDict[@"json1616"];
                            break;
                        case 20:
                            json = emojiDict[@"json2020"];
                            break;
                        case 24:
                            json = emojiDict[@"json2424"];
                            break;
                        case 32:
                            json = emojiDict[@"json3232"];
                            break;
                        case 48:
                            json = emojiDict[@"json4848"];
                            break;
                        default:
                            break;
                    }
                    
                    NSString *jsonPath = [[NSBundle mainBundle] pathForResource:json ofType:@"json"];
                    NSData *emojiData = [[NSData alloc] initWithContentsOfFile:jsonPath];
                    
                    NSDictionary *localDict = [NSJSONSerialization JSONObjectWithData:emojiData options:0 error:nil];
                    NSArray *animationData = localDict[@"animationData"];
                    int length = (int)(animationData.count);
                    // 处理红色数据
                    NSArray *redArray = [animationData subarrayWithRange:NSMakeRange(0, length)];
                    
                    NSData *reddata = [HLUtils arrayToByte:redArray];
                    reddata = [JTCommon getOriginDataWordShowHeight:textModel.heightData font:currentFont emojiData:reddata degree:degree];
                    latticeArray = textModel.heightData == 16 ? [HLUtils arrayWithOriginData:reddata]: [HLUtils arrayWithOriginData:reddata wordShowHeight:textModel.heightData] ;
                    
                    // 3.优化点阵数据，加空列，或返回6个空列
                    latticeArray = textModel.heightData == 16 ? [HLUtils optArrayWithLatticeArray:latticeArray fontSpace:textModel.fontSpace fontSize:currentFont] : [HLUtils optArrayWithLatticeArray:latticeArray wordShowHeight:textModel.heightData fontSpace:textModel.fontSpace fontSize:currentFont];
                    
                    checkedString = [NSString checkedStringWithLatticeArray:latticeArray];
                    
                    [typeN addObject:@"01"];
                    [dataS addObject:checkedString];
                    [dataN addObject:dataS];
                    
                }
            }
            
            if (needOpt) {

                //32一列4个字节，16一列2个字节，24一列3个字节
                int oneWordCols = checkedString.length * [JTCommon ratioStringByte:textModel.heightData];
                if ((sumCols + oneWordCols) > currentDeviceCols && sumCols != 0) {

                    NSDictionary *result = [self makeWordCenter:sumCheckedString currentDeviceCols:currentDeviceCols wordShowHeight:textModel.heightData wordsWidth:wordsWidth wideN:wideN typeN:typeN dataN:dataN wordsColor:wordsColor checkedSumM:checkedSumM isMirror:textModel.isMirror];
                    sumCheckedString = result[@"sumCheckedString"];
                    wordsWidth = result[@"wordsWidth"];
                    wordsColor = result[@"wordsColor"];
                    checkedSumM = result[@"checkedSumM"];
                    
                    sumCols = oneWordCols;
                } else {
                    sumCols += oneWordCols;
                 }
            }
            
            //为自定义颜色效果计算相关参数
            // 每个文字对应的点阵数据所占的列数
            int currentLength = (int)(checkedString.length * [JTCommon ratioStringByte:textModel.heightData]);
            NSString *hexValue = [NSString stringWithFormat:@"%02x", currentLength];
            if (hexValue.length % 2 != 0) {
                hexValue = [NSString stringWithFormat:@"0%@", hexValue];
            }
            wordsWidth = [wordsWidth stringByAppendingFormat:@"%@", hexValue];
            wordsColor = [wordsColor stringByAppendingString: [JTCommon getWordColorFrom:textItem.rgbString]];
            
            sumCheckedString = [sumCheckedString stringByAppendingString:checkedString];
            [checkedSumM addObjectsFromArray:latticeArray];
            
            [wideN addObject:[NSString stringWithFormat:@"%02x", currentLength]];
            
        }else{
            
            if (needOpt) {
                NSDictionary *result = [self makeWordCenter:sumCheckedString currentDeviceCols:currentDeviceCols wordShowHeight:textModel.heightData wordsWidth:wordsWidth wideN:wideN typeN:typeN dataN:dataN wordsColor:wordsColor checkedSumM:checkedSumM isMirror:textModel.isMirror];
                sumCheckedString = result[@"sumCheckedString"];
                wordsWidth = result[@"wordsWidth"];
                wordsColor = result[@"wordsColor"];
                checkedSumM = result[@"checkedSumM"];
                sumCols = 0;
            }
            //为自定义颜色效果计算相关参数
            // 每个文字对应的点阵数据所占的列数
            int currentLength = (int)(checkedString.length * [JTCommon ratioStringByte:textModel.heightData]);
            wordsWidth = [wordsWidth stringByAppendingFormat:@"%02x", currentLength];
            wordsColor = [wordsColor stringByAppendingString: [JTCommon getWordColorFrom:textItem.rgbString]];
            
            sumCheckedString = [sumCheckedString stringByAppendingString:checkedString];
            
            [typeN addObject:@"00"];
            [wideN addObject:[NSString stringWithFormat:@"%02x", currentLength]];
            [dataS addObject:checkedString];
            [dataN addObject:dataS];
            
        }
    }


    // 让最后一屏文字居中
    if (needOpt) {
        @try {
            NSDictionary *result = [self makeWordCenter:sumCheckedString currentDeviceCols:currentDeviceCols wordShowHeight:textModel.heightData wordsWidth:wordsWidth wideN:wideN typeN:typeN dataN:dataN wordsColor:wordsColor checkedSumM:checkedSumM isMirror:textModel.isMirror];
            sumCheckedString = result[@"sumCheckedString"];
            wordsWidth = result[@"wordsWidth"];
            wordsColor = result[@"wordsColor"];
            checkedSumM = result[@"checkedSumM"];
        } @catch (NSException *exception) {
            // Continue with existing data if makeWordCenter fails
        }
        
    }else{

        if (textModel.isMirror) {
            @try {
                checkedSumM = [[HLUtils verticalMirror:checkedSumM] mutableCopy];

                sumCheckedString = [NSString checkedStringWithLatticeArray:checkedSumM];

                wordsWidth = [HLUtils reverseAndSwapPairs:wordsWidth];

                if([CurrentDeviceType isEqual:@"CoolLEDM"]){
                    wordsColor = [HLUtils reverseAndSwapPairs:wordsColor];
                }else if([CurrentDeviceType isEqual:@"CoolLEDU"]){
                    wordsColor = [HLUtils reverseStringByFourCharacters:wordsColor];
                }
            } @catch (NSException *exception) {
                // Continue with existing data if mirror fails
            }
        }
        
    }
    
    //为自定义颜色效果计算相关参数
    wordsLenght = (int)(sumCheckedString.length * [JTCommon ratioStringByte:textModel.heightData]);
    
    NSString *sendText = @"";
    
    // 1.拼接1个字节表示该内容的类型
    sendText = [sendText stringByAppendingString:@"01"];
    
    // 2.拼接7个字节预留字节
    for (int i = 0; i < 7; i++) {
        sendText = [sendText stringByAppendingString:@"00"];
    }
    
    // 3.拼接1个字节该内容显示的时候，和其他层级的内容的混合方式
    sendText = [sendText stringByAppendingFormat:@"%02x", textModel.coverType];
    
    // 4.拼接2个字节该内容显示起始列
    sendText = [sendText stringByAppendingFormat:@"%04x",textModel.startCol];
    
    // 5.拼接2个字节该内容显示起始行
    sendText = [sendText stringByAppendingFormat:@"%04x",textModel.startRow];
    
    // 6.拼接2个字节该内容显示宽度
    sendText = [sendText stringByAppendingFormat:@"%04x",textModel.widthData];
    
    // 7.拼接2个字节该内容显示高度
    sendText = [sendText stringByAppendingFormat:@"%04x",textModel.heightData];
    
    // 8.拼接1个字节显示模式
    sendText = [sendText stringByAppendingFormat:@"%02x",textModel.showModel];
    
    // 9.拼接1个字节显示速度（显示模式的对应速度）
    //+239解决速度变化非线性，前期滑动速度不明显
    sendText = [sendText stringByAppendingFormat:@"%02x",textModel.speedData];
    
    // 10.拼接1个字节停留时间（一屏显示完成后的停留时间）
    sendText = [sendText stringByAppendingFormat:@"%02x",textModel.stayTime];
    
    if ([[ThemManager sharedInstance].peripheralName isEqualToString:@"CoolLEDMX"]) {
        // 11.拼接2个字节移动间隔
        sendText = [sendText stringByAppendingFormat:@"%04x",textModel.movespace];
        
        // 12.拼接2个字节文字个数
        sendText = [sendText stringByAppendingFormat:@"%04x",(int)textModel.textItems.count];
        
        // 12.拼接4个字节所有文字所占宽度之和
        
        sendText = [sendText stringByAppendingFormat:@"%08x",(int)wordsLenght];
        
        //13.
        // N 个文字所占宽度,
        //第 N 个文字的类型标识( 0-表示为单色文字， 1-表示为多色文字表情 ),
        //第 N 个文字的显示数据,如果为单色文字，只需要显示数据,如果为多色文字（表情）， 则按照涂鸦方式表示该文字数据。
        
        for (int i = 0; i < wideN.count; i ++) {
            NSString *wide = wideN[i];
            wideTypeDataTotal = [wideTypeDataTotal stringByAppendingString:wide];
            NSString *type = typeN[i];
            wideTypeDataTotal = [wideTypeDataTotal stringByAppendingString:type];
            NSArray *dataS = dataN[i];
            for (int j=0; j<dataS.count; j++) {
                NSString *dataStr = dataS[j];
                wideTypeDataTotal = [wideTypeDataTotal stringByAppendingString:dataStr];
            }
        }

        sendText = [sendText stringByAppendingString:wideTypeDataTotal];
        
    }else if ([[ThemManager sharedInstance].peripheralName isEqualToString:@"CoolLEDUX"]) {
        // 11.拼接2个字节移动间隔
        sendText = [sendText stringByAppendingFormat:@"%04x",textModel.movespace];
        
        // 12.拼接2个字节文字个数
        sendText = [sendText stringByAppendingFormat:@"%04x",(int)textModel.textItems.count];
        
        // 13.拼接4个字节所有文字所占宽度之和
        
        sendText = [sendText stringByAppendingFormat:@"%08x",(int)wordsLenght];
        
        //14.
        // N 个文字所占宽度,
        //第 N 个文字的类型标识( 0-表示为单色文字， 1-表示为多色文字表情 ),
        //第 N 个文字的显示数据,如果为单色文字，只需要显示数据,如果为多色文字（表情）， 则按照涂鸦方式表示该文字数据。
        
        for (int i = 0; i < wideN.count; i ++) {
            NSString *wide = wideN[i];
            wideTypeDataTotal = [wideTypeDataTotal stringByAppendingString:wide];
            NSString *type = typeN[i];
            wideTypeDataTotal = [wideTypeDataTotal stringByAppendingString:type];
            NSArray *dataS = dataN[i];
            for (int j=0; j<dataS.count; j++) {
                NSString *dataStr = dataS[j];
                wideTypeDataTotal = [wideTypeDataTotal stringByAppendingString:dataStr];
            }
        }

        sendText = [sendText stringByAppendingString:wideTypeDataTotal];
        
    }else{
        
        // 存文字点阵数据的总长度
        int charsTotalLength = (int) sumCheckedString.length * 0.5 ;
        
        // 11.拼接4个字节文字点阵数据的总长度
        sendText = [sendText stringByAppendingFormat:@"%08x", charsTotalLength];
        
        // 12.文字点阵数据
        sendText = [sendText stringByAppendingString:sumCheckedString];
        
    }
    
    // 0.拼接4个字节该段内容所有数据的总长度
    int sendTotalLength = (int) sendText.length * 0.5 ;
    sendText = [[NSString stringWithFormat:@"%08x", (sendTotalLength+4)] stringByAppendingString:sendText];
    
    
    NSDictionary *result = @{@"sendText":sendText,@"wordsLenght":@(wordsLenght),@"wordsWidth":wordsWidth,@"wordsColor":wordsColor};
    return result;
}

+(NSDictionary *)makeWordCenter:(NSString *)sumCheckedString currentDeviceCols:(int)currentDeviceCols wordShowHeight:(NSInteger)wordShowHeight wordsWidth:(NSString *)wordsWidth wideN:(NSMutableArray *)wideN typeN:(NSMutableArray *)typeN dataN:(NSMutableArray *)dataN wordsColor:(NSString *)wordsColor checkedSumM:(NSMutableArray *)checkedSumM isMirror:(BOOL)isMirror{
    int indexMirror = 0;
    int ratioByte;
    
    switch (wordShowHeight) {
        case 12:
        case 16:
            ratioByte = 2;
            break;
        case 20:
        case 24:
            ratioByte = 3;
            break;
        case 32:
            ratioByte = 4;
            break;
        case 48:
            ratioByte = 6;
            break;
        default:
            break;
    }
    
    int screenNumber = ((int) (sumCheckedString.length * [JTCommon ratioStringByte:wordShowHeight]) + currentDeviceCols - 1) / currentDeviceCols;
    int startCol = (screenNumber - 1) * currentDeviceCols;
    int emptyHalfCol = (screenNumber * currentDeviceCols - (int) (sumCheckedString.length * [JTCommon ratioStringByte:wordShowHeight]))/2;
    int theRestEmptyHalfCol = (screenNumber * currentDeviceCols - (int) (sumCheckedString.length * [JTCommon ratioStringByte:wordShowHeight])) - emptyHalfCol;
    
    NSString *defaultString = @"";
    for (int i = 0; i < emptyHalfCol * ratioByte; i++) {
        defaultString = [defaultString stringByAppendingString:@"00"];
    }
    
    NSString *theRestDefaultString = @"";
    for (int i = 0; i < theRestEmptyHalfCol * ratioByte; i++) {
        theRestDefaultString = [theRestDefaultString stringByAppendingString:@"00"];
    }
    
    NSMutableArray *searchAll = [[NSMutableArray alloc] init];
    NSMutableString *searchCol = [NSMutableString stringWithString:wordsWidth];
    while (searchCol.length >= 2) {
        NSString *str = [searchCol substringWithRange:NSMakeRange(0, 2)];
        [searchCol deleteCharactersInRange:NSMakeRange(0, 2)];
        [searchAll addObject:str];
    }
    int sumCol = 0;
    for (int i = 0; i < searchAll.count; i++) {
        NSString *oneWordWidth = searchAll[i];
        int oneWordCol = (int)strtoul([[NSString stringWithFormat:@"0x%@",oneWordWidth] UTF8String],0,16);
        sumCol += oneWordCol;
        if(sumCol > startCol){
            NSString *newCol = [NSString stringWithFormat:@"%02x", oneWordCol + emptyHalfCol];
            wordsWidth = [wordsWidth stringByReplacingCharactersInRange:NSMakeRange(i*2, 2) withString:newCol];
            searchAll[i] = newCol;
            indexMirror = i;
            
            wideN[i] = newCol;
            NSString *type = typeN[i];
            NSMutableArray *dataS = dataN[i];
            NSMutableArray *dataSNew = [[NSMutableArray alloc] init];
            
            if ([[ThemManager sharedInstance].peripheralName isEqualToString:@"CoolLEDMX"]) {
                for (int i = 0; i < dataS.count; i++) {
                    NSMutableString *tempMu = [NSMutableString stringWithString:dataS[i]];
                    [tempMu insertString:defaultString atIndex:0];
                    [dataSNew addObject:tempMu];
                }
            }else if([[ThemManager sharedInstance].peripheralName isEqualToString:@"CoolLEDUX"]) {
                if ([type isEqualToString:@"00"]) {
                    for (int i = 0; i < dataS.count; i++) {
                        NSMutableString *tempMu = [NSMutableString stringWithString:dataS[i]];
                        [tempMu insertString:defaultString atIndex:0];
                        [dataSNew addObject:tempMu];
                    }
                }else{
                    for (int i = 0; i < dataS.count; i++) {
                        NSMutableString *tempMu = [NSMutableString stringWithString:dataS[i]];
                        for (int j = 0; j < 16; j++) {
                            [tempMu insertString:defaultString atIndex:0];
                        }
                        [dataSNew addObject:tempMu];
                    }
                }
            }else{
                for (int i = 0; i < dataS.count; i++) {
                    NSMutableString *tempMu = [NSMutableString stringWithString:dataS[i]];
                    [tempMu insertString:defaultString atIndex:0];
                    [dataSNew addObject:tempMu];
                }
            }
            
            dataN[i] = dataSNew;

            break;
        }
    }
    
    int i = searchAll.count - 1;
    NSString *oneWordWidth = searchAll[i];
    int oneWordCol = (int)strtoul([[NSString stringWithFormat:@"0x%@",oneWordWidth] UTF8String],0,16);
    NSString *newCol = [NSString stringWithFormat:@"%02x", oneWordCol + theRestEmptyHalfCol];
    wordsWidth = [wordsWidth stringByReplacingCharactersInRange:NSMakeRange(i*2, 2) withString:newCol];
    
    wideN[i] = newCol;
    NSString *type = typeN[i];
    NSMutableArray *dataS = dataN[i];
    NSMutableArray *dataSNew = [[NSMutableArray alloc] init];
    
    if ([[ThemManager sharedInstance].peripheralName isEqualToString:@"CoolLEDMX"]) {
        for (int i = 0; i < dataS.count; i++) {
            NSMutableString *tempMu = [NSMutableString stringWithString:dataS[i]];
            [tempMu appendString:theRestDefaultString];
            [dataSNew addObject:tempMu];
        }
    }else if([[ThemManager sharedInstance].peripheralName isEqualToString:@"CoolLEDUX"]) {
        if ([type isEqualToString:@"00"]) {
            for (int i = 0; i < dataS.count; i++) {
                NSMutableString *tempMu = [NSMutableString stringWithString:dataS[i]];
                [tempMu appendString:theRestDefaultString];
                [dataSNew addObject:tempMu];
            }
        }else{
            for (int i = 0; i < dataS.count; i++) {
                NSMutableString *tempMu = [NSMutableString stringWithString:dataS[i]];
                for (int j = 0; j < 16; j++) {
                    [tempMu appendString:theRestDefaultString];
                }
                [dataSNew addObject:tempMu];
            }
        }
        
    }else{
        for (int i = 0; i < dataS.count; i++) {
            NSMutableString *tempMu = [NSMutableString stringWithString:dataS[i]];
            [tempMu appendString:theRestDefaultString];
            [dataSNew addObject:tempMu];
        }
    }

    dataN[i] = dataSNew;
    
    NSMutableString *tempMu = [NSMutableString stringWithString:sumCheckedString];
    [tempMu insertString:defaultString atIndex:startCol * ratioByte * 2];
    [tempMu appendString:theRestDefaultString];
    sumCheckedString = [tempMu copy];
    
    // 检查是否需要镜像
    if (isMirror) {
        
        NSUInteger index = startCol;
        
        // 创建两个可变数组用于存储结果
        NSMutableArray *firstArray = [NSMutableArray array];
        NSMutableArray *secondArray = [NSMutableArray array];
        
        // 检查索引是否有效
        if (index < [checkedSumM count]) {
            // 使用 subarrayWithRange 截取第一个数组
            NSRange firstRange = NSMakeRange(0, index);
            [firstArray addObjectsFromArray:[checkedSumM subarrayWithRange:firstRange]];

            // 使用 subarrayWithRange 截取第二个数组
            NSRange secondRange = NSMakeRange(index, [checkedSumM count] - index);
            [secondArray addObjectsFromArray:[checkedSumM subarrayWithRange:secondRange]];
        }
            
        for (int col = 0; col < emptyHalfCol; col++) {
            NSArray *EmptyCol = [HLUtils emptyColArrayWith:@(0) rows:wordShowHeight];
            [secondArray insertObject:EmptyCol atIndex:0];
        }
        for (int col = 0; col < theRestEmptyHalfCol; col++) {
            NSArray *EmptyCol = [HLUtils emptyColArrayWith:@(0) rows:wordShowHeight];
            [secondArray addObject:EmptyCol];
        }
        
        secondArray = [[HLUtils verticalMirror:secondArray] mutableCopy];
        [firstArray addObjectsFromArray:secondArray];
        checkedSumM = firstArray;
        sumCheckedString = [NSString checkedStringWithLatticeArray:checkedSumM];
        
        NSString *wordsWidth1 = [wordsWidth substringToIndex:indexMirror * 2];
        NSString *wordsWidth2 = [wordsWidth substringFromIndex:indexMirror * 2];
        
        wordsWidth2 = [HLUtils reverseAndSwapPairs:wordsWidth2];
        wordsWidth = [wordsWidth1 stringByAppendingString:wordsWidth2];
        if([CurrentDeviceType isEqual:@"CoolLEDM"]){
            NSString *wordsColor1 = [wordsColor substringToIndex:indexMirror * 2];
            NSString *wordsColor2 = [wordsColor substringFromIndex:indexMirror * 2];
            
            wordsColor2 = [HLUtils reverseAndSwapPairs:wordsColor2];
            wordsColor = [wordsColor1 stringByAppendingString:wordsColor2];
        }else if([CurrentDeviceType isEqual:@"CoolLEDU"]){
            NSString *wordsColor1 = [wordsColor substringToIndex:indexMirror * 4];
            NSString *wordsColor2 = [wordsColor substringFromIndex:indexMirror * 4];
            
            wordsColor2 = [HLUtils reverseStringByFourCharacters:wordsColor2];
            wordsColor = [wordsColor1 stringByAppendingString:wordsColor2];
        }
    }
    
    NSDictionary *result = @{@"sumCheckedString":sumCheckedString,@"wordsWidth":wordsWidth,@"wordsColor":wordsColor,@"checkedSumM":checkedSumM};
    
    return result;
}

//B.设置节目内容-自定义文字效果
+(NSString *)getItemCustomColorContent:(ColorTextModel32 *)textModel wordCount:(int)wordCount result:(NSDictionary *)result{
    
    int wordsLenght = [result[@"wordsLenght"] intValue]; // 13.拼接2个字节所有文字所占宽度之和
    NSString *wordsWidth = result[@"wordsWidth"]; // 拼接n个字节每个文字所占宽度的集合
    NSString *wordsColor = result[@"wordsColor"]; // 拼接n个字节每个文字的颜色集合
    
    NSString *customColor = @"";
    
    // 1.拼接1个字节表示该内容的类型
    customColor = [customColor stringByAppendingString:@"06"];
    
    // 2.拼接7个字节预留字节
    for (int i = 0; i < 5; i++) {
        customColor = [customColor stringByAppendingString:@"00"];
    }
    
    // 2.1 拼接2个字节移动间隔
    customColor = [customColor stringByAppendingFormat:@"%04x",textModel.movespace];
    
    // 3.拼接2个字节该内容显示起始列
    customColor = [customColor stringByAppendingFormat:@"%04x",textModel.startCol];
    
    // 4.拼接2个字节该该内容显示起始行
    customColor = [customColor stringByAppendingFormat:@"%04x",textModel.startRow];
    
    // 5.拼接2个字节该内容显示宽度
    customColor = [customColor stringByAppendingFormat:@"%04x",textModel.widthData];
    
    // 6.拼接2个字节该内容显示高度
    customColor = [customColor stringByAppendingFormat:@"%04x",textModel.heightData];
    
    // 7.拼接1个字节显示模式
    customColor = [customColor stringByAppendingFormat:@"%02x",textModel.showModel];
    
    // 9.拼接1个字节显示速度（显示模式的对应速度）
    //+239解决速度变化非线性，前期滑动速度不明显
    customColor = [customColor stringByAppendingFormat:@"%02x",textModel.speedData];
    
    // 10.拼接1个字节停留时间（一屏显示完成后的停留时间）
    customColor = [customColor stringByAppendingFormat:@"%02x",textModel.stayTime];
    
    // 11.拼接1个字预留
    customColor = [customColor stringByAppendingString:@"00"];
    
    // 12.拼接2个字节文字个数
    customColor = [customColor stringByAppendingFormat:@"%04x",(int)wordCount];
    
    // 13.拼接2个字节所有文字所占宽度之和
    
    customColor = [customColor stringByAppendingFormat:@"%04x",(int)wordsLenght];
    
    // 14.拼接n个字节每个文字所占宽度的集合
    customColor = [customColor stringByAppendingString:wordsWidth];
    
    // 15.拼接n个字节每个文字的颜色集合
    customColor = [customColor stringByAppendingString:wordsColor];
    
    // 0.拼接4个字节该段内容所有数据的总长度
    int customColorTotalLength = (int) customColor.length * 0.5 ;
    customColor = [[NSString stringWithFormat:@"%08x", (customColorTotalLength+4)] stringByAppendingString:customColor];
    return customColor;
}

//C.设置节目内容-炫彩文字效果
+(NSString *)getItemDazzleColorContent:(ColorTextModel32 *)textModel{
    
    NSString *dazzleColor = @"";
    
    // 1.拼接1个字节表示该内容的类型
    dazzleColor = [dazzleColor stringByAppendingString:@"05"];
    
    // 2.拼接7个字节预留字节
    for (int i = 0; i < 7; i++) {
        dazzleColor = [dazzleColor stringByAppendingString:@"00"];
    }
    
    // 3.拼接2个字节该内容显示起始列
    dazzleColor = [dazzleColor stringByAppendingFormat:@"%04x", textModel.startCol];
    
    // 4.拼接2个字节该该内容显示起始行
    dazzleColor = [dazzleColor stringByAppendingFormat:@"%04x", textModel.startRow];
    
    // 5.拼接2个字节该内容显示宽度
    dazzleColor = [dazzleColor stringByAppendingFormat:@"%04x", textModel.widthData];
    
    // 6.拼接2个字节该内容显示高度
    dazzleColor = [dazzleColor stringByAppendingFormat:@"%04x", textModel.heightData];
    
    // 7.拼接1个字节文字颜色效果
    //水平斜线滚动（向左、向右）为 7
    dazzleColor = [dazzleColor stringByAppendingFormat:@"%02x", textModel.dazzleShowModel];
    
    // 8.拼接1个字节文字颜色效果变化速度
    dazzleColor = [dazzleColor stringByAppendingFormat:@"%02x", textModel.dazzleSpeedData];
    
    // 9.拼接1个字节文字颜色效果显示方向
    dazzleColor = [dazzleColor stringByAppendingFormat:@"%02x", textModel.dazzleShowModelDirection];
    
    // 10.拼接1个字节预留
    dazzleColor = [dazzleColor stringByAppendingString:@"00"];
    
    // 11.拼接2个字节颜色数据长度
    // 水平斜线滚动（向左、向右）为 7，数据为0x01,0x03,0x02,0x06,0x04,0x05,0x07
    dazzleColor = [dazzleColor stringByAppendingFormat:@"%04x", textModel.dazzleTypeLength];
    
    // 12.拼接n个字节颜色数据
    dazzleColor = [dazzleColor stringByAppendingString:textModel.dazzleType];
    
    // 0.拼接4个字节该段内容所有数据的总长度
    int dazzleColorTotalLength = (int) dazzleColor.length * 0.5 ;
    dazzleColor = [[NSString stringWithFormat:@"%08x", (dazzleColorTotalLength+4)] stringByAppendingString:dazzleColor];
    return dazzleColor;
}

//D.设置节目内容-边框内容数据格式
+(NSString *)getItemEdgeContent:(ColorTextModel32 *)textModel{
    NSString *setEdging = @"";
    
    // 1.拼接1个字节表示该内容的类型
    setEdging = [setEdging stringByAppendingString:@"04"];
    
    // 2.拼接7个字节预留字节
    for (int i = 0; i < 7; i++) {
        setEdging = [setEdging stringByAppendingString:@"00"];
    }
    
    // 3.拼接1个字节该内容显示的时候，和其他层级的内容的混合方式
    setEdging = [setEdging stringByAppendingFormat:@"%02x", textModel.coverTypeEdge];
    
    // 4.拼接2个字节该内容显示起始列
    setEdging = [setEdging stringByAppendingFormat:@"%04x", textModel.startColEdge];
    
    // 5.拼接2个字节该该内容显示起始行
    setEdging = [setEdging stringByAppendingFormat:@"%04x", textModel.startRowEdge];
    
    // 6.拼接2个字节该内容显示宽度
    setEdging = [setEdging stringByAppendingFormat:@"%04x", textModel.widthDataEdge];
    
    // 7.拼接2个字节该内容显示高度
    setEdging = [setEdging stringByAppendingFormat:@"%04x", textModel.heightDataEdge];
    
    // 8.拼接1个字节边框显示效果
    setEdging = [setEdging stringByAppendingFormat:@"%02x", textModel.showModelEdge];
    
    // 9.拼接1个字节边框变化速度
    setEdging = [setEdging stringByAppendingFormat:@"%02x", textModel.speedDataEdge];
    
    // 10.拼接1个字节边框内容高度
    setEdging = [setEdging stringByAppendingFormat:@"%02x", textModel.heightEdge];
    
    // 11.拼接2个字节边框数据的总长度
    setEdging = [setEdging stringByAppendingFormat:@"%04x", textModel.edgelenght];
    
    // 12.拼接n个字节边框显示数据
    setEdging = [setEdging stringByAppendingString:textModel.edgeContent];
    
    // 0.拼接4个字节该段内容所有数据的总长度
    int setEdgingTotalLength = (int) setEdging.length * 0.5 ;
    setEdging = [[NSString stringWithFormat:@"%08x", (setEdgingTotalLength+4)] stringByAppendingString:setEdging];
    
    return setEdging;
}

//通过涂鸦类型点阵生成字符串类型字节数组
+(NSString *)getStrFromGraffitiArr:(NSArray *)data{
    
    NSString *graffitiContent = @"";
    
    if([CurrentDeviceType isEqual:@"CoolLEDM"]){
        
        NSMutableArray *redData = [NSMutableArray array];
        NSMutableArray *greenData = [NSMutableArray array];
        NSMutableArray *blueData = [NSMutableArray array];
        for (int i = 0; i < data.count; i++) {
            NSArray *cols = data[i];
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
        
        
        NSString *redResult = [JTCommon resultStrWithData:redData];
        
        NSString *greenResult = [JTCommon resultStrWithData:greenData];
        
        NSString *blueResult = [JTCommon resultStrWithData:blueData];
        
        graffitiContent = [graffitiContent stringByAppendingString:redResult];
        graffitiContent = [graffitiContent stringByAppendingString:greenResult];
        graffitiContent = [graffitiContent stringByAppendingString:blueResult];
            
    }else if ([CurrentDeviceType isEqual:@"CoolLEDU"]){
        
        for (int i = 0; i < data.count; i++) {
            NSArray *cols = data[i];
            
            NSString *colStr = @"";
            for (int j = 0; j < cols.count; j++) {
                NSArray *rgbData = cols[j];
                
                CGFloat red = [rgbData[0] floatValue] ;
                CGFloat green = [rgbData[1] floatValue];
                CGFloat blue = [rgbData[2] floatValue];
                
                NSString *onePixel = @"";
                onePixel = [onePixel stringByAppendingFormat:@"%02x", [HLUtils colorExchangeFloat:red]];
                onePixel = [onePixel stringByAppendingFormat:@"%02x", [HLUtils colorExchangeFloat:green]* 16 + [HLUtils colorExchangeFloat:blue]];
                
                colStr = [colStr stringByAppendingString:onePixel];
            }
            graffitiContent = [graffitiContent stringByAppendingString:colStr];
        }
        
    }
    
    return graffitiContent;
}

//设置节目内容-涂鸦内容数据格式
+(NSString *)getGraffitiContent:(GraffitiModel32 *)textModel{
    
    NSString *graffitiText = @"";
    
    // 1.拼接1个字节表示该内容的类型
    graffitiText = [graffitiText stringByAppendingString:@"02"];
    
    // 2.拼接7个字节预留字节
    for (int i = 0; i < 7; i++) {
        graffitiText = [graffitiText stringByAppendingString:@"00"];
    }
    
    // 3.拼接1个字节该内容显示的时候，和其他层级的内容的混合方式
    graffitiText = [graffitiText stringByAppendingFormat:@"%02x", textModel.coverTypeGraffiti];
    
    // 4.拼接2个字节该内容显示起始列
    graffitiText = [graffitiText stringByAppendingFormat:@"%04x", textModel.startColGraffiti];
    
    // 5.拼接2个字节该内容显示起始行
    graffitiText = [graffitiText stringByAppendingFormat:@"%04x", textModel.startRowGraffiti];
    
    // 6.拼接2个字节该内容显示宽度
    graffitiText = [graffitiText stringByAppendingFormat:@"%04x", textModel.widthDataGraffiti];
    
    // 7.拼接2个字节该内容显示高度
    graffitiText = [graffitiText stringByAppendingFormat:@"%04x", textModel.heightDataGraffiti];
    
    // 8.拼接1个字节显示模式
    graffitiText = [graffitiText stringByAppendingFormat:@"%02x",textModel.showModelGraffiti];
    
    // 9.拼接1个字节显示速度（显示模式的对应速度）
    //+239解决速度变化非线性，前期滑动速度不明显
    graffitiText = [graffitiText stringByAppendingFormat:@"%02x",textModel.speedDataGraffiti + 239];
    
    // 10.拼接1个字节停留时间（一屏显示完成后的停留时间）
    graffitiText = [graffitiText stringByAppendingFormat:@"%02x",textModel.stayTimeGraffiti];
    
    NSString *sumCheckedString = [self getStrFromGraffitiArr:textModel.dataGraffiti];
    
    // 存文字点阵数据的总长度
    int charsTotalLength = (int) sumCheckedString.length * 0.5 ;
    
    // 11.拼接4个字节文字点阵数据的总长度
    graffitiText = [graffitiText stringByAppendingFormat:@"%08x", charsTotalLength];
    
    // 12.文字点阵数据
    graffitiText = [graffitiText stringByAppendingString:sumCheckedString];
    
    // 0.拼接4个字节该段内容所有数据的总长度
    int sendTotalLength = (int) graffitiText.length * 0.5 ;
    graffitiText = [[NSString stringWithFormat:@"%08x", (sendTotalLength+4)] stringByAppendingString:graffitiText];
    
    return graffitiText;
}

//设置节目内容-动画内容数据格式
+(NSString *)getAnimationContent:(AnimationModel32 *)textModel{
    
    NSString *animationText = @"";
    
    // 1.拼接1个字节表示该内容的类型
    animationText = [animationText stringByAppendingString:@"03"];
    
    // 2.拼接7个字节预留字节
    for (int i = 0; i < 7; i++) {
        animationText = [animationText stringByAppendingString:@"00"];
    }
    
    // 3.拼接1个字节该内容显示的时候，和其他层级的内容的混合方式
    animationText = [animationText stringByAppendingFormat:@"%02x", textModel.coverTypeAnimation];
    
    // 4.拼接2个字节该内容显示起始列
    animationText = [animationText stringByAppendingFormat:@"%04x", textModel.startColAnimation];
    
    // 5.拼接2个字节该内容显示起始行
    animationText = [animationText stringByAppendingFormat:@"%04x", textModel.startRowAnimation];
    
    // 6.拼接2个字节该内容显示宽度
    animationText = [animationText stringByAppendingFormat:@"%04x", textModel.widthDataAnimation];
    
    // 7.拼接2个字节该内容显示高度
    animationText = [animationText stringByAppendingFormat:@"%04x", textModel.heightDataAnimation];
    
    // 8.拼接1个字节预留字节
    animationText = [animationText stringByAppendingString:@"00"];
    
    NSString *sumCheckedString = [JTCommon getStrFromAnimationArr:textModel.dataAnimation]; //计算动画数据
    
    if ([[ThemManager sharedInstance].peripheralName isEqualToString:@"CoolLEDMX"] || [[ThemManager sharedInstance].peripheralName isEqualToString:@"CoolLEDUX"]) {
        
        // 9.拼接2个字节帧数
        animationText = [animationText stringByAppendingFormat:@"%04x",textModel.dataAnimation.count];
        
        // 10.拼接n个字节每帧的独立显示时间集合
        NSString *frameEveInterval = @"";
        if (textModel.frameEveInterval.count == 0){
            for (int i = 0; i<textModel.dataAnimation.count; i++) {
                frameEveInterval = [frameEveInterval stringByAppendingFormat:@"%04x",textModel.timeIntervalAnimation];
            }
        }else{
            for (int i = 0; i<textModel.frameEveInterval.count; i++) {
                frameEveInterval = [frameEveInterval stringByAppendingFormat:@"%04x",textModel.frameEveInterval[i]];
            }
        }
        
        animationText = [animationText stringByAppendingString:frameEveInterval];
        
    }else{
        
        // 9.拼接2个字节每个帧之间的显示间隔时间，间隔时间越长，显示越慢
        animationText = [animationText stringByAppendingFormat:@"%04x",textModel.timeIntervalAnimation];
        
        // 存文字点阵数据的总长度
        int charsTotalLength = (int) sumCheckedString.length * 0.5 ;
        
        // 10.拼接4个字节文字点阵数据的总长度
        animationText = [animationText stringByAppendingFormat:@"%08x", charsTotalLength];
        
    }
    
    // 11.文字点阵数据
    animationText = [animationText stringByAppendingString:sumCheckedString];
    
    // 0.拼接4个字节该段内容所有数据的总长度
    int sendTotalLength = (int) animationText.length * 0.5 ;
    animationText = [[NSString stringWithFormat:@"%08x", (sendTotalLength+4)] stringByAppendingString:animationText];
    
    return animationText;
}

//设置节目内容-时间组件数据格式-数字结构时间组件
+(NSString *)getClockTimeContent:(ClockTime *)textModel{
    
    NSString *clockTimeText = @"";
    
    // 1.拼接1个字节表示该内容的类型
    clockTimeText = [clockTimeText stringByAppendingString:@"07"];
    
    // 2.拼接7个字节预留字节
    for (int i = 0; i < 7; i++) {
        clockTimeText = [clockTimeText stringByAppendingString:@"00"];
    }
    
    // 3.拼接1个字节该内容显示的时候，和其他层级的内容的混合方式
    clockTimeText = [clockTimeText stringByAppendingFormat:@"%02x", textModel.coverTypeClockTime];
    
    // 4.拼接1个字节时间组件标志
    clockTimeText = [clockTimeText stringByAppendingFormat:@"%02x", textModel.timeFlagClockTime];
    
    // 5.拼接2个字节显示时长
    clockTimeText = [clockTimeText stringByAppendingFormat:@"%04x", textModel.showTimeClockTime];
    
    // 6.拼接2个字节每个数字的高度
    clockTimeText = [clockTimeText stringByAppendingFormat:@"%04x", textModel.numHeightClockTime];
    
    // 7.拼接2个字节每个数字的宽度
    clockTimeText = [clockTimeText stringByAppendingFormat:@"%04x", textModel.numWidthClockTime];
    
    // 8.拼接2个字节数字数据长度
    clockTimeText = [clockTimeText stringByAppendingFormat:@"%04x", textModel.numDataLenClockTime];
    
    // 9.拼接n个字节数字（0~9）对应的文字的显示内容。
    clockTimeText = [clockTimeText stringByAppendingString:textModel.numDataClockTime];
    
    // 10.拼接2个字节小时显示颜色
    clockTimeText = [clockTimeText stringByAppendingFormat:@"%04x",textModel.hourColorClockTime];
    
    // 11.拼接2个字节小时显示起始列，相当于 X 坐标
    clockTimeText = [clockTimeText stringByAppendingFormat:@"%04x",textModel.hourStartColumnClockTime];
    
    // 12.拼接2个字节小时显示起始行，相当于 Y 坐标
    clockTimeText = [clockTimeText stringByAppendingFormat:@"%04x",textModel.hourStartRowClockTime];
    
    // 13.拼接2个字节小时显示宽度
    clockTimeText = [clockTimeText stringByAppendingFormat:@"%04x",textModel.hourWidthClockTime];
    
    // 14.拼接2个字节小时显示高度
    clockTimeText = [clockTimeText stringByAppendingFormat:@"%04x",textModel.hourHeightClockTime];
    
    // 15.拼接2个字节分隔符颜色
    clockTimeText = [clockTimeText stringByAppendingFormat:@"%04x",textModel.spacehColorClockTime];
    
    // 16.拼接2个字节分割符显示起始列，相当于 X 坐标
    clockTimeText = [clockTimeText stringByAppendingFormat:@"%04x",textModel.spacehStartColumnClockTime];
    
    // 17.拼接2个字节分割符显示起始行，相当于 Y 坐标
    clockTimeText = [clockTimeText stringByAppendingFormat:@"%04x",textModel.spacehStartRowClockTime];
    
    // 18.拼接2个字节分隔符显示宽度
    clockTimeText = [clockTimeText stringByAppendingFormat:@"%04x",textModel.spacehWidthClockTime];
    
    // 19.拼接2个字节分隔符显示高度
    clockTimeText = [clockTimeText stringByAppendingFormat:@"%04x",textModel.spacehHeightClockTime];
    
    // 20.拼接2个字节分隔符显示数据长度
    clockTimeText = [clockTimeText stringByAppendingFormat:@"%04x",textModel.spacehDataLenClockTime];
    
    // 21.拼接n字节分割符的显示数据
    clockTimeText = [clockTimeText stringByAppendingString:textModel.spacehDataClockTime];
    
    // 22.拼接2个字节分钟显示颜色
    clockTimeText = [clockTimeText stringByAppendingFormat:@"%04x",textModel.minColorClockTime];
    
    // 23.拼接2个字节分钟显示起始列，相当于 X 坐标
    clockTimeText = [clockTimeText stringByAppendingFormat:@"%04x",textModel.minStartColumnClockTime];
    
    // 24.拼接2个字节分钟显示起始行，相当于 Y 坐标
    clockTimeText = [clockTimeText stringByAppendingFormat:@"%04x",textModel.minStartRowClockTime];
    
    // 25拼接2个字节分钟显示宽度
    clockTimeText = [clockTimeText stringByAppendingFormat:@"%04x",textModel.minWidthClockTime];
    
    // 26.拼接2个字节分钟显示高度
    clockTimeText = [clockTimeText stringByAppendingFormat:@"%04x",textModel.minHeightClockTime];
    
    // 27.拼接2个字节分隔符颜色
    clockTimeText = [clockTimeText stringByAppendingFormat:@"%04x",textModel.spacemColorClockTime];
    
    // 28.拼接2个字节分割 符显 示起 始列，相当于 X 坐标
    clockTimeText = [clockTimeText stringByAppendingFormat:@"%04x",textModel.spacemStartColumnClockTime];
    
    // 29.拼接2个字节分割 符显 示起 始行，相当于 Y 坐标
    clockTimeText = [clockTimeText stringByAppendingFormat:@"%04x",textModel.spacemStartRowClockTime];
    
    // 30.拼接2个字节分隔符显示宽度
    clockTimeText = [clockTimeText stringByAppendingFormat:@"%04x",textModel.spacemWidthClockTime];
    
    // 31.拼接2个字节分隔符显示高度
    clockTimeText = [clockTimeText stringByAppendingFormat:@"%04x",textModel.spacemHeightClockTime];
    
    // 32.拼接2个字节分隔符显示数据长度
    clockTimeText = [clockTimeText stringByAppendingFormat:@"%04x",textModel.spacemDataLenClockTime];
    
    // 33.拼接n个字节分割符的显示数据
    clockTimeText = [clockTimeText stringByAppendingString:textModel.spacemDataClockTime];
    
    // 34.拼接2个字节秒显示颜色
    clockTimeText = [clockTimeText stringByAppendingFormat:@"%04x",textModel.secColorClockTime];
    
    // 35.拼接2个字节秒显示起始列，相当于 X 坐标
    clockTimeText = [clockTimeText stringByAppendingFormat:@"%04x",textModel.secStartColumnClockTime];
    
    // 36.拼接2个字节秒显示起始行，相当于 Y 坐标
    clockTimeText = [clockTimeText stringByAppendingFormat:@"%04x",textModel.secStartRowClockTime];
    
    // 37.拼接2个字节秒显示宽度
    clockTimeText = [clockTimeText stringByAppendingFormat:@"%04x",textModel.secWidthClockTime];
    
    // 38.拼接2个字节秒显示高度
    clockTimeText = [clockTimeText stringByAppendingFormat:@"%04x",textModel.secHeightClockTime];
    
    // 39.拼接2个字节Am 和pm 显示颜色
    clockTimeText = [clockTimeText stringByAppendingFormat:@"%04x",textModel.ampmColorClockTime];
    
    // 40.拼接2个字节Am/pm 显示起始列，相当于 X 坐标
    clockTimeText = [clockTimeText stringByAppendingFormat:@"%04x",textModel.ampmStartColumnClockTime];
    
    // 41.拼接2个字节Am/pm 显示起始行，相当于 Y 坐标
    clockTimeText = [clockTimeText stringByAppendingFormat:@"%04x",textModel.ampmStartRowClockTime];
    
    // 42.拼接2个字节Am/pm 显示宽度
    clockTimeText = [clockTimeText stringByAppendingFormat:@"%04x",textModel.ampmWidthClockTime];
    
    // 43.拼接2个字节Am/pm 显示高度
    clockTimeText = [clockTimeText stringByAppendingFormat:@"%04x",textModel.ampmHeightClockTime];
    
    // 44.拼接2个字节Am/pm 显示数据长度
    clockTimeText = [clockTimeText stringByAppendingFormat:@"%04x",textModel.ampmDataLenClockTime];
    
    // 45.拼接n个字节Am 显示数据和 pm显示数据，顺序排列
    clockTimeText = [clockTimeText stringByAppendingString:textModel.ampmDataClockTime];
    
    // 0.拼接4个字节该段内容所有数据的总长度
    int sendTotalLength = (int) clockTimeText.length * 0.5 ;
    clockTimeText = [[NSString stringWithFormat:@"%08x", (sendTotalLength+4)] stringByAppendingString:clockTimeText];
    
    return clockTimeText;
}

//设置节目内容-日期组件数据格式
+(NSString *)getDateTimeContent:(DateTime *)textModel{
    
    NSString *dateTimeText = @"";
    
    // 1.拼接1个字节表示该内容的类型
    dateTimeText = [dateTimeText stringByAppendingString:@"09"];
    
    // 2.拼接7个字节预留字节
    for (int i = 0; i < 7; i++) {
        dateTimeText = [dateTimeText stringByAppendingString:@"00"];
    }
    
    // 3.拼接1个字节该内容显示的时候，和其他层级的内容的混合方式
    dateTimeText = [dateTimeText stringByAppendingFormat:@"%02x", textModel.coverTypeDateTime];
    
    // 4.拼接1个字节日期组件标志
    dateTimeText = [dateTimeText stringByAppendingFormat:@"%02x", textModel.dateFlagDateTime];
    
    // 5.拼接2个字节显示时长
    dateTimeText = [dateTimeText stringByAppendingFormat:@"%04x", textModel.showTimeDateTime];
    
    // 6.拼接2个字节每个数字的高度
    dateTimeText = [dateTimeText stringByAppendingFormat:@"%04x", textModel.numHeightDateTime];
    
    // 7.拼接2个字节每个数字的宽度
    dateTimeText = [dateTimeText stringByAppendingFormat:@"%04x", textModel.numWidthDateTime];
    
    // 8.拼接2个字节数字数据长度
    dateTimeText = [dateTimeText stringByAppendingFormat:@"%04x", textModel.numDataLenDateTime];
    
    // 9.拼接n个字节数字（0~9）对应的文字的显示内容。
    dateTimeText = [dateTimeText stringByAppendingString:textModel.numDataDateTime];
    
    // 10.拼接2个字节年份数字的高度
    dateTimeText = [dateTimeText stringByAppendingFormat:@"%04x", textModel.yearNumHeightDateTime];
    
    // 11.拼接2个字节年份数字的宽度
    dateTimeText = [dateTimeText stringByAppendingFormat:@"%04x", textModel.yearNumWidthDateTime];
    
    // 12.拼接2个字节年份数字数据长度
    dateTimeText = [dateTimeText stringByAppendingFormat:@"%04x", textModel.yearNumDataLenDateTime];
    
    // 13.拼接n个字节年份数字（0~9）对应的文字的显示内容。
    dateTimeText = [dateTimeText stringByAppendingString:textModel.yearNumDataDateTime];
    
    // 14.拼接2个字节年份显示颜色
    dateTimeText = [dateTimeText stringByAppendingFormat:@"%04x", textModel.yearColorDateTime];
    
    // 15.拼接2个字节年份显示起始列，相当于 X 坐标
    dateTimeText = [dateTimeText stringByAppendingFormat:@"%04x", textModel.yearStartColumnDateTime];
    
    // 16.拼接2个字节年份显示起始行，相当于 Y 坐标
    dateTimeText = [dateTimeText stringByAppendingFormat:@"%04x", textModel.yearStartRowDateTime];
    
    // 17.拼接2个字节年份显示宽度
    dateTimeText = [dateTimeText stringByAppendingFormat:@"%04x", textModel.yearWidthDateTime];
    
    // 18.拼接2个字节年份显示高度
    dateTimeText = [dateTimeText stringByAppendingFormat:@"%04x", textModel.yearHeightDateTime];
    
    // 19.拼接2个字节分隔符颜色
    dateTimeText = [dateTimeText stringByAppendingFormat:@"%04x", textModel.spaceyColorDateTime];
    
    // 20.拼接2个字节分割 符显 示起 始列，相当于 X 坐标
    dateTimeText = [dateTimeText stringByAppendingFormat:@"%04x", textModel.spaceyStartColumnDateTime];
    
    // 21.拼接2个字节分割 符显 示起 始行，相当于 Y 坐标
    dateTimeText = [dateTimeText stringByAppendingFormat:@"%04x", textModel.spaceyStartRowDateTime];
    
    // 22.拼接2个字节分隔符显示宽度
    dateTimeText = [dateTimeText stringByAppendingFormat:@"%04x", textModel.spaceyWidthDateTime];
    
    // 23.拼接2个字节分隔符显示高度
    dateTimeText = [dateTimeText stringByAppendingFormat:@"%04x", textModel.spaceyHeightDateTime];
    
    // 24.拼接2个字节分隔符显示数据长度
    dateTimeText = [dateTimeText stringByAppendingFormat:@"%04x", textModel.spaceyDataLenDateTime];
    
    // 25.拼接n个字节分割符的显示数据
    dateTimeText = [dateTimeText stringByAppendingString:textModel.spaceyDataDateTime];
    
    // 26.拼接2个字节月显示颜色
    dateTimeText = [dateTimeText stringByAppendingFormat:@"%04x", textModel.monColorDateTime];
    
    // 27.拼接2个字节月显示起始列，相当于 X 坐标
    dateTimeText = [dateTimeText stringByAppendingFormat:@"%04x", textModel.monStartColumnDateTime];
    
    // 28.拼接2个字节月显示起始行，相当于 Y 坐标
    dateTimeText = [dateTimeText stringByAppendingFormat:@"%04x", textModel.monStartRowDateTime];
    
    // 29.拼接2个字节月显示宽度
    dateTimeText = [dateTimeText stringByAppendingFormat:@"%04x", textModel.monWidthateTime];
    
    // 30.拼接2个字节月显示高度
    dateTimeText = [dateTimeText stringByAppendingFormat:@"%04x", textModel.monHeightDateTime];
    
    // 31.拼接2个字节月份简写显示数据长度
    dateTimeText = [dateTimeText stringByAppendingFormat:@"%04x", textModel.monDataLenDateTime];
    
    // 32.拼接n个字节月份 简写 显示 数据，1 月到 12 月的显示数据，顺序排列
    dateTimeText = [dateTimeText stringByAppendingString:textModel.monDataDateTime];
    
    // 33.拼接2个字节分隔符颜色
    dateTimeText = [dateTimeText stringByAppendingFormat:@"%04x", textModel.spacemColorDateTime];
    
    // 34.拼接2个字节分割 符显 示起 始列，相当于 X 坐标
    dateTimeText = [dateTimeText stringByAppendingFormat:@"%04x", textModel.spacemStartColumnDateTime];
    
    // 35.拼接2个字节分割 符显 示起 始行，相当于 Y 坐标
    dateTimeText = [dateTimeText stringByAppendingFormat:@"%04x", textModel.spacemStartRowDateTime];
    
    // 36.拼接2个字节分隔符显示宽度
    dateTimeText = [dateTimeText stringByAppendingFormat:@"%04x", textModel.spacemWidthDateTime];
    
    // 37.拼接2个字节分隔符显示高度
    dateTimeText = [dateTimeText stringByAppendingFormat:@"%04x", textModel.spacemHeightDateTime];
    
    // 38.拼接2个字节分隔符显示数据长度
    dateTimeText = [dateTimeText stringByAppendingFormat:@"%04x", textModel.spacemDataLenDateTime];
    
    // 39.拼接n个字节分割符的显示数据
    dateTimeText = [dateTimeText stringByAppendingString:textModel.spacemDataDateTime];
    
    // 40.拼接2个字节天显示颜色
    dateTimeText = [dateTimeText stringByAppendingFormat:@"%04x", textModel.dayColorDateTime];
    
    // 41.拼接2个字节天显示起始列，相当于 X 坐标
    dateTimeText = [dateTimeText stringByAppendingFormat:@"%04x", textModel.dayStartColumnDateTime];
    
    // 42.拼接2个字节天显示起始行，相当于 Y 坐标
    dateTimeText = [dateTimeText stringByAppendingFormat:@"%04x", textModel.dayStartRowDateTime];
    
    // 43.拼接2个字节天显示宽度
    dateTimeText = [dateTimeText stringByAppendingFormat:@"%04x", textModel.dayWidthDateTime];
    
    // 44.拼接2个字节天显示高度
    dateTimeText = [dateTimeText stringByAppendingFormat:@"%04x", textModel.dayHeightDateTime];
    
    // 45.拼接2个字节分隔符颜色
    dateTimeText = [dateTimeText stringByAppendingFormat:@"%04x", textModel.spacedColorDateTime];
    
    // 46.拼接2个字节分割 符显 示起 始列，相当于 X 坐标
    dateTimeText = [dateTimeText stringByAppendingFormat:@"%04x", textModel.spacedStartColumnDateTime];
    
    // 47.拼接2个字节分割 符显 示起 始行，相当于 Y 坐标
    dateTimeText = [dateTimeText stringByAppendingFormat:@"%04x", textModel.spacedStartRowDateTime];
    
    // 48.拼接2个字节分隔符显示宽度
    dateTimeText = [dateTimeText stringByAppendingFormat:@"%04x", textModel.spacedWidthDateTime];
    
    // 49.拼接2个字节分隔符显示高度
    dateTimeText = [dateTimeText stringByAppendingFormat:@"%04x", textModel.spacedHeightDateTime];
    
    // 50.拼接2个字节分隔符显示数据长度
    dateTimeText = [dateTimeText stringByAppendingFormat:@"%04x", textModel.spacedDataLenDateTime];
    
    // 51.拼接n个字节分割符的显示数据
    dateTimeText = [dateTimeText stringByAppendingString:textModel.spacedDataDateTime];
    
    // 52.拼接2个字节星期显示颜色
    dateTimeText = [dateTimeText stringByAppendingFormat:@"%04x", textModel.weekColorDateTime];
    
    // 53.拼接2个字节星期显示起始行
    dateTimeText = [dateTimeText stringByAppendingFormat:@"%04x", textModel.weekStartRowDateTime];
    
    // 54.拼接2个字节星期显示起始列
    dateTimeText = [dateTimeText stringByAppendingFormat:@"%04x", textModel.weekStartColumnDateTime];
    
    // 55.拼接2个字节星期显示宽度
    dateTimeText = [dateTimeText stringByAppendingFormat:@"%04x", textModel.weekWidthDateTime];
    
    // 56.拼接2个字节星期显示高度
    dateTimeText = [dateTimeText stringByAppendingFormat:@"%04x", textModel.weekHeightDateTime];
    
    // 57.拼接2个字节星期显示数据长度
    dateTimeText = [dateTimeText stringByAppendingFormat:@"%04x", textModel.weekDataLenDateTime];
    
    // 58.拼接n个字节星期一到星期日的显示数据，顺序排列
    dateTimeText = [dateTimeText stringByAppendingString:textModel.weekDataDateTime];
    
    // 0.拼接4个字节该段内容所有数据的总长度
    int sendTotalLength = (int) dateTimeText.length * 0.5 ;
    dateTimeText = [[NSString stringWithFormat:@"%08x", (sendTotalLength+4)] stringByAppendingString:dateTimeText];
    
    return dateTimeText;
}

//设置节目内容-计时器组件数据格式
+(NSString *)getCountdownContent:(Countdown *)textModel{
    
    NSString *countdownText = @"";
    
    // 1.拼接1个字节表示该内容的类型
    countdownText = [countdownText stringByAppendingString:@"0A"];
    
    // 2.拼接7个字节预留字节
    for (int i = 0; i < 7; i++) {
        countdownText = [countdownText stringByAppendingString:@"00"];
    }
    
    // 3.拼接1个字节该内容显示的时候，和其他层级的内容的混合方式
    countdownText = [countdownText stringByAppendingFormat:@"%02x", textModel.coverTypeCountdown];
    
    // 4.拼接1个字节计时器模式
    countdownText = [countdownText stringByAppendingFormat:@"%02x", textModel.modeCountdown];
    
    // 5.拼接2个字节每个数字的高度
    countdownText = [countdownText stringByAppendingFormat:@"%04x", textModel.numHeightCountdown];
    
    // 6.拼接2个字节每个数字的宽度
    countdownText = [countdownText stringByAppendingFormat:@"%04x", textModel.numWidthCountdown];
    
    // 7.拼接2个字节数字数据长度
    countdownText = [countdownText stringByAppendingFormat:@"%04x", textModel.numDataLenCountdown];
    
    // 8.拼接n个字节数字（0~9）对应的文字的显示内容。
    countdownText = [countdownText stringByAppendingString:textModel.numDataCountdown];
    
    // 9.拼接2个字节小时显示颜色
    countdownText = [countdownText stringByAppendingFormat:@"%04x",textModel.hourColorCountdown];
    
    // 10.拼接2个字节小时显示起始列，相当于 X 坐标
    countdownText = [countdownText stringByAppendingFormat:@"%04x",textModel.hourStartColumnCountdown];
    
    // 11.拼接2个字节小时显示起始行，相当于 Y 坐标
    countdownText = [countdownText stringByAppendingFormat:@"%04x",textModel.hourStartRowCountdown];
    
    // 12.拼接2个字节小时显示宽度
    countdownText = [countdownText stringByAppendingFormat:@"%04x",textModel.hourWidthCountdown];
    
    // 13.拼接2个字节小时显示高度
    countdownText = [countdownText stringByAppendingFormat:@"%04x",textModel.hourHeightCountdown];
    
    // 14.拼接2个字节分隔符颜色
    countdownText = [countdownText stringByAppendingFormat:@"%04x",textModel.spacehColorCountdown];
    
    // 15.拼接2个字节分割符显示起始列，相当于 X 坐标
    countdownText = [countdownText stringByAppendingFormat:@"%04x",textModel.spacehStartColumnCountdown];
    
    // 16.拼接2个字节分割符显示起始行，相当于 Y 坐标
    countdownText = [countdownText stringByAppendingFormat:@"%04x",textModel.spacehStartRowCountdown];
    
    // 17.拼接2个字节分隔符显示宽度
    countdownText = [countdownText stringByAppendingFormat:@"%04x",textModel.spacehWidthCountdown];
    
    // 18.拼接2个字节分隔符显示高度
    countdownText = [countdownText stringByAppendingFormat:@"%04x",textModel.spacehHeightCountdown];
    
    // 19.拼接2个字节分隔符显示数据长度
    countdownText = [countdownText stringByAppendingFormat:@"%04x",textModel.spacehDataLenCountdown];
    
    // 20.拼接n字节分割符的显示数据
    countdownText = [countdownText stringByAppendingString:textModel.spacehDataCountdown];
    
    // 21拼接2个字节分钟显示颜色
    countdownText = [countdownText stringByAppendingFormat:@"%04x",textModel.minColorCountdown];
    
    // 22.拼接2个字节分钟显示起始列，相当于 X 坐标
    countdownText = [countdownText stringByAppendingFormat:@"%04x",textModel.minStartColumnCountdown];
    
    // 23.拼接2个字节分钟显示起始行，相当于 Y 坐标
    countdownText = [countdownText stringByAppendingFormat:@"%04x",textModel.minStartRowCountdown];
    
    // 24拼接2个字节分钟显示宽度
    countdownText = [countdownText stringByAppendingFormat:@"%04x",textModel.minWidthCountdown];
    
    // 25.拼接2个字节分钟显示高度
    countdownText = [countdownText stringByAppendingFormat:@"%04x",textModel.minHeightCountdown];
    
    // 26.拼接2个字节分隔符颜色
    countdownText = [countdownText stringByAppendingFormat:@"%04x",textModel.spacemColorCountdown];
    
    // 27.拼接2个字节分割 符显 示起 始列，相当于 X 坐标
    countdownText = [countdownText stringByAppendingFormat:@"%04x",textModel.spacemStartColumnCountdown];
    
    // 28.拼接2个字节分割 符显 示起 始行，相当于 Y 坐标
    countdownText = [countdownText stringByAppendingFormat:@"%04x",textModel.spacemStartRowCountdown];
    
    // 29.拼接2个字节分隔符显示宽度
    countdownText = [countdownText stringByAppendingFormat:@"%04x",textModel.spacemWidthCountdown];
    
    // 30.拼接2个字节分隔符显示高度
    countdownText = [countdownText stringByAppendingFormat:@"%04x",textModel.spacemHeightCountdown];
    
    // 31.拼接2个字节分隔符显示数据长度
    countdownText = [countdownText stringByAppendingFormat:@"%04x",textModel.spacemDataLenCountdown];
    
    // 32.拼接n个字节分割符的显示数据
    countdownText = [countdownText stringByAppendingString:textModel.spacemDataCountdown];
    
    // 33.拼接2个字节秒显示颜色
    countdownText = [countdownText stringByAppendingFormat:@"%04x",textModel.secColorCountdown];
    
    // 34拼接2个字节秒显示起始列，相当于 X 坐标
    countdownText = [countdownText stringByAppendingFormat:@"%04x",textModel.secStartColumnCountdown];
    
    // 35.拼接2个字节秒显示起始行，相当于 Y 坐标
    countdownText = [countdownText stringByAppendingFormat:@"%04x",textModel.secStartRowCountdown];
    
    // 36.拼接2个字节秒显示宽度
    countdownText = [countdownText stringByAppendingFormat:@"%04x",textModel.secWidthCountdown];
    
    // 37.拼接2个字节秒显示高度
    countdownText = [countdownText stringByAppendingFormat:@"%04x",textModel.secHeightCountdown];
    
    // 0.拼接4个字节该段内容所有数据的总长度
    int sendTotalLength = (int) countdownText.length * 0.5 ;
    countdownText = [[NSString stringWithFormat:@"%08x", (sendTotalLength+4)] stringByAppendingString:countdownText];
    
    return countdownText;
}

//设置节目内容-计分板组件数据格式
+(NSString *)getScoreboardContent:(Scoreboard *)textModel{
    
    NSString *scoreboardTimeText = @"";
    
    // 1.拼接1个字节表示该内容的类型
    scoreboardTimeText = [scoreboardTimeText stringByAppendingString:@"0B"];
    
    // 2.拼接7个字节预留字节
    for (int i = 0; i < 7; i++) {
        scoreboardTimeText = [scoreboardTimeText stringByAppendingString:@"00"];
    }
    
    // 3.拼接1个字节该内容显示的时候，和其他层级的内容的混合方式
    scoreboardTimeText = [scoreboardTimeText stringByAppendingFormat:@"%02x", textModel.coverTypeScoreboard];
    
    // 4.拼接1个字节预留字节
    scoreboardTimeText = [scoreboardTimeText stringByAppendingString:@"00"];
    
    // 5.拼接2个字节小节比分每个数字的高度
    scoreboardTimeText = [scoreboardTimeText stringByAppendingFormat:@"%04x", textModel.secnumHeightScoreboard];
    
    // 6.拼接2个字节小节比分每个数字的宽度
    scoreboardTimeText = [scoreboardTimeText stringByAppendingFormat:@"%04x", textModel.secnumWidthScoreboard];
    
    // 7.拼接2个字节小节比分数字数据长度
    scoreboardTimeText = [scoreboardTimeText stringByAppendingFormat:@"%04x", textModel.secnumDataLenScoreboard];
    
    // 8.拼接n个字节小 节 比 分 数 字（0~9）对应的文字的显示内容。
    scoreboardTimeText = [scoreboardTimeText stringByAppendingString:textModel.secnumDataScoreboard];
    
    // 9.拼接2个字节主队分数显示颜色
    scoreboardTimeText = [scoreboardTimeText stringByAppendingFormat:@"%04x", textModel.hsColorScoreboard];
    
    // 10.拼接2个字节主队分数显示起始列，相当于X 坐标
    scoreboardTimeText = [scoreboardTimeText stringByAppendingFormat:@"%04x", textModel.hsStartColumnScoreboard];
    
    // 11.拼接2个字节主队分数显示起始行，相当于Y 坐标
    scoreboardTimeText = [scoreboardTimeText stringByAppendingFormat:@"%04x", textModel.hsStartRowScoreboard];
    
    // 12.拼接2个字节主队分数显示宽度
    scoreboardTimeText = [scoreboardTimeText stringByAppendingFormat:@"%04x", textModel.hsWidthScoreboard];
    
    // 13.拼接2个字节主队分数显示高度
    scoreboardTimeText = [scoreboardTimeText stringByAppendingFormat:@"%04x", textModel.hsHeightScoreboard];
    
    // 14.拼接2个字节客队分数显示颜色
    scoreboardTimeText = [scoreboardTimeText stringByAppendingFormat:@"%04x", textModel.vsColorScoreboard];
    
    // 15.拼接2个字节客队分数显示起始列，相当于X 坐标
    scoreboardTimeText = [scoreboardTimeText stringByAppendingFormat:@"%04x", textModel.vsStartColumnScoreboard];
    
    // 16.拼接2个字节客队分数显示起始行，相当于Y 坐标
    scoreboardTimeText = [scoreboardTimeText stringByAppendingFormat:@"%04x", textModel.vsStartRowScoreboard];
    
    // 17.拼接2个字节客队分数显示宽度
    scoreboardTimeText = [scoreboardTimeText stringByAppendingFormat:@"%04x", textModel.vsWidthScoreboard];
    
    // 18.拼接2个字节客队分数显示高度
    scoreboardTimeText = [scoreboardTimeText stringByAppendingFormat:@"%04x", textModel.vsHeightScoreboard];
    
    // 19.拼接2个字节总比分每个数字的高度
    scoreboardTimeText = [scoreboardTimeText stringByAppendingFormat:@"%04x", textModel.totalnumHeightScoreboard];
    
    // 20.拼接2个字节总比分每个数字的宽度
    scoreboardTimeText = [scoreboardTimeText stringByAppendingFormat:@"%04x", textModel.totalnumWidthScoreboard];
    
    // 21.拼接2个字节总比分数字数据长度
    scoreboardTimeText = [scoreboardTimeText stringByAppendingFormat:@"%04x", textModel.totalnumDataLenScoreboard];
    
    // 22.拼接n个字节总比分数字（0~9）对应的文字的显示内容。
    scoreboardTimeText = [scoreboardTimeText stringByAppendingString:textModel.totalnumDataScoreboard];
    
    // 23.拼接2个字节主队总分数显示颜色
    scoreboardTimeText = [scoreboardTimeText stringByAppendingFormat:@"%04x", textModel.htsColorScoreboard];
    
    // 24.拼接2个字节主队总分数显示起始列，相当于 X 坐标
    scoreboardTimeText = [scoreboardTimeText stringByAppendingFormat:@"%04x", textModel.htsStartColumnScoreboard];
    
    // 25.拼接2个字节主队总分数显示起始行，相当于Y 坐标
    scoreboardTimeText = [scoreboardTimeText stringByAppendingFormat:@"%04x", textModel.htsStartRowScoreboard];
    
    // 26.拼接2个字节主队总分数显示宽度
    scoreboardTimeText = [scoreboardTimeText stringByAppendingFormat:@"%04x", textModel.htsWidthScoreboard];
    
    // 27.拼接2个字节主队总分数显示高度
    scoreboardTimeText = [scoreboardTimeText stringByAppendingFormat:@"%04x", textModel.htsHeightScoreboard];
    
    // 28.拼接2个字节客队总分数显示颜色
    scoreboardTimeText = [scoreboardTimeText stringByAppendingFormat:@"%04x", textModel.vtsColorScoreboard];
    
    // 29.拼接2个字节客队总分数显示起始列，相当于 X 坐标
    scoreboardTimeText = [scoreboardTimeText stringByAppendingFormat:@"%04x", textModel.vtsStartColumnScoreboard];
    
    // 30.拼接2个字节客队总分数显示起始行，相当于Y 坐标
    scoreboardTimeText = [scoreboardTimeText stringByAppendingFormat:@"%04x", textModel.vtsStartRowScoreboard];
    
    // 31.拼接2个字节客队总分数显示宽度
    scoreboardTimeText = [scoreboardTimeText stringByAppendingFormat:@"%04x", textModel.vtsWidthScoreboard];
    
    // 32.拼接2个字节客队总分数显示高度
    scoreboardTimeText = [scoreboardTimeText stringByAppendingFormat:@"%04x", textModel.vtsHeightScoreboard];
    
    // 33.拼接2个字节时间每个数字的高度
    scoreboardTimeText = [scoreboardTimeText stringByAppendingFormat:@"%04x", textModel.timenumHeightScoreboard];
    
    // 34.拼接2个字节时间每个数字的宽度
    scoreboardTimeText = [scoreboardTimeText stringByAppendingFormat:@"%04x", textModel.timenumWidthScoreboard];
    
    // 35.拼接2个字节时间数字数据长度
    scoreboardTimeText = [scoreboardTimeText stringByAppendingFormat:@"%04x", textModel.timenumDataLenScoreboard];
    
    // 36.拼接n个字节时间数字（0~9）对应的文字的显示内容。
    scoreboardTimeText = [scoreboardTimeText stringByAppendingString:textModel.timenumDataScoreboard];
    
    // 37.拼接2个字节分钟显示颜色
    scoreboardTimeText = [scoreboardTimeText stringByAppendingFormat:@"%04x", textModel.minColorScoreboard];
    
    // 38.拼接2个字节分钟显示起始列，相当于 X 坐标
    scoreboardTimeText = [scoreboardTimeText stringByAppendingFormat:@"%04x", textModel.minStartColumnScoreboard];
    
    // 39.拼接n个字节分钟显示起始行，相当于 Y 坐标
    scoreboardTimeText = [scoreboardTimeText stringByAppendingFormat:@"%04x", textModel.minStartRowScoreboard];
    
    // 40.拼接2个字节分钟显示宽度
    scoreboardTimeText = [scoreboardTimeText stringByAppendingFormat:@"%04x", textModel.minWidthScoreboard];
    
    // 41.拼接2个字节分钟显示高度
    scoreboardTimeText = [scoreboardTimeText stringByAppendingFormat:@"%04x", textModel.minHeightScoreboard];
    
    // 42.拼接2个字节分隔符颜色
    scoreboardTimeText = [scoreboardTimeText stringByAppendingFormat:@"%04x", textModel.spacemColorScoreboard];
    
    // 43.拼接2个字节分割 符显 示起 始列，相当于 X 坐标
    scoreboardTimeText = [scoreboardTimeText stringByAppendingFormat:@"%04x", textModel.spacemStartColumnScoreboard];
    
    // 44.拼接2个字节分割 符显 示起 始行，相当于 Y 坐标
    scoreboardTimeText = [scoreboardTimeText stringByAppendingFormat:@"%04x", textModel.spacemStartRowScoreboard];
    
    // 45.拼接2个字节分隔符显示宽度
    scoreboardTimeText = [scoreboardTimeText stringByAppendingFormat:@"%04x", textModel.spacemWidthScoreboard];
    
    // 46.拼接2个字节分隔符显示高度
    scoreboardTimeText = [scoreboardTimeText stringByAppendingFormat:@"%04x", textModel.spacemHeightScoreboard];
    
    // 47.拼接2个字节分割符显示数据长度
    scoreboardTimeText = [scoreboardTimeText stringByAppendingFormat:@"%04x", textModel.spacemDataLenScoreboard];
    
    // 48.拼接n个字节分割符的显示数据
    scoreboardTimeText = [scoreboardTimeText stringByAppendingString:textModel.spacemDataScoreboard];
    
    // 49.拼接2个字节秒显示颜色
    scoreboardTimeText = [scoreboardTimeText stringByAppendingFormat:@"%04x", textModel.secColorScoreboard];
    
    // 50.拼接2个字节秒显示起始列，相当于 X 坐标
    scoreboardTimeText = [scoreboardTimeText stringByAppendingFormat:@"%04x", textModel.secStartColumnScoreboard];
    
    // 51.拼接2个字节秒显示起始行，相当于 Y 坐标
    scoreboardTimeText = [scoreboardTimeText stringByAppendingFormat:@"%04x", textModel.secStartRowScoreboard];
    
    // 52.拼接2个字节秒显示宽度
    scoreboardTimeText = [scoreboardTimeText stringByAppendingFormat:@"%04x", textModel.secWidthScoreboard];
    
    // 53.拼接2个字节秒显示高度
    scoreboardTimeText = [scoreboardTimeText stringByAppendingFormat:@"%04x", textModel.secHeightScoreboard];
    
    // 0.拼接4个字节该段内容所有数据的总长度
    int sendTotalLength = (int) scoreboardTimeText.length * 0.5 ;
    scoreboardTimeText = [[NSString stringWithFormat:@"%08x", (sendTotalLength+4)] stringByAppendingString:scoreboardTimeText];
    
    return scoreboardTimeText;
}


//E.设置节目内容
+(NSString *)getItemTotalContent:(ColorItemModel32 *)colorItemModel32{

    // CRITICAL DEBUG: Log what we're receiving
    for (NSInteger i = 0; i < colorItemModel32.colorTextModel32Arr.count; i++) {
        ColorTextModel32 *textModel = colorItemModel32.colorTextModel32Arr[i];

        // Log each textItem to see if any have issues
        for (NSInteger j = 0; j < textModel.textItems.count; j++) {
            HLColorTextItem *textItem = textModel.textItems[j];
        }
    }

    NSString *sendItem = @"";
    
    // 1.拼接8个字节预留字节
    for (int i = 0; i < 8; i++) {
        sendItem = [sendItem stringByAppendingString:@"00"];
    }
    
    // 2.拼接1个字节该节目包含了多少个内容
    sendItem = [sendItem stringByAppendingFormat:@"%02x",colorItemModel32.itemContentCount];
    
    
    
    if ([[ThemManager sharedInstance].peripheralName isEqualToString:@"CoolLEDUX"]) {
        // 3.拼接1个字节预留字节
        sendItem = [sendItem stringByAppendingFormat:@"%02x",0];
    }else{
        // 3.拼接1个字节在有多个节目的情况下，显示多少次后切换到下一个节目
        sendItem = [sendItem stringByAppendingFormat:@"%02x",colorItemModel32.itemShowTime];
    }
   
    
    // 4.拼接n个字节相应内容的数据（内容排到前面的渲染层 级 Z 越低）
    
    //对节目内容进行拼接，按CoolLEDM的协议格式进行拼接
    //判断在2行的文字情况下是否拥有大边框
    BOOL isLargeEdge = NO;
    if(colorItemModel32.colorTextModel32Arr.count == 3){
        ColorTextModel32 *textModel = colorItemModel32.colorTextModel32Arr[2];
        isLargeEdge = textModel.isEdge;
    }
    if([CurrentDeviceType isEqual:@"CoolLEDM"]){
        
        // 4.1拼接 - 节目对象（内容、颜色、边框组合部分）
        
        if(colorItemModel32.colorTextModel32Arr.count > 0){
            
            for (int i = 0; i < colorItemModel32.colorTextModel32Arr.count; i++) {
                NSString *colorTextModel32Str = @"";
                
                ColorTextModel32 *textModel = colorItemModel32.colorTextModel32Arr[i];
                NSArray *textItems = textModel.textItems;
                
                //允许边框单独存在，判断是否有内容
                if(![textModel isOnlyEdge]){
                    //A.设置节目内容-文字内容数据格式
                    NSDictionary *result = [self getItemWordContent:textModel deviceCols:textModel.widthData isLargeEdge:isLargeEdge];
                    NSString *sendText = result[@"sendText"];
                    
                    //B.设置节目内容-自定义文字效果
                    NSString *customColor = [self getItemCustomColorContent:textModel wordCount:(int)textItems.count  result:result];
                    
                    
                    //C.设置节目内容-炫彩文字效果
                    NSString *dazzleColor = [self getItemDazzleColorContent:textModel];
                    
                    switch (textModel.colorShowType) {
                        case 0:
                            
                            break;
                        case 1:
                        {
                            //拼接自定义文字效果
                            colorTextModel32Str = [colorTextModel32Str stringByAppendingString:customColor];
                        }
                            break;
                        case 2:
                        {
                            //拼接炫彩文字效果
                            colorTextModel32Str = [colorTextModel32Str stringByAppendingString:dazzleColor];
                        }
                            break;
                            
                        default:
                            break;
                    }
                    //拼接字体内容
                    colorTextModel32Str = [colorTextModel32Str stringByAppendingString:sendText];
                }
                
                if(textModel.isEdge){
                    //D.设置节目内容-边框内容数据格式
                    NSString *setEdging = [self getItemEdgeContent:textModel];
                    //拼接边框内容
                    colorTextModel32Str = [colorTextModel32Str stringByAppendingString:setEdging];
                }
                //拼接每个对象包括内容、颜色、边框组合
                sendItem = [sendItem stringByAppendingString:colorTextModel32Str];
            }
            
        }
        
        // 4.2拼接 - 涂鸦内容数据格式
        if(colorItemModel32.graffitiModel32Arr.count > 0){
            
            
            for (int i = 0; i < colorItemModel32.graffitiModel32Arr.count; i++) {
                NSString *graffitiModel32Str = @"";
                
                GraffitiModel32 *graffitiModel = colorItemModel32.graffitiModel32Arr[i];
                
                //涂鸦内容数据
                NSString *setGraffiti = [self getGraffitiContent:graffitiModel];
                
                graffitiModel32Str = [graffitiModel32Str stringByAppendingString:setGraffiti];
                
                sendItem = [sendItem stringByAppendingString:graffitiModel32Str];
            }
            
        }
        
        // 4.3拼接 - 动画内容数据格式
        if(colorItemModel32.animationModel32Arr.count > 0){
            for (int i = 0; i < colorItemModel32.animationModel32Arr.count; i++) {
                NSString *animationModel32Str = @"";
                
                AnimationModel32 *animationModel = colorItemModel32.animationModel32Arr[i];
                
                //动画内容数据
                NSString *setAnimation = [self getAnimationContent:animationModel];
                
                animationModel32Str = [animationModel32Str stringByAppendingString:setAnimation];
                
                sendItem = [sendItem stringByAppendingString:animationModel32Str];
            }
        }
        
        // 10.3.6.1拼接 - 数字结构时间组件
        if(colorItemModel32.clockTimeModelArr.count > 0){
            for (int i = 0; i < colorItemModel32.clockTimeModelArr.count; i++) {
                NSString *clockTimeModelStr = @"";
                
                ClockTime *animationModel = colorItemModel32.clockTimeModelArr[i];
                
                //数字结构时间组件
                NSString *setClockTime = [self getClockTimeContent:animationModel];
                
                clockTimeModelStr = [clockTimeModelStr stringByAppendingString:setClockTime];
                
                sendItem = [sendItem stringByAppendingString:clockTimeModelStr];
            }
        }
        
        // 10.3.7拼接 - 日期组件数据格式
        if(colorItemModel32.dateTimeModelArr.count > 0){
            for (int i = 0; i < colorItemModel32.dateTimeModelArr.count; i++) {
                NSString *dateTimeModelStr = @"";
                
                DateTime *dateTime = colorItemModel32.dateTimeModelArr[i];
                
                //日期组件数据格式
                NSString *setDateTime = [self getDateTimeContent:dateTime];
                
                dateTimeModelStr = [dateTimeModelStr stringByAppendingString:setDateTime];
                
                sendItem = [sendItem stringByAppendingString:dateTimeModelStr];
            }
        }
        
        // 10.3.8拼接 - 计时器组件数据格式
        if(colorItemModel32.countdownModelArr.count > 0){
            for (int i = 0; i < colorItemModel32.countdownModelArr.count; i++) {
                NSString *countdownModelStr = @"";
                
                Countdown *countdown = colorItemModel32.countdownModelArr[i];
                
                //计时器组件数据格式
                NSString *setCountdown = [self getCountdownContent:countdown];
                
                countdownModelStr = [countdownModelStr stringByAppendingString:setCountdown];
                
                sendItem = [sendItem stringByAppendingString:countdownModelStr];
            }
        }
        
        // 11.3.9拼接 - 计分板组件数据格式
        if(colorItemModel32.scoreboardModelArr.count > 0){
            for (int i = 0; i < colorItemModel32.scoreboardModelArr.count; i++) {
                NSString *scoreboardModelStr = @"";
                
                Scoreboard *scoreboard = colorItemModel32.scoreboardModelArr[i];
                
                //日期组件数据格式
                NSString *setScoreboard = [self getScoreboardContent:scoreboard];
                
                scoreboardModelStr = [scoreboardModelStr stringByAppendingString:setScoreboard];
                
                sendItem = [sendItem stringByAppendingString:scoreboardModelStr];
            }
        }
        
        
        
    //对节目内容进行拼接，按CoolLEDU的协议格式进行拼接
    }else if ([CurrentDeviceType isEqual:@"CoolLEDU"]){


        // 4.1拼接 - 节目对象（内容、颜色、边框组合部分）
        if(colorItemModel32.colorTextModel32Arr.count > 0){

            for (int i = 0; i < colorItemModel32.colorTextModel32Arr.count; i++) {
                NSString *colorTextModel32Str = @"";

                ColorTextModel32 *textModel = colorItemModel32.colorTextModel32Arr[i];
                NSArray *textItems = textModel.textItems;

                //允许边框单独存在，判断是否有内容
                if(![textModel isOnlyEdge]){
                    //A.设置节目内容-文字内容数据格式
                    NSDictionary *result = [self getItemWordContent:textModel deviceCols:textModel.widthData isLargeEdge:isLargeEdge];
                    NSString *sendText = result[@"sendText"];
                    
                    //B.设置节目内容-自定义文字效果
                    NSString *customColor = [self getItemCustomColorContent:textModel wordCount:(int)textItems.count result:result];
                    
                    
                    //C.设置节目内容-炫彩文字效果
                    NSString *dazzleColor = [self getItemDazzleColorContent:textModel];
                    
                    switch (textModel.colorShowType) {
                        case 0:
                            
                            break;
                        case 1:
                        {
                            //拼接自定义文字效果
                            colorTextModel32Str = [colorTextModel32Str stringByAppendingString:customColor];
                        }
                            break;
                        case 2:
                        {
                            //拼接炫彩文字效果
                            colorTextModel32Str = [colorTextModel32Str stringByAppendingString:dazzleColor];
                        }
                            break;
                            
                        default:
                            break;
                    }
                    //拼接字体内容
                    colorTextModel32Str = [colorTextModel32Str stringByAppendingString:sendText];
                }
                
                if(textModel.isEdge){
                    //D.设置节目内容-边框内容数据格式
                    NSString *setEdging = [self getItemEdgeContent:textModel];
                    //拼接边框内容
                    colorTextModel32Str = [colorTextModel32Str stringByAppendingString:setEdging];
                }
                //拼接每个对象包括内容、颜色、边框组合
                sendItem = [sendItem stringByAppendingString:colorTextModel32Str];
            }
            
        }
        
        // 4.2拼接 - 涂鸦内容数据格式
        if(colorItemModel32.graffitiModel32Arr.count > 0){
            
            
            for (int i = 0; i < colorItemModel32.graffitiModel32Arr.count; i++) {
                NSString *graffitiModel32Str = @"";
                
                GraffitiModel32 *graffitiModel = colorItemModel32.graffitiModel32Arr[i];
                
                //涂鸦内容数据
                NSString *setGraffiti = [self getGraffitiContent:graffitiModel];
                
                graffitiModel32Str = [graffitiModel32Str stringByAppendingString:setGraffiti];
                
                sendItem = [sendItem stringByAppendingString:graffitiModel32Str];
            }
            
        }
        
        // 4.3拼接 - 动画内容数据格式
        if(colorItemModel32.animationModel32Arr.count > 0){
            for (int i = 0; i < colorItemModel32.animationModel32Arr.count; i++) {
                NSString *animationModel32Str = @"";
                
                AnimationModel32 *animationModel = colorItemModel32.animationModel32Arr[i];
                
                //动画内容数据
                NSString *setAnimation = [self getAnimationContent:animationModel];
                
                animationModel32Str = [animationModel32Str stringByAppendingString:setAnimation];
                
                sendItem = [sendItem stringByAppendingString:animationModel32Str];
            }
        }
        
        // 10.3.6.1拼接 - 数字结构时间组件
        if(colorItemModel32.clockTimeModelArr.count > 0){
            for (int i = 0; i < colorItemModel32.clockTimeModelArr.count; i++) {
                NSString *clockTimeModelStr = @"";
                
                ClockTime *animationModel = colorItemModel32.clockTimeModelArr[i];
                
                //数字结构时间组件
                NSString *setClockTime = [self getClockTimeContent:animationModel];
                
                clockTimeModelStr = [clockTimeModelStr stringByAppendingString:setClockTime];
                
                sendItem = [sendItem stringByAppendingString:clockTimeModelStr];
            }
        }
        
        // 10.3.7拼接 - 日期组件数据格式
        if(colorItemModel32.dateTimeModelArr.count > 0){
            for (int i = 0; i < colorItemModel32.dateTimeModelArr.count; i++) {
                NSString *dateTimeModelStr = @"";
                
                DateTime *dateTime = colorItemModel32.dateTimeModelArr[i];
                
                //日期组件数据格式
                NSString *setDateTime = [self getDateTimeContent:dateTime];
                
                dateTimeModelStr = [dateTimeModelStr stringByAppendingString:setDateTime];
                
                sendItem = [sendItem stringByAppendingString:dateTimeModelStr];
            }
        }
        
        // 10.3.8拼接 - 计时器组件数据格式
        if(colorItemModel32.countdownModelArr.count > 0){
            for (int i = 0; i < colorItemModel32.countdownModelArr.count; i++) {
                NSString *countdownModelStr = @"";
                
                Countdown *countdown = colorItemModel32.countdownModelArr[i];
                
                //计时器组件数据格式
                NSString *setCountdown = [self getCountdownContent:countdown];
                
                countdownModelStr = [countdownModelStr stringByAppendingString:setCountdown];
                
                sendItem = [sendItem stringByAppendingString:countdownModelStr];
            }
        }
        
        // 11.3.9拼接 - 计分板组件数据格式
        if(colorItemModel32.scoreboardModelArr.count > 0){
            for (int i = 0; i < colorItemModel32.scoreboardModelArr.count; i++) {
                NSString *scoreboardModelStr = @"";
                
                Scoreboard *scoreboard = colorItemModel32.scoreboardModelArr[i];
                
                //日期组件数据格式
                NSString *setScoreboard = [self getScoreboardContent:scoreboard];
                
                scoreboardModelStr = [scoreboardModelStr stringByAppendingString:setScoreboard];
                
                sendItem = [sendItem stringByAppendingString:scoreboardModelStr];
            }
        }
        
    }else if ([CurrentDeviceType isEqual:@"CoolLEDC"]){
        
        // 4.1拼接 - 节目对象（内容、颜色、边框组合部分）
        if(colorItemModel32.colorTextModel32Arr.count > 0){
            
            for (int i = 0; i < colorItemModel32.colorTextModel32Arr.count; i++) {
                NSString *colorTextModel32Str = @"";
                
                ColorTextModel32 *textModel = colorItemModel32.colorTextModel32Arr[i];
                NSArray *textItems = textModel.textItems;
                
                //允许边框单独存在，判断是否有内容
                if(![textModel isOnlyEdge]){
                    //A.设置节目内容-文字内容数据格式
                    NSDictionary *result = [self getItemWordContent:textModel deviceCols:textModel.widthData isLargeEdge:isLargeEdge];
                    NSString *sendText = result[@"sendText"];
                    
                    //拼接字体内容
                    colorTextModel32Str = [colorTextModel32Str stringByAppendingString:sendText];
                }
                
                if(textModel.isEdge){
                    //D.设置节目内容-边框内容数据格式
                    NSString *setEdging = [self getItemEdgeContent:textModel];
                    //拼接边框内容
                    colorTextModel32Str = [colorTextModel32Str stringByAppendingString:setEdging];
                }
                //拼接每个对象包括内容、颜色、边框组合
                sendItem = [sendItem stringByAppendingString:colorTextModel32Str];
            }
            
        }
    }
    
    return sendItem;
}

@end
