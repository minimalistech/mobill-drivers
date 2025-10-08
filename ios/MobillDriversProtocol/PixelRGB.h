//
//  PixelRGB.h
//  CoolLED1248
//
//  Created by go on 9/30/24.
//  Copyright © 2024 Haley. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GWPeripheral.h"
#import "HLPackageSendModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface PixelRGB : NSObject

@property (nonatomic, assign) int isColor;

@property (nonatomic, strong) NSArray *rgbArr;


@end

NS_ASSUME_NONNULL_END
