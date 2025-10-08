//
//  Scoreboard.m
//  CoolLED1248
//
//  Created by go on 10/15/24.
//  Copyright © 2024 Haley. All rights reserved.
//

#import "Scoreboard.h"

@implementation Scoreboard

- (instancetype)init
{
    if (self = [super init]) {
        
    }
    return self;
}


- (void)encodeWithCoder:(NSCoder *)coder {
    
    [coder encodeInt:self.coverTypeScoreboard forKey:@"coverTypeScoreboard"];
    [coder encodeInt:self.secnumHeightScoreboard forKey:@"secnumHeightScoreboard"];
    [coder encodeInt:self.secnumWidthScoreboard forKey:@"secnumWidthScoreboard"];
    [coder encodeInt:self.secnumDataLenScoreboard forKey:@"secnumDataLenScoreboard"];
    [coder encodeObject:self.secnumDataScoreboard forKey:@"secnumDataScoreboard"];
    
    [coder encodeInt:self.hsColorScoreboard forKey:@"hsColorScoreboard"];
    [coder encodeInt:self.hsStartColumnScoreboard forKey:@"hsStartColumnScoreboard"];
    [coder encodeInt:self.hsStartRowScoreboard forKey:@"hsStartRowScoreboard"];
    [coder encodeInt:self.hsWidthScoreboard forKey:@"hsWidthScoreboard"];
    [coder encodeInt:self.hsHeightScoreboard forKey:@"hsHeightScoreboard"];
    
    [coder encodeInt:self.vsColorScoreboard forKey:@"vsColorScoreboard"];
    [coder encodeInt:self.vsStartColumnScoreboard forKey:@"vsStartColumnScoreboard"];
    [coder encodeInt:self.vsStartRowScoreboard forKey:@"vsStartRowScoreboard"];
    [coder encodeInt:self.vsWidthScoreboard forKey:@"vsWidthScoreboard"];
    [coder encodeInt:self.vsHeightScoreboard forKey:@"vsHeightScoreboard"];
    
    [coder encodeInt:self.totalnumHeightScoreboard forKey:@"totalnumHeightScoreboard"];
    [coder encodeInt:self.totalnumWidthScoreboard forKey:@"totalnumWidthScoreboard"];
    [coder encodeInt:self.totalnumDataLenScoreboard forKey:@"totalnumDataLenScoreboard"];
    [coder encodeObject:self.totalnumDataScoreboard forKey:@"totalnumDataScoreboard"];
    
    [coder encodeInt:self.htsColorScoreboard forKey:@"htsColorScoreboard"];
    [coder encodeInt:self.htsStartColumnScoreboard forKey:@"htsStartColumnScoreboard"];
    [coder encodeInt:self.htsStartRowScoreboard forKey:@"htsStartRowScoreboard"];
    [coder encodeInt:self.htsWidthScoreboard forKey:@"htsWidthScoreboard"];
    [coder encodeInt:self.htsHeightScoreboard forKey:@"htsHeightScoreboard"];
    
    [coder encodeInt:self.vtsColorScoreboard forKey:@"vtsColorScoreboard"];
    [coder encodeInt:self.vtsStartColumnScoreboard forKey:@"vtsStartColumnScoreboard"];
    [coder encodeInt:self.vtsStartRowScoreboard forKey:@"vtsStartRowScoreboard"];
    [coder encodeInt:self.vtsWidthScoreboard forKey:@"vtsWidthScoreboard"];
    [coder encodeInt:self.vtsHeightScoreboard forKey:@"vtsHeightScoreboard"];
    
    [coder encodeInt:self.timenumHeightScoreboard forKey:@"timenumHeightScoreboard"];
    [coder encodeInt:self.timenumWidthScoreboard forKey:@"timenumWidthScoreboard"];
    [coder encodeInt:self.timenumDataLenScoreboard forKey:@"timenumDataLenScoreboard"];
    [coder encodeObject:self.timenumDataScoreboard forKey:@"timenumDataScoreboard"];
    
    [coder encodeInt:self.minColorScoreboard forKey:@"minColorScoreboard"];
    [coder encodeInt:self.minStartColumnScoreboard forKey:@"minStartColumnScoreboard"];
    [coder encodeInt:self.minStartRowScoreboard forKey:@"minStartRowScoreboard"];
    [coder encodeInt:self.minWidthScoreboard forKey:@"minWidthScoreboard"];
    [coder encodeInt:self.minHeightScoreboard forKey:@"minHeightScoreboard"];
    
    [coder encodeInt:self.spacemColorScoreboard forKey:@"spacemColorScoreboard"];
    [coder encodeInt:self.spacemStartColumnScoreboard forKey:@"spacemStartColumnScoreboard"];
    [coder encodeInt:self.spacemStartRowScoreboard forKey:@"spacemStartRowScoreboard"];
    [coder encodeInt:self.spacemWidthScoreboard forKey:@"spacemWidthScoreboard"];
    [coder encodeInt:self.spacemHeightScoreboard forKey:@"spacemHeightScoreboard"];
    [coder encodeInt:self.spacemDataLenScoreboard forKey:@"spacemDataLenScoreboard"];
    [coder encodeObject:self.spacemDataScoreboard forKey:@"spacemDataScoreboard"];
    
    [coder encodeInt:self.secColorScoreboard forKey:@"secColorScoreboard"];
    [coder encodeInt:self.secStartColumnScoreboard forKey:@"secStartColumnScoreboard"];
    [coder encodeInt:self.secStartRowScoreboard forKey:@"secStartRowScoreboard"];
    [coder encodeInt:self.secWidthScoreboard forKey:@"secWidthScoreboard"];
    [coder encodeInt:self.secHeightScoreboard forKey:@"secHeightScoreboard"];
    
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        //解档
        self.coverTypeScoreboard = [coder decodeIntForKey:@"coverTypeScoreboard"];
        self.secnumHeightScoreboard = [coder decodeIntForKey:@"secnumHeightScoreboard"];
        self.secnumWidthScoreboard = [coder decodeIntForKey:@"secnumWidthScoreboard"];
        self.secnumDataLenScoreboard = [coder decodeIntForKey:@"secnumDataLenScoreboard"];
        self.secnumDataScoreboard = [coder decodeObjectForKey:@"secnumDataScoreboard"];
        
        self.hsColorScoreboard = [coder decodeIntForKey:@"hsColorScoreboard"];
        self.hsStartColumnScoreboard = [coder decodeIntForKey:@"hsStartColumnScoreboard"];
        self.hsStartRowScoreboard = [coder decodeIntForKey:@"hsStartRowScoreboard"];
        self.hsWidthScoreboard = [coder decodeIntForKey:@"hsWidthScoreboard"];
        self.hsHeightScoreboard = [coder decodeIntForKey:@"hsHeightScoreboard"];
        
        self.vsColorScoreboard = [coder decodeIntForKey:@"vsColorScoreboard"];
        self.vsStartColumnScoreboard = [coder decodeIntForKey:@"vsStartColumnScoreboard"];
        self.vsStartRowScoreboard = [coder decodeIntForKey:@"vsStartRowScoreboard"];
        self.vsWidthScoreboard = [coder decodeIntForKey:@"vsWidthScoreboard"];
        self.vsHeightScoreboard = [coder decodeIntForKey:@"vsHeightScoreboard"];
        
        self.totalnumHeightScoreboard = [coder decodeIntForKey:@"totalnumHeightScoreboard"];
        self.totalnumWidthScoreboard = [coder decodeIntForKey:@"totalnumWidthScoreboard"];
        self.totalnumDataLenScoreboard = [coder decodeIntForKey:@"totalnumDataLenScoreboard"];
        self.totalnumDataScoreboard = [coder decodeObjectForKey:@"totalnumDataScoreboard"];
        
        self.htsColorScoreboard = [coder decodeIntForKey:@"htsColorScoreboard"];
        self.htsStartColumnScoreboard = [coder decodeIntForKey:@"htsStartColumnScoreboard"];
        self.htsStartRowScoreboard = [coder decodeIntForKey:@"htsStartRowScoreboard"];
        self.htsWidthScoreboard = [coder decodeIntForKey:@"htsWidthScoreboard"];
        self.htsHeightScoreboard = [coder decodeIntForKey:@"htsHeightScoreboard"];
        
        self.vtsColorScoreboard = [coder decodeIntForKey:@"vtsColorScoreboard"];
        self.vtsStartColumnScoreboard = [coder decodeIntForKey:@"vtsStartColumnScoreboard"];
        self.vtsStartRowScoreboard = [coder decodeIntForKey:@"vtsStartRowScoreboard"];
        self.vtsWidthScoreboard = [coder decodeIntForKey:@"vtsWidthScoreboard"];
        self.vtsHeightScoreboard = [coder decodeIntForKey:@"vtsHeightScoreboard"];
        
        self.timenumHeightScoreboard = [coder decodeIntForKey:@"timenumHeightScoreboard"];
        self.timenumWidthScoreboard = [coder decodeIntForKey:@"timenumWidthScoreboard"];
        self.timenumDataLenScoreboard = [coder decodeIntForKey:@"timenumDataLenScoreboard"];
        self.timenumDataScoreboard = [coder decodeObjectForKey:@"timenumDataScoreboard"];
        
        self.minColorScoreboard = [coder decodeIntForKey:@"minColorScoreboard"];
        self.minStartColumnScoreboard = [coder decodeIntForKey:@"minStartColumnScoreboard"];
        self.minStartRowScoreboard = [coder decodeIntForKey:@"minStartRowScoreboard"];
        self.minWidthScoreboard = [coder decodeIntForKey:@"minWidthScoreboard"];
        self.minHeightScoreboard = [coder decodeIntForKey:@"minHeightScoreboard"];
        
        self.spacemColorScoreboard = [coder decodeIntForKey:@"spacemColorScoreboard"];
        self.spacemStartColumnScoreboard = [coder decodeIntForKey:@"spacemStartColumnScoreboard"];
        self.spacemStartRowScoreboard = [coder decodeIntForKey:@"spacemStartRowScoreboard"];
        self.spacemWidthScoreboard = [coder decodeIntForKey:@"spacemWidthScoreboard"];
        self.spacemHeightScoreboard = [coder decodeIntForKey:@"spacemHeightScoreboard"];
        self.spacemDataLenScoreboard = [coder decodeIntForKey:@"spacemDataLenScoreboard"];
        self.spacemDataScoreboard = [coder decodeObjectForKey:@"spacemDataScoreboard"];
        
        self.secColorScoreboard = [coder decodeIntForKey:@"secColorScoreboard"];
        self.secStartColumnScoreboard = [coder decodeIntForKey:@"secStartColumnScoreboard"];
        self.secStartRowScoreboard = [coder decodeIntForKey:@"secStartRowScoreboard"];
        self.secWidthScoreboard = [coder decodeIntForKey:@"secWidthScoreboard"];
        self.secHeightScoreboard = [coder decodeIntForKey:@"secHeightScoreboard"];
        
    }
    return self;
}

@end
