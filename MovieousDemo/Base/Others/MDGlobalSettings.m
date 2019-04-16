//
//  MDGlobalSettings.m
//  MovieousDemo
//
//  Created by Chris Wang on 2019/1/10.
//  Copyright © 2019 Movieous Team. All rights reserved.
//

#import "MDGlobalSettings.h"

NSString *getVendorName(VendorType vendorType) {
    switch (vendorType) {
        case VendorTypeNone:
            return @"不使用第三方特效";
        case VendorTypeFaceunity:
            return @"相芯科技";
        case VendorTypeSenseTime:
            return @"商汤科技";
        case VendorTypeTuSDK:
            return @"涂图";
        default:
            return @"";
    }
}

@implementation MDGlobalSettings

+ (instancetype)sharedInstance {
    static MDGlobalSettings *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [self new];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        _vendorType = VendorTypeNone;
    }
    return self;
}

@end
