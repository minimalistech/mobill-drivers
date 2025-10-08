//
//  GraffitiModel32.m
//  CoolLED1248
//
//  Created by 君同 on 2023/4/25.
//  Copyright © 2023 Haley. All rights reserved.
//

#import "GraffitiModel32.h"

@implementation GraffitiModel32

- (instancetype)init
{
    if (self = [super init]) {
        self.coverTypeGraffiti = 1;
        self.startRowGraffiti = 0;
        self.startColGraffiti = 0;
        self.widthDataGraffiti = 96;
        self.heightDataGraffiti = 32;
        self.showModelGraffiti = 1;
        self.speedDataGraffiti = 8;
        self.stayTimeGraffiti = 2;
        
        self.dataGraffiti = [[NSArray alloc] init];
    }
    return self;
}


- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.dataGraffiti forKey:@"dataGraffiti"];
    
    [coder encodeInt:self.coverTypeGraffiti forKey:@"coverTypeGraffiti"];
    [coder encodeInt:self.startRowGraffiti forKey:@"startRowGraffiti"];
    [coder encodeInt:self.startColGraffiti forKey:@"startColGraffiti"];
    [coder encodeInt:self.widthDataGraffiti forKey:@"widthDataGraffiti"];
    [coder encodeInt:self.heightDataGraffiti forKey:@"heightDataGraffiti"];
    [coder encodeInt:self.showModelGraffiti forKey:@"showModelGraffiti"];
    [coder encodeInt:self.speedDataGraffiti forKey:@"speedDataGraffiti"];
    [coder encodeInt:self.stayTimeGraffiti forKey:@"stayTimeGraffiti"];
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        //解档
        self.dataGraffiti = [coder decodeObjectForKey:@"dataGraffiti"];
        
        self.coverTypeGraffiti = [coder decodeIntForKey:@"coverTypeGraffiti"];
        self.startRowGraffiti = [coder decodeIntForKey:@"startRowGraffiti"];
        self.startColGraffiti = [coder decodeIntForKey:@"startColGraffiti"];
        self.widthDataGraffiti = [coder decodeIntForKey:@"widthDataGraffiti"];
        self.heightDataGraffiti = [coder decodeIntForKey:@"heightDataGraffiti"];
        self.showModelGraffiti = [coder decodeIntForKey:@"showModelGraffiti"];
        self.speedDataGraffiti = [coder decodeIntForKey:@"speedDataGraffiti"];
        self.stayTimeGraffiti = [coder decodeIntForKey:@"stayTimeGraffiti"];
    }
    return self;
}

@end
