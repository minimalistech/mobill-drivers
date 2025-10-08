//
//  EyeItemModel.m
//  CoolLED1248
//
//  Created by go on 1/7/25.
//  Copyright © 2025 Haley. All rights reserved.
//

#import "EyeItemModel.h"

@implementation EyeItemModel

- (instancetype)init
{
    if (self = [super init]) {
        self.timestampInMillisecondsEye = (NSInteger)([[NSDate date] timeIntervalSince1970] * 1000);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeInteger:self.timestampInMillisecondsEye forKey:@"timestampInMillisecondsEye"];
    [coder encodeObject:self.itemDeviceIdentifyEye forKey:@"itemDeviceIdentifyEye"];

    [coder encodeInt:self.itemShowTimeEye forKey:@"itemShowTimeEye"];
    [coder encodeBool:self.isSelectedEye forKey:@"isSelectedEye"];
    [coder encodeInt:self.selectIndexEye forKey:@"selectIndexEye"];
    
    [coder encodeObject:self.textModelEyeL forKey:@"textModelEyeL"];
    [coder encodeObject:self.textModelEyeR forKey:@"textModelEyeR"];
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        //解档
        self.timestampInMillisecondsEye = [coder decodeIntegerForKey:@"timestampInMillisecondsEye"];
        self.itemDeviceIdentifyEye = [coder decodeObjectForKey:@"itemDeviceIdentifyEye"];
        
        self.itemShowTimeEye = [coder decodeIntForKey:@"itemShowTimeEye"];
        self.isSelectedEye = [coder decodeBoolForKey:@"isSelectedEye"];
        self.selectIndexEye = [coder decodeIntForKey:@"selectIndexEye"];
        
        self.textModelEyeL = [coder decodeObjectForKey:@"textModelEyeL"];
        self.textModelEyeR = [coder decodeObjectForKey:@"textModelEyeR"];
    }
    return self;
}

@end
