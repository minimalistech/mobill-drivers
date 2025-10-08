//
//  Clock.h
//  CoolLED1248
//
//  Created by go on 11/7/23.
//  Copyright © 2023 Haley. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Clock : NSObject

@property (nonatomic, assign)int enable;
@property (nonatomic, assign)int hours;
@property (nonatomic, assign)int minutes;
@property (nonatomic, assign)int repeat;
@property (nonatomic, assign)int switchTime;
@property (nonatomic, assign)int action;

@end

NS_ASSUME_NONNULL_END
