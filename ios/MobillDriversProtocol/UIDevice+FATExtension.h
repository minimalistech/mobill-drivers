//
//  UIDevice+FATExtension.h
//  FinApplet
//
//  Created by Haley on 2019/12/20.
//  Copyright © 2019 finogeeks. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIDevice (FATExtension)

/**
 设备的分辨率

 @return 分辨率
 */
- (CGSize)actualSize;

/**
 设备的mode （也就是机型，例如iPhone 11 Pro Max）

 @return 机型
 */
- (NSString *)deviceMode;

/**
设备的mode，例如 iPhone12,5

@return 机型
*/
- (NSString *)mode;

@end

