//
//  HLColorTextItem.m
//  CoolLED1248
//
//  Created by Harvey on 2020/11/3.
//  Copyright © 2020 Haley. All rights reserved.
//

#import "HLColorTextItem.h"

@implementation HLColorTextItem

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeInteger:self.itemType forKey:@"itemType"];
    [coder encodeObject:self.text forKey:@"text"];
    [coder encodeObject:self.rgbString forKey:@"rgbString"];
    [coder encodeObject:self.emojiDict forKey:@"emojiDict"];
    [coder encodeInteger:self.languageType forKey:@"languageType"];
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        //解档
        self.itemType = [coder decodeIntegerForKey:@"itemType"];
        self.text = [coder decodeObjectForKey:@"text"];
        self.rgbString = [coder decodeObjectForKey:@"rgbString"];
        self.emojiDict = [coder decodeObjectForKey:@"emojiDict"];
        self.languageType = [coder decodeIntegerForKey:@"languageType"];
    }
    return self;
}

@end
