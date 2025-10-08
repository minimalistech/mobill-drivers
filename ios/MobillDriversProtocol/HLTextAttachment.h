//
//  HLTextAttachment.h
//  CoolLED1248
//
//  Created by Harvey on 2020/11/1.
//  Copyright © 2020 Haley. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HLTextAttachment : NSTextAttachment

@property (nonatomic, copy) NSString *emoji_text;

@property (nonatomic, strong) NSDictionary *emojiDict;

@end

