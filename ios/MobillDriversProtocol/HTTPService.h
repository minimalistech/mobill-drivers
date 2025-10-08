//
//  HTTPService.h
//  WanDeSport2.0
//
//  Created by liusiyuan on 17/3/24.
//  Copyright © 2017年 liusiyuan. All rights reserved.
//

#import <Foundation/Foundation.h>
// #import "AFNetworking.h" // COMMENTED OUT: Not needed for basic LED functionality
#define HTTPServiceInstance [HTTPService shareHTTPService]
#define otaUrl @"http://www.coolledx.com/CoolLED1248/ota/"

typedef void (^succeeBlock) (NSDictionary *dic);
typedef void (^errorBlock) (NSError *error);
typedef void (^downBlock) (NSString *filePath);

@interface HTTPService : NSObject
+ (HTTPService *)shareHTTPService;

/**
 *  BannerInfo
 *  @param result      返回访问成功信息
 *  @param errorresult 返回错误信息
 */
- (void)getBannerInfoServerSuccess:(succeeBlock)result errorresult:(errorBlock)errorresult;

/**
 *  material
 *  @param result      返回访问成功信息
 *  @param errorresult 返回错误信息
 */
- (void)getMaterialServerWith:(NSString *)urlStr success:(succeeBlock)result errorresult:(errorBlock)errorresult;

/**
 *  config
 *  @param result      返回访问成功信息
 *  @param errorresult 返回错误信息
 */
- (void)getCategoryDependOnServerWith:(NSString *)categoryURL success:(succeeBlock)result errorresult:(errorBlock)errorresult;

/**
 *  config
 *  @param result      返回访问成功信息
 *  @param errorresult 返回错误信息
 */
- (void)getDevilEyeServerWith:(NSString *)categoryURL success:(succeeBlock)result errorresult:(errorBlock)errorresult;

/**
 *  config
 *  @param result      返回访问成功信息
 *  @param errorresult 返回错误信息
 */
- (void)getMaterialListDependOnServerWith:(NSString *)materialListURL success:(succeeBlock)result errorresult:(errorBlock)errorresult;
/**
 *  OTA升级
 *  @param result      返回访问成功信息
 *  @param errorresult 返回错误信息
 */
- (void)getOtaServerWith:(NSString *)materialListURL success:(succeeBlock)result errorresult:(errorBlock)errorresult;

@end
