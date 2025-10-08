//
//  HLTextModel.m
//  CoolLED1248
//
//  Created by Harvey on 2020/11/6.
//  Copyright © 2020 Haley. All rights reserved.
//

#import "HLTextModel.h"

@implementation HLTextModel

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.originText forKey:@"originText"];
    [coder encodeObject:self.textItems forKey:@"textItems"];
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        //解档
        self.originText = [coder decodeObjectForKey:@"originText"];
        self.textItems = [coder decodeObjectForKey:@"textItems"];
    }
    return self;
}

@end
