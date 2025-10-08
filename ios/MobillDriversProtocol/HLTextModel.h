//
//  HLTextModel.h
//  CoolLED1248
//
//  Created by Harvey on 2020/11/6.
//  Copyright © 2020 Haley. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HLTextModel : NSObject<NSCoding>

@property (nonatomic, copy) NSString *originText;

@property (nonatomic, strong) NSArray *textItems;

@end

