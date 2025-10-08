//
//  HLTextItem.h
//  CoolLED1248
//
//  Created by Harvey on 2020/11/6.
//  Copyright © 2020 Haley. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, HLTextItemType) {
    HLTextItemTypeText,     // 文字
    HLTextItemTypeEmoji     // 表情
};

@interface HLTextItem : NSObject<NSCoding>

@property (nonatomic, assign) HLTextItemType itemType;

@property (nonatomic, copy) NSString *text;

@property (nonatomic, strong) NSDictionary *emojiDict;

@end

