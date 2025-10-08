//
//  HLTextItem.m
//  CoolLED1248
//
//  Created by Harvey on 2020/11/6.
//  Copyright © 2020 Haley. All rights reserved.
//

#import "HLTextItem.h"

@implementation HLTextItem

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeInteger:self.itemType forKey:@"itemType"];
    [coder encodeObject:self.text forKey:@"text"];
    [coder encodeObject:self.emojiDict forKey:@"emojiDict"];
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        //解档
        self.itemType = [coder decodeIntegerForKey:@"itemType"];
        self.text = [coder decodeObjectForKey:@"text"];
        self.emojiDict = [coder decodeObjectForKey:@"emojiDict"];
    }
    return self;
}


@end
