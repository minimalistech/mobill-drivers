//
//  HLColorTextItem.h
//  CoolLED1248
//
//  Created by Harvey on 2020/11/3.
//  Copyright © 2020 Haley. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HLTextItem.h"

@interface HLColorTextItem : NSObject<NSCoding>

@property (nonatomic, assign) HLTextItemType itemType;

@property (nonatomic, copy) NSString *text;
@property (nonatomic, copy) NSString *rgbString;

@property (nonatomic, strong) NSDictionary *emojiDict;

//语言类别，0通用，1泰语，2印地语,3阿拉伯语
@property (nonatomic, assign) NSInteger languageType;

@end

