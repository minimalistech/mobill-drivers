//
//  HLOnePackageModel.m
//  CoolLED1248
//
//  Created by Harvey on 2022/6/3.
//  Copyright © 2022 Haley. All rights reserved.
//

#import "HLOnePackageModel.h"

@implementation HLOnePackageModel

- (instancetype)initWithPackageContent:(NSString *)packageContent packageId:(NSInteger)packageId
{
    self = [super init];
    if (self) {
        _sendIndex = 0;
        _packageContent = packageContent;
        _packageId = packageId;
    }
    
    return self;
}

@end
