//
//  ColorItemModel32.m
//  CoolLED1248
//
//  Created by 君同 on 2023/3/13.
//  Copyright © 2023 Haley. All rights reserved.
//

#import "ColorItemModel32.h"

@implementation ColorItemModel32

- (instancetype)init
{
    if (self = [super init]) {
        self.timestampInMilliseconds = (NSInteger)([[NSDate date] timeIntervalSince1970] * 1000);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeInteger:self.timestampInMilliseconds forKey:@"timestampInMilliseconds"];
    [coder encodeObject:self.itemDeviceIdentify forKey:@"itemDeviceIdentify"];

    [coder encodeInt:self.itemContentCount forKey:@"itemContentCount"];
    [coder encodeInt:self.itemShowTime forKey:@"itemShowTime"];
    [coder encodeBool:self.isSelected forKey:@"isSelected"];
    [coder encodeInt:self.selectIndex forKey:@"selectIndex"];
    [coder encodeBool:self.isSelectedState forKey:@"isSelectedState"];
    [coder encodeObject:self.itemName forKey:@"itemName"];
    
    [coder encodeInt:self.masterplateCaseType forKey:@"masterplateCaseType"];
    [coder encodeObject:self.colorTextModel32Arr forKey:@"colorTextModel32Arr"];
    [coder encodeObject:self.graffitiImageName32Arr forKey:@"graffitiImageName32Arr"];
    [coder encodeObject:self.graffitiModel32Arr forKey:@"graffitiModel32Arr"];
    [coder encodeObject:self.animationGIFName32Arr forKey:@"animationGIFName32Arr"];
    [coder encodeObject:self.animationModel32Arr forKey:@"animationModel32Arr"];
    [coder encodeObject:self.clockTimeModelArr forKey:@"clockTimeModelArr"];
    [coder encodeObject:self.dateTimeModelArr forKey:@"dateTimeModelArr"];
    [coder encodeObject:self.scoreboardModelArr forKey:@"scoreboardModelArr"];
    [coder encodeObject:self.countdownModelArr forKey:@"countdownModelArr"];
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        //解档
        self.timestampInMilliseconds = [coder decodeIntegerForKey:@"timestampInMilliseconds"];
        self.itemDeviceIdentify = [coder decodeObjectForKey:@"itemDeviceIdentify"];
        
        self.itemContentCount = [coder decodeIntForKey:@"itemContentCount"];
        self.itemShowTime = [coder decodeIntForKey:@"itemShowTime"];
        self.isSelected = [coder decodeBoolForKey:@"isSelected"];
        self.selectIndex = [coder decodeIntForKey:@"selectIndex"];
        self.isSelectedState = [coder decodeBoolForKey:@"isSelectedState"];
        self.itemName = [coder decodeObjectForKey:@"itemName"];
        
        self.masterplateCaseType = [coder decodeIntForKey:@"masterplateCaseType"];
        self.colorTextModel32Arr = [coder decodeObjectForKey:@"colorTextModel32Arr"];
        self.graffitiImageName32Arr = [coder decodeObjectForKey:@"graffitiImageName32Arr"];
        self.graffitiModel32Arr = [coder decodeObjectForKey:@"graffitiModel32Arr"];
        self.animationGIFName32Arr = [coder decodeObjectForKey:@"animationGIFName32Arr"];
        self.animationModel32Arr = [coder decodeObjectForKey:@"animationModel32Arr"];
        self.clockTimeModelArr = [coder decodeObjectForKey:@"clockTimeModelArr"];
        self.dateTimeModelArr = [coder decodeObjectForKey:@"dateTimeModelArr"];
        self.scoreboardModelArr = [coder decodeObjectForKey:@"scoreboardModelArr"];
        self.countdownModelArr = [coder decodeObjectForKey:@"countdownModelArr"];
    }
    return self;
}
@end
