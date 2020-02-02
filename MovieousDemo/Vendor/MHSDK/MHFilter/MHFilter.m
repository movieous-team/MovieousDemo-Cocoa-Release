//
//  MHFilter.m
//  MovieousDemo
//
//  Created by apple on 2020/1/6.
//  Copyright © 2020 Movieous Team. All rights reserved.
//

#import "MHFilter.h"

@implementation MHFilter
+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static MHFilter *filter;
    dispatch_once(&onceToken, ^{
        filter = [[MHFilter alloc] init];
    });
    return filter;
}

- (CVPixelBufferRef)processPixelBuffer:(CVPixelBufferRef)pixelBuffer sampleTimingInfo:(CMSampleTimingInfo)sampleTimingInfo {
 
    pixelBuffer =  [self.beautyManager processPixelBuffer:pixelBuffer sampleTimingInfo:sampleTimingInfo];
    return pixelBuffer;
    
}
@end
