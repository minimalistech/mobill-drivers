//
//  DateTime.m
//  CoolLED1248
//
//  Created by go on 9/20/24.
//  Copyright © 2024 Haley. All rights reserved.
//

#import "DateTime.h"

@implementation DateTime

- (instancetype)init
{
    if (self = [super init]) {
        
    }
    return self;
}


- (void)encodeWithCoder:(NSCoder *)coder {
    
    
    [coder encodeInt:self.coverTypeDateTime forKey:@"coverTypeDateTime"];
    [coder encodeInt:self.dateFlagDateTime forKey:@"dateFlagDateTime"];
    [coder encodeInt:self.showTimeDateTime forKey:@"showTimeDateTime"];
    [coder encodeInt:self.numHeightDateTime forKey:@"numHeightDateTime"];
    [coder encodeInt:self.numWidthDateTime forKey:@"numWidthDateTime"];
    [coder encodeInt:self.numDataLenDateTime forKey:@"numDataLenDateTime"];
    [coder encodeObject:self.numDataDateTime forKey:@"numDataDateTime"];
    [coder encodeInt:self.yearNumHeightDateTime forKey:@"yearNumHeightDateTime"];
    [coder encodeInt:self.yearNumWidthDateTime forKey:@"yearNumWidthDateTime"];
    [coder encodeInt:self.yearNumDataLenDateTime forKey:@"yearNumDataLenDateTime"];
    [coder encodeObject:self.yearNumDataDateTime forKey:@"yearNumDataDateTime"];
    
    [coder encodeInt:self.yearColorDateTime forKey:@"yearColorDateTime"];
    [coder encodeInt:self.yearStartColumnDateTime forKey:@"yearStartColumnDateTime"];
    [coder encodeInt:self.yearStartRowDateTime forKey:@"yearStartRowDateTime"];
    [coder encodeInt:self.yearWidthDateTime forKey:@"yearWidthDateTime"];
    [coder encodeInt:self.yearHeightDateTime forKey:@"yearHeightDateTime"];
    
    [coder encodeInt:self.spaceyColorDateTime forKey:@"spacehColorDateTime"];
    [coder encodeInt:self.spaceyStartColumnDateTime forKey:@"spacehStartColumnDateTime"];
    [coder encodeInt:self.spaceyStartRowDateTime forKey:@"spacehStartRowDateTime"];
    [coder encodeInt:self.spaceyWidthDateTime forKey:@"spacehWidthDateTime"];
    [coder encodeInt:self.spaceyHeightDateTime forKey:@"spacehHeightDateTime"];
    [coder encodeInt:self.spaceyDataLenDateTime forKey:@"spacehDataLenDateTime"];
    [coder encodeObject:self.spaceyDataDateTime forKey:@"spacehDataDateTime"];
    
    [coder encodeInt:self.monColorDateTime forKey:@"monColorDateTime"];
    [coder encodeInt:self.monStartColumnDateTime forKey:@"monStartColumnDateTime"];
    [coder encodeInt:self.monStartRowDateTime forKey:@"monStartRowDateTime"];
    [coder encodeInt:self.monWidthateTime forKey:@"monWidthateTime"];
    [coder encodeInt:self.monHeightDateTime forKey:@"monHeightDateTime"];
    [coder encodeObject:self.monDataDateTime forKey:@"monDataDateTime"];
    
    [coder encodeInt:self.spacemColorDateTime forKey:@"spacemColorDateTime"];
    [coder encodeInt:self.spacemStartColumnDateTime forKey:@"spacemStartColumnDateTime"];
    [coder encodeInt:self.spacemStartRowDateTime forKey:@"spacemStartRowDateTime"];
    [coder encodeInt:self.spacemWidthDateTime forKey:@"spacemWidthDateTime"];
    [coder encodeInt:self.spacemHeightDateTime forKey:@"spacemHeightDateTime"];
    [coder encodeInt:self.spacemDataLenDateTime forKey:@"spacemDataLenDateTime"];
    [coder encodeObject:self.spacemDataDateTime forKey:@"spacemDataDateTime"];
    
    [coder encodeInt:self.dayColorDateTime forKey:@"dayColorDateTime"];
    [coder encodeInt:self.dayStartColumnDateTime forKey:@"dayStartColumnDateTime"];
    [coder encodeInt:self.dayStartRowDateTime forKey:@"dayStartRowDateTime"];
    [coder encodeInt:self.dayWidthDateTime forKey:@"dayWidthDateTime"];
    [coder encodeInt:self.dayHeightDateTime forKey:@"dayHeightDateTime"];

    [coder encodeInt:self.spacedColorDateTime forKey:@"spaceColorDateTime"];
    [coder encodeInt:self.spacedStartColumnDateTime forKey:@"spaceStartColumnDateTime"];
    [coder encodeInt:self.spacedStartRowDateTime forKey:@"spaceStartRowDateTime"];
    [coder encodeInt:self.spacedWidthDateTime forKey:@"spaceWidthDateTime"];
    [coder encodeInt:self.spacedHeightDateTime forKey:@"spaceHeightDateTime"];
    [coder encodeInt:self.spacedDataLenDateTime forKey:@"spaceDataLenDateTime"];
    [coder encodeObject:self.spacedDataDateTime forKey:@"spaceDataDateTime"];
    
    [coder encodeInt:self.weekColorDateTime forKey:@"weekColorDateTime"];
    [coder encodeInt:self.weekStartRowDateTime forKey:@"weekStartRowDateTime"];
    [coder encodeInt:self.weekStartColumnDateTime forKey:@"weekStartColumnDateTime"];
    [coder encodeInt:self.weekWidthDateTime forKey:@"weekWidthDateTime"];
    [coder encodeInt:self.weekHeightDateTime forKey:@"weekHeightDateTime"];
    [coder encodeInt:self.weekDataLenDateTime forKey:@"weekDataLenDateTime"];
    [coder encodeObject:self.weekDataDateTime forKey:@"weekDataDateTime"];
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        //解档
        self.coverTypeDateTime = [coder decodeIntForKey:@"coverTypeDateTime"];
        self.dateFlagDateTime = [coder decodeIntForKey:@"dateFlagDateTime"];
        self.showTimeDateTime = [coder decodeIntForKey:@"showTimeDateTime"];
        self.numHeightDateTime = [coder decodeIntForKey:@"numHeightDateTime"];
        self.numWidthDateTime = [coder decodeIntForKey:@"numWidthDateTime"];
        self.numDataLenDateTime = [coder decodeIntForKey:@"numDataLenDateTime"];
        self.numDataDateTime = [coder decodeObjectForKey:@"numDataDateTime"];
        self.yearNumHeightDateTime = [coder decodeIntForKey:@"yearNumHeightDateTime"];
        self.yearNumWidthDateTime = [coder decodeIntForKey:@"yearNumWidthDateTime"];
        self.yearNumDataLenDateTime = [coder decodeIntForKey:@"yearNumDataLenDateTime"];
        self.yearNumDataDateTime = [coder decodeObjectForKey:@"yearNumDataDateTime"];
        
        self.yearColorDateTime = [coder decodeIntForKey:@"yearColorDateTime"];
        self.yearStartColumnDateTime = [coder decodeIntForKey:@"yearStartColumnDateTime"];
        self.yearStartRowDateTime = [coder decodeIntForKey:@"yearStartRowDateTime"];
        self.yearWidthDateTime = [coder decodeIntForKey:@"yearWidthDateTime"];
        self.yearHeightDateTime = [coder decodeIntForKey:@"yearHeightDateTime"];
        
        self.spaceyColorDateTime = [coder decodeIntForKey:@"spacehColorDateTime"];
        self.spaceyStartColumnDateTime = [coder decodeIntForKey:@"spacehStartColumnDateTime"];
        self.spaceyStartRowDateTime = [coder decodeIntForKey:@"spacehStartRowDateTime"];
        self.spaceyWidthDateTime = [coder decodeIntForKey:@"spacehWidthDateTime"];
        self.spaceyHeightDateTime = [coder decodeIntForKey:@"spacehHeightDateTime"];
        self.spaceyDataLenDateTime = [coder decodeIntForKey:@"spacehDataLenDateTime"];
        self.spaceyDataDateTime = [coder decodeObjectForKey:@"spacehDataDateTime"];
        
        self.monColorDateTime = [coder decodeIntForKey:@"monColorDateTime"];
        self.monStartColumnDateTime = [coder decodeIntForKey:@"monStartColumnDateTime"];
        self.monStartRowDateTime = [coder decodeIntForKey:@"monStartRowDateTime"];
        self.monWidthateTime = [coder decodeIntForKey:@"monWidthateTime"];
        self.monHeightDateTime = [coder decodeIntForKey:@"monHeightDateTime"];
        self.monDataDateTime = [coder decodeObjectForKey:@"monDataDateTime"];
        
        self.spacemColorDateTime = [coder decodeIntForKey:@"spacemColorDateTime"];
        self.spacemStartColumnDateTime = [coder decodeIntForKey:@"spacemStartColumnDateTime"];
        self.spacemStartRowDateTime = [coder decodeIntForKey:@"spacemStartRowDateTime"];
        self.spacemWidthDateTime = [coder decodeIntForKey:@"spacemWidthDateTime"];
        self.spacemHeightDateTime = [coder decodeIntForKey:@"spacemHeightDateTime"];
        self.spacemDataLenDateTime = [coder decodeIntForKey:@"spacemDataLenDateTime"];
        self.spacemDataDateTime = [coder decodeObjectForKey:@"spacemDataDateTime"];
        
        self.dayColorDateTime = [coder decodeIntForKey:@"dayColorDateTime"];
        self.dayStartColumnDateTime = [coder decodeIntForKey:@"dayStartColumnDateTime"];
        self.dayStartRowDateTime = [coder decodeIntForKey:@"dayStartRowDateTime"];
        self.dayWidthDateTime = [coder decodeIntForKey:@"dayWidthDateTime"];
        self.dayHeightDateTime = [coder decodeIntForKey:@"dayHeightDateTime"];
        
        self.spacedColorDateTime = [coder decodeIntForKey:@"spaceColorDateTime"];
        self.spacedStartColumnDateTime = [coder decodeIntForKey:@"spaceStartColumnDateTime"];
        self.spacedStartRowDateTime = [coder decodeIntForKey:@"spaceStartRowDateTime"];
        self.spacedWidthDateTime = [coder decodeIntForKey:@"spaceWidthDateTime"];
        self.spacedHeightDateTime = [coder decodeIntForKey:@"spaceHeightDateTime"];
        self.spacedDataLenDateTime = [coder decodeIntForKey:@"spaceDataLenDateTime"];
        self.spacedDataDateTime = [coder decodeObjectForKey:@"spaceDataDateTime"];
        
        self.weekColorDateTime = [coder decodeIntForKey:@"weekColorDateTime"];
        self.weekStartRowDateTime = [coder decodeIntForKey:@"weekStartRowDateTime"];
        self.weekStartColumnDateTime = [coder decodeIntForKey:@"weekStartColumnDateTime"];
        self.weekWidthDateTime = [coder decodeIntForKey:@"weekWidthDateTime"];
        self.weekHeightDateTime = [coder decodeIntForKey:@"weekHeightDateTime"];
        self.weekDataLenDateTime = [coder decodeIntForKey:@"weekDataLenDateTime"];
        self.weekDataDateTime = [coder decodeObjectForKey:@"weekDataDateTime"];
    }
    return self;
}

@end
