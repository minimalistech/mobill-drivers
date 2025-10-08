//
//  Countdown.m
//  CoolLED1248
//
//  Created by go on 10/24/24.
//  Copyright © 2024 Haley. All rights reserved.
//

#import "Countdown.h"

@implementation Countdown

- (instancetype)init
{
    if (self = [super init]) {
        
    }
    return self;
}


- (void)encodeWithCoder:(NSCoder *)coder {
    
    [coder encodeInt:self.coverTypeCountdown forKey:@"coverTypeCountdown"];
    [coder encodeInt:self.modeCountdown forKey:@"modeCountdown"];
    
    [coder encodeInt:self.numHeightCountdown forKey:@"numHeightCountdown"];
    [coder encodeInt:self.numWidthCountdown forKey:@"numWidthCountdown"];
    [coder encodeInt:self.numDataLenCountdown forKey:@"numDataLenCountdown"];
    [coder encodeObject:self.numDataCountdown forKey:@"numDataCountdown"];
    
    [coder encodeInt:self.hourColorCountdown forKey:@"hourColorCountdown"];
    [coder encodeInt:self.hourStartColumnCountdown forKey:@"hourStartColumnCountdown"];
    [coder encodeInt:self.hourStartRowCountdown forKey:@"hourStartRowCountdown"];
    [coder encodeInt:self.hourWidthCountdown forKey:@"hourWidthCountdown"];
    [coder encodeInt:self.hourHeightCountdown forKey:@"hourHeightCountdown"];

    [coder encodeInt:self.spacehColorCountdown forKey:@"spacehColorCountdown"];
    [coder encodeInt:self.spacehStartColumnCountdown forKey:@"spacehStartColumnCountdown"];
    [coder encodeInt:self.spacehStartRowCountdown forKey:@"spacehStartRowCountdown"];
    [coder encodeInt:self.spacehWidthCountdown forKey:@"spacehWidthCountdown"];
    [coder encodeInt:self.spacehHeightCountdown forKey:@"spacehHeightCountdown"];
    [coder encodeInt:self.spacehDataLenCountdown forKey:@"spacehDataLenCountdown"];
    [coder encodeObject:self.spacehDataCountdown forKey:@"spacehDataCountdown"];
    
    [coder encodeInt:self.minColorCountdown forKey:@"minColorCountdown"];
    [coder encodeInt:self.minStartColumnCountdown forKey:@"minStartColumnCountdown"];
    [coder encodeInt:self.minStartRowCountdown forKey:@"minStartRowCountdown"];
    [coder encodeInt:self.minWidthCountdown forKey:@"minWidthCountdown"];
    [coder encodeInt:self.minHeightCountdown forKey:@"minHeightCountdown"];
    
    [coder encodeInt:self.spacemColorCountdown forKey:@"spacemColorCountdown"];
    [coder encodeInt:self.spacemStartColumnCountdown forKey:@"spacemStartColumnCountdown"];
    [coder encodeInt:self.spacemStartRowCountdown forKey:@"spacemStartRowCountdown"];
    [coder encodeInt:self.spacemWidthCountdown forKey:@"spacemWidthCountdown"];
    [coder encodeInt:self.spacemHeightCountdown forKey:@"spacemHeightCountdown"];
    [coder encodeInt:self.spacemDataLenCountdown forKey:@"spacemDataLenCountdown"];
    [coder encodeObject:self.spacemDataCountdown forKey:@"spacemDataCountdown"];
    
    [coder encodeInt:self.secColorCountdown forKey:@"secColorCountdown"];
    [coder encodeInt:self.secStartColumnCountdown forKey:@"secStartColumnCountdown"];
    [coder encodeInt:self.secStartRowCountdown forKey:@"secStartRowCountdown"];
    [coder encodeInt:self.secWidthCountdown forKey:@"secWidthCountdown"];
    [coder encodeInt:self.secHeightCountdown forKey:@"secHeightCountdown"];
    
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        //解档
        self.coverTypeCountdown = [coder decodeIntForKey:@"coverTypeCountdown"];
        self.modeCountdown = [coder decodeIntForKey:@"modeCountdown"];
        
        self.numHeightCountdown = [coder decodeIntForKey:@"numHeightCountdown"];
        self.numWidthCountdown = [coder decodeIntForKey:@"numWidthCountdown"];
        self.numDataLenCountdown = [coder decodeIntForKey:@"numDataLenCountdown"];
        self.numDataCountdown = [coder decodeObjectForKey:@"numDataCountdown"];
        
        self.hourColorCountdown = [coder decodeIntForKey:@"hourColorCountdown"];
        self.hourStartColumnCountdown = [coder decodeIntForKey:@"hourStartColumnCountdown"];
        self.hourStartRowCountdown = [coder decodeIntForKey:@"hourStartRowCountdown"];
        self.hourWidthCountdown = [coder decodeIntForKey:@"hourWidthCountdown"];
        self.hourHeightCountdown = [coder decodeIntForKey:@"hourHeightCountdown"];
        
        self.spacehColorCountdown = [coder decodeIntForKey:@"spacehColorCountdown"];
        self.spacehStartColumnCountdown = [coder decodeIntForKey:@"spacehStartColumnCountdown"];
        self.spacehStartRowCountdown = [coder decodeIntForKey:@"spacehStartRowCountdown"];
        self.spacehWidthCountdown = [coder decodeIntForKey:@"spacehWidthCountdown"];
        self.spacehHeightCountdown = [coder decodeIntForKey:@"spacehHeightCountdown"];
        self.spacehDataLenCountdown = [coder decodeIntForKey:@"spacehDataLenCountdown"];
        self.spacehDataCountdown = [coder decodeObjectForKey:@"spacehDataCountdown"];
        
        self.minColorCountdown = [coder decodeIntForKey:@"minColorCountdown"];
        self.minStartColumnCountdown = [coder decodeIntForKey:@"minStartColumnCountdown"];
        self.minStartRowCountdown = [coder decodeIntForKey:@"minStartRowCountdown"];
        self.minWidthCountdown = [coder decodeIntForKey:@"minWidthCountdown"];
        self.minHeightCountdown = [coder decodeIntForKey:@"minHeightCountdown"];
        
        self.spacemColorCountdown = [coder decodeIntForKey:@"spacemColorCountdown"];
        self.spacemStartColumnCountdown = [coder decodeIntForKey:@"spacemStartColumnCountdown"];
        self.spacemStartRowCountdown = [coder decodeIntForKey:@"spacemStartRowCountdown"];
        self.spacemWidthCountdown = [coder decodeIntForKey:@"spacemWidthCountdown"];
        self.spacemHeightCountdown = [coder decodeIntForKey:@"spacemHeightCountdown"];
        self.spacemDataLenCountdown = [coder decodeIntForKey:@"spacemDataLenCountdown"];
        self.spacemDataCountdown = [coder decodeObjectForKey:@"spacemDataCountdown"];
        
        self.secColorCountdown = [coder decodeIntForKey:@"secColorCountdown"];
        self.secStartColumnCountdown = [coder decodeIntForKey:@"secStartColumnCountdown"];
        self.secStartRowCountdown = [coder decodeIntForKey:@"secStartRowCountdown"];
        self.secWidthCountdown = [coder decodeIntForKey:@"secWidthCountdown"];
        self.secHeightCountdown = [coder decodeIntForKey:@"secHeightCountdown"];
    }
    return self;
}

@end
