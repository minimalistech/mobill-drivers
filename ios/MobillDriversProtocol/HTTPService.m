//
//  HTTPService.m
//  WanDeSport2.0
//
//  Created by liusiyuan on 17/3/24.
//  Copyright © 2017年 liusiyuan. All rights reserved.
//

#import "HTTPService.h"

static HTTPService * shareHTTPService = nil;

@implementation HTTPService

+ (HTTPService *)shareHTTPService
{
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        shareHTTPService = [[HTTPService alloc] init];
    });
    return shareHTTPService;
}

// STUB IMPLEMENTATIONS - Not essential for basic LED functionality

- (void)getBannerInfoServerSuccess:(succeeBlock)result errorresult:(errorBlock)errorresult {
    NSLog(@"🔧 getBannerInfoServerSuccess - stubbed implementation");
    if (errorresult) {
        NSError *error = [NSError errorWithDomain:@"HTTPServiceStub" code:404 userInfo:@{NSLocalizedDescriptionKey: @"Stubbed - not implemented"}];
        errorresult(error);
    }
}

- (void)getMaterialServerWith:(NSString *)urlStr success:(succeeBlock)result errorresult:(errorBlock)errorresult {
    NSLog(@"🔧 getMaterialServerWith - stubbed implementation");
    if (errorresult) {
        NSError *error = [NSError errorWithDomain:@"HTTPServiceStub" code:404 userInfo:@{NSLocalizedDescriptionKey: @"Stubbed - not implemented"}];
        errorresult(error);
    }
}

- (void)getCategoryDependOnServerWith:(NSString *)categoryURL success:(succeeBlock)result errorresult:(errorBlock)errorresult {
    NSLog(@"🔧 getCategoryDependOnServerWith - stubbed implementation");
    if (errorresult) {
        NSError *error = [NSError errorWithDomain:@"HTTPServiceStub" code:404 userInfo:@{NSLocalizedDescriptionKey: @"Stubbed - not implemented"}];
        errorresult(error);
    }
}

- (void)getDevilEyeServerWith:(NSString *)categoryURL success:(succeeBlock)result errorresult:(errorBlock)errorresult {
    NSLog(@"🔧 getDevilEyeServerWith - stubbed implementation");
    if (errorresult) {
        NSError *error = [NSError errorWithDomain:@"HTTPServiceStub" code:404 userInfo:@{NSLocalizedDescriptionKey: @"Stubbed - not implemented"}];
        errorresult(error);
    }
}

- (void)getMaterialListDependOnServerWith:(NSString *)materialListURL success:(succeeBlock)result errorresult:(errorBlock)errorresult {
    NSLog(@"🔧 getMaterialListDependOnServerWith - stubbed implementation");
    if (errorresult) {
        NSError *error = [NSError errorWithDomain:@"HTTPServiceStub" code:404 userInfo:@{NSLocalizedDescriptionKey: @"Stubbed - not implemented"}];
        errorresult(error);
    }
}

- (void)getOtaServerWith:(NSString *)materialListURL success:(succeeBlock)result errorresult:(errorBlock)errorresult {
    NSLog(@"🔧 getOtaServerWith - stubbed implementation for OTA functionality");
    // For OTA, we can provide a minimal success response to avoid breaking the flow
    if (result) {
        NSDictionary *stubResponse = @{
            @"version": @"1.0.0",
            @"message": @"OTA functionality disabled - using stub implementation"
        };
        result(stubResponse);
    }
}

@end