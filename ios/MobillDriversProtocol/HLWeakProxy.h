//
//  HLWeakProxy.h
//  GlowGlasses
//
//  Created by Harvey on 2020/4/18.
//  Copyright © 2020 Haley. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HLWeakProxy : NSProxy

@property (nullable, nonatomic, weak, readonly) id target;

- (instancetype)initWithTarget:(id)target;

+ (instancetype)proxyWithTarget:(id)target;

@end

