//
//  AnimationModel32.m
//  CoolLED1248
//
//  Created by 君同 on 2023/4/25.
//  Copyright © 2023 Haley. All rights reserved.
//

#import "AnimationModel32.h"
#import "DNApplication.h"
#import "Const_Header.h"
#import "ThemManager.h"

@implementation AnimationModel32

- (instancetype)init
{
    if (self = [super init]) {
        self.coverTypeAnimation = 1;
        self.startRowAnimation = 0;
        self.startColAnimation = 0;
        self.widthDataAnimation = [currentColNum intValue];
        self.heightDataAnimation = 32;
        self.timeIntervalAnimation = 200;
        
        self.dataAnimation = [[NSArray alloc] init];
        self.frameEveInterval = [[NSArray alloc] init];
    }
    return self;
}


- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.dataAnimation forKey:@"dataAnimation"];
    [coder encodeObject:self.frameEveInterval forKey:@"frameEveInterval"];
    
    [coder encodeInt:self.coverTypeAnimation forKey:@"coverTypeAnimation"];
    [coder encodeInt:self.startRowAnimation forKey:@"startRowAnimation"];
    [coder encodeInt:self.startColAnimation forKey:@"startColAnimation"];
    [coder encodeInt:self.widthDataAnimation forKey:@"widthDataAnimation"];
    [coder encodeInt:self.heightDataAnimation forKey:@"heightDataAnimation"];
    [coder encodeInt:self.timeIntervalAnimation forKey:@"timeIntervalAnimation"];
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        //解档
        self.dataAnimation = [coder decodeObjectForKey:@"dataAnimation"];
        self.frameEveInterval = [coder decodeObjectForKey:@"frameEveInterval"];
        
        self.coverTypeAnimation = [coder decodeIntForKey:@"coverTypeAnimation"];
        self.startRowAnimation = [coder decodeIntForKey:@"startRowAnimation"];
        self.startColAnimation = [coder decodeIntForKey:@"startColAnimation"];
        self.widthDataAnimation = [coder decodeIntForKey:@"widthDataAnimation"];
        self.heightDataAnimation = [coder decodeIntForKey:@"heightDataAnimation"];
        self.timeIntervalAnimation = [coder decodeIntForKey:@"timeIntervalAnimation"];
    }
    return self;
}

@end
