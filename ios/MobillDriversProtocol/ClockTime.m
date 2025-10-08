//
//  ClockTime.m
//  CoolLED1248
//
//  Created by go on 9/20/24.
//  Copyright © 2024 Haley. All rights reserved.
//

#import "ClockTime.h"

@implementation ClockTime

- (instancetype)init
{
    if (self = [super init]) {
        
    }
    return self;
}


- (void)encodeWithCoder:(NSCoder *)coder {
    
    [coder encodeInt:self.coverTypeClockTime forKey:@"coverTypeClockTime"];
    [coder encodeInt:self.timeFlagClockTime forKey:@"timeFlagClockTime"];
    [coder encodeInt:self.showTimeClockTime forKey:@"showTimeClockTime"];
    [coder encodeInt:self.numHeightClockTime forKey:@"numHeightClockTime"];
    [coder encodeInt:self.numWidthClockTime forKey:@"numWidthClockTime"];
    [coder encodeInt:self.numDataLenClockTime forKey:@"numDataLenClockTime"];
    [coder encodeObject:self.numDataClockTime forKey:@"numDataClockTime"];
    
    [coder encodeInt:self.hourColorClockTime forKey:@"hourColorClockTime"];
    [coder encodeInt:self.hourStartColumnClockTime forKey:@"hourStartColumnClockTime"];
    [coder encodeInt:self.hourStartRowClockTime forKey:@"hourStartRowClockTime"];
    [coder encodeInt:self.hourWidthClockTime forKey:@"hourWidthClockTime"];
    [coder encodeInt:self.hourHeightClockTime forKey:@"hourHeightClockTime"];

    [coder encodeInt:self.spacehColorClockTime forKey:@"spacehColorClockTime"];
    [coder encodeInt:self.spacehStartColumnClockTime forKey:@"spacehStartColumnClockTime"];
    [coder encodeInt:self.spacehStartRowClockTime forKey:@"spacehStartRowClockTime"];
    [coder encodeInt:self.spacehWidthClockTime forKey:@"spacehWidthClockTime"];
    [coder encodeInt:self.spacehHeightClockTime forKey:@"spacehHeightClockTime"];
    [coder encodeInt:self.spacehDataLenClockTime forKey:@"spacehDataLenClockTime"];
    [coder encodeObject:self.spacehDataClockTime forKey:@"spacehDataClockTime"];
    
    [coder encodeInt:self.minColorClockTime forKey:@"minColorClockTime"];
    [coder encodeInt:self.minStartColumnClockTime forKey:@"minStartColumnClockTime"];
    [coder encodeInt:self.minStartRowClockTime forKey:@"minStartRowClockTime"];
    [coder encodeInt:self.minWidthClockTime forKey:@"minWidthClockTime"];
    [coder encodeInt:self.minHeightClockTime forKey:@"minHeightClockTime"];
    
    [coder encodeInt:self.spacemColorClockTime forKey:@"spacemColorClockTime"];
    [coder encodeInt:self.spacemStartColumnClockTime forKey:@"spacemStartColumnClockTime"];
    [coder encodeInt:self.spacemStartRowClockTime forKey:@"spacemStartRowClockTime"];
    [coder encodeInt:self.spacemWidthClockTime forKey:@"spacemWidthClockTime"];
    [coder encodeInt:self.spacemHeightClockTime forKey:@"spacemHeightClockTime"];
    [coder encodeInt:self.spacemDataLenClockTime forKey:@"spacemDataLenClockTime"];
    [coder encodeObject:self.spacemDataClockTime forKey:@"spacemDataClockTime"];
    
    [coder encodeInt:self.secColorClockTime forKey:@"secColorClockTime"];
    [coder encodeInt:self.secStartColumnClockTime forKey:@"secStartColumnClockTime"];
    [coder encodeInt:self.secStartRowClockTime forKey:@"secStartRowClockTime"];
    [coder encodeInt:self.secWidthClockTime forKey:@"secWidthClockTime"];
    [coder encodeInt:self.secHeightClockTime forKey:@"secHeightClockTime"];
    
    [coder encodeInt:self.ampmColorClockTime forKey:@"ampmColorClockTime"];
    [coder encodeInt:self.ampmStartColumnClockTime forKey:@"ampmStartColumnClockTime"];
    [coder encodeInt:self.ampmStartRowClockTime forKey:@"ampmStartRowClockTime"];
    [coder encodeInt:self.ampmWidthClockTime forKey:@"ampmWidthClockTime"];
    [coder encodeInt:self.ampmHeightClockTime forKey:@"ampmHeightClockTime"];
    [coder encodeInt:self.ampmDataLenClockTime forKey:@"ampmDataLenClockTime"];
    [coder encodeObject:self.ampmDataClockTime forKey:@"ampmDataClockTime"];
    
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        //解档
        self.coverTypeClockTime = [coder decodeIntForKey:@"coverTypeClockTime"];
        self.timeFlagClockTime = [coder decodeIntForKey:@"timeFlagClockTime"];
        self.showTimeClockTime = [coder decodeIntForKey:@"showTimeClockTime"];
        self.numHeightClockTime = [coder decodeIntForKey:@"numHeightClockTime"];
        self.numWidthClockTime = [coder decodeIntForKey:@"numWidthClockTime"];
        self.numDataLenClockTime = [coder decodeIntForKey:@"numDataLenClockTime"];
        self.numDataClockTime = [coder decodeObjectForKey:@"numDataClockTime"];
        
        self.hourColorClockTime = [coder decodeIntForKey:@"hourColorClockTime"];
        self.hourStartColumnClockTime = [coder decodeIntForKey:@"hourStartColumnClockTime"];
        self.hourStartRowClockTime = [coder decodeIntForKey:@"hourStartRowClockTime"];
        self.hourWidthClockTime = [coder decodeIntForKey:@"hourWidthClockTime"];
        self.hourHeightClockTime = [coder decodeIntForKey:@"hourHeightClockTime"];
        
        self.spacehColorClockTime = [coder decodeIntForKey:@"spacehColorClockTime"];
        self.spacehStartColumnClockTime = [coder decodeIntForKey:@"spacehStartColumnClockTime"];
        self.spacehStartRowClockTime = [coder decodeIntForKey:@"spacehStartRowClockTime"];
        self.spacehWidthClockTime = [coder decodeIntForKey:@"spacehWidthClockTime"];
        self.spacehHeightClockTime = [coder decodeIntForKey:@"spacehHeightClockTime"];
        self.spacehDataLenClockTime = [coder decodeIntForKey:@"spacehDataLenClockTime"];
        self.spacehDataClockTime = [coder decodeObjectForKey:@"spacehDataClockTime"];
        
        self.minColorClockTime = [coder decodeIntForKey:@"minColorClockTime"];
        self.minStartColumnClockTime = [coder decodeIntForKey:@"minStartColumnClockTime"];
        self.minStartRowClockTime = [coder decodeIntForKey:@"minStartRowClockTime"];
        self.minWidthClockTime = [coder decodeIntForKey:@"minWidthClockTime"];
        self.minHeightClockTime = [coder decodeIntForKey:@"minHeightClockTime"];
        
        self.spacemColorClockTime = [coder decodeIntForKey:@"spacemColorClockTime"];
        self.spacemStartColumnClockTime = [coder decodeIntForKey:@"spacemStartColumnClockTime"];
        self.spacemStartRowClockTime = [coder decodeIntForKey:@"spacemStartRowClockTime"];
        self.spacemWidthClockTime = [coder decodeIntForKey:@"spacemWidthClockTime"];
        self.spacemHeightClockTime = [coder decodeIntForKey:@"spacemHeightClockTime"];
        self.spacemDataLenClockTime = [coder decodeIntForKey:@"spacemDataLenClockTime"];
        self.spacemDataClockTime = [coder decodeObjectForKey:@"spacemDataClockTime"];
        
        self.secColorClockTime = [coder decodeIntForKey:@"secColorClockTime"];
        self.secStartColumnClockTime = [coder decodeIntForKey:@"secStartColumnClockTime"];
        self.secStartRowClockTime = [coder decodeIntForKey:@"secStartRowClockTime"];
        self.secWidthClockTime = [coder decodeIntForKey:@"secWidthClockTime"];
        self.secHeightClockTime = [coder decodeIntForKey:@"secHeightClockTime"];
        
        self.ampmColorClockTime = [coder decodeIntForKey:@"ampmColorClockTime"];
        self.ampmStartColumnClockTime = [coder decodeIntForKey:@"ampmStartColumnClockTime"];
        self.ampmStartRowClockTime = [coder decodeIntForKey:@"ampmStartRowClockTime"];
        self.ampmWidthClockTime = [coder decodeIntForKey:@"ampmWidthClockTime"];
        self.ampmHeightClockTime = [coder decodeIntForKey:@"ampmHeightClockTime"];
        self.ampmDataLenClockTime = [coder decodeIntForKey:@"ampmDataLenClockTime"];
        self.ampmDataClockTime = [coder decodeObjectForKey:@"ampmDataClockTime"];
    }
    return self;
}

@end
