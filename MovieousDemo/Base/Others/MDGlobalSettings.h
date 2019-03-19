//
//  MDGlobalSettings.h
//  MovieousDemo
//
//  Created by Chris Wang on 2019/1/10.
//  Copyright © 2019 Movieous Team. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, VendorType) {
    VendorTypeNone,
    VendorTypeFaceunity,
    VendorTypeSenseTime,
    VendorTypeTuSDK,
};

NS_ASSUME_NONNULL_BEGIN

NSString *getVendorName(VendorType vendorType);

@interface MDGlobalSettings : NSObject

@property (nonatomic, assign) VendorType vendorType;

+ (instancetype)sharedInstance;

@end

NS_ASSUME_NONNULL_END
