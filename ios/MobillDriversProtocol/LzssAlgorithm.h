//
//  LzssAlgorithm.h
//  CoolLED1248
//
//  Created by 君同 on 2023/3/8.
//  Copyright © 2023 Haley. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LzssAlgorithm : NSObject

-(NSData *)lzssEncode:(NSData *)dataDa;

@end

NS_ASSUME_NONNULL_END
