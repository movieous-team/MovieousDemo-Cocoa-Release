//
//  MDFilter.m
//  MovieousDemo
//
//  Created by Chris Wang on 2018/10/23.
//  Copyright © 2018 Movieous Team. All rights reserved.
//

#import "MDFilter.h"
#import "FUManager.h"
#import "STManager.h"
#import "TuSDKManager.h"
#import "MDGlobalSettings.h"
#import "MDSharedCenter.h"

@implementation MDSceneEffect

@end

@implementation MDFilter {
    BOOL _isSetup;
    NSRecursiveLock *_lock;
}

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static MDFilter *filter;
    dispatch_once(&onceToken, ^{
        filter = [[MDFilter alloc] init];
    });
    return filter;
}

- (instancetype)init {
    if (self = [super init]) {
        _sceneEffects = [NSMutableArray array];
        _lock = [NSRecursiveLock new];
    }
    return self;
}

- (void)setup {
    [_lock lock];
    if (_isSetup) {
        [_lock unlock];
        return;
    }
    _isSetup = YES;
    if (MDGlobalSettings.sharedInstance.vendorType == VendorTypeFaceunity) {
        [[FUManager shareManager] destoryItems];
        [[FUManager shareManager] loadFilter];
        [[FUManager shareManager] setAsyncTrackFaceEnable:YES];
        [[FUManager shareManager] resetAllBeautyParams];
    } else if (MDGlobalSettings.sharedInstance.vendorType == VendorTypeSenseTime) {
        [[STManager sharedManager] initResources];
    } else if (MDGlobalSettings.sharedInstance.vendorType == VendorTypeTuSDK) {
        [TuSDKManager.sharedManager setupResources];
    }
    [_lock unlock];
}

- (void)dispose {
    [_lock lock];
    if (!_isSetup) {
        [_lock unlock];
        return;
    }
    _isSetup = NO;
    if (MDGlobalSettings.sharedInstance.vendorType == VendorTypeFaceunity) {
        [FUManager.shareManager destoryItems];
    } else if (MDGlobalSettings.sharedInstance.vendorType == VendorTypeSenseTime) {
        [STManager.sharedManager releaseResources];
    } else if (MDGlobalSettings.sharedInstance.vendorType == VendorTypeTuSDK) {
        [TuSDKManager.sharedManager releaseResources];
    }
    [_lock unlock];
}

- (void)onCameraChanged {
    [_lock lock];
    if (MDGlobalSettings.sharedInstance.vendorType == VendorTypeFaceunity) {
        /**切换摄像头要调用此函数来重置人脸检测状态*/
        [[FUManager shareManager] onCameraChange];
    }
    [_lock unlock];
}

- (CVPixelBufferRef)processPixelBuffer:(CVPixelBufferRef)pixelBuffer sampleTimingInfo:(CMSampleTimingInfo)sampleTimingInfo {
    [_lock lock];
    if (!_isSetup) {
        NSLog(@"MDFilter not setup, please setup first");
        [_lock unlock];
        return pixelBuffer;
    }
    if (MDGlobalSettings.sharedInstance.vendorType == VendorTypeFaceunity) {
        NSTimeInterval time = CMTimeGetSeconds(sampleTimingInfo.presentationTimeStamp);
        id sceneCode = [NSNull null];
        for (MDSceneEffect *effect in _sceneEffects) {
            if (MovieousTimeRangeIsEqual(effect.timeRange, kMovieousTimeRangeDefault) ||
                (time >= effect.timeRange.startTime && time <= effect.timeRange.startTime + effect.timeRange.duration)) {
                sceneCode = effect.sceneCode;
            }
        }
        if (sceneCode == [NSNull null]) {
            if (![FUManager.shareManager.selectedMusicFilter isEqualToString:@"noitem"]) {
                [FUManager.shareManager loadMusicItem:@"noitem"];
            }
        } else {
            if (![FUManager.shareManager.selectedMusicFilter isEqualToString:sceneCode]) {
                [FUManager.shareManager loadMusicItem:sceneCode];
            }
            [FUManager.shareManager setMusicTime:time];
        }
        pixelBuffer = [FUManager.shareManager renderItemsToPixelBuffer:pixelBuffer];
    } else if (MDGlobalSettings.sharedInstance.vendorType == VendorTypeSenseTime) {
        pixelBuffer = [STManager.sharedManager processPixelBuffer:pixelBuffer];
    } else if (MDGlobalSettings.sharedInstance.vendorType == VendorTypeTuSDK) {
        NSTimeInterval time = CMTimeGetSeconds(sampleTimingInfo.presentationTimeStamp);
        id sceneCode = [NSNull null];
        for (MDSceneEffect *effect in _sceneEffects) {
            if (MovieousTimeRangeIsEqual(effect.timeRange, kMovieousTimeRangeDefault) ||
                (time >= effect.timeRange.startTime && time <= effect.timeRange.startTime + effect.timeRange.duration)) {
                sceneCode = effect.sceneCode;
            }
        }
        if (sceneCode == [NSNull null]) {
            [TuSDKManager.sharedManager removeMediaEffectsWithType:TuSDKMediaEffectDataTypeScene];
        } else {
            [TuSDKManager.sharedManager removeMediaEffectsWithType:TuSDKMediaEffectDataTypeScene];
            TuSDKMediaSceneEffectData *effectData = [[TuSDKMediaSceneEffectData alloc] initWithEffectsCode:sceneCode];
            effectData.atTimeRange = [TuSDKTimeRange makeTimeRangeWithStart:kCMTimeZero end:CMTimeMake(INTMAX_MAX, 1)];
            [TuSDKManager.sharedManager addMediaEffect:effectData];
            // 只有需要使用到 TuSDK 的滤镜时才经过其处理，否则不用处理
        }
        pixelBuffer = [TuSDKManager.sharedManager syncProcessPixelBuffer:pixelBuffer frameTime:sampleTimingInfo.presentationTimeStamp];
        [TuSDKManager.sharedManager destroyFrameData];
    } else if (MDGlobalSettings.sharedInstance.vendorType == VendorTypeKiwi) {
        [KWRenderManager processPixelBuffer:pixelBuffer];
    }
    [_lock unlock];
    return pixelBuffer;
}

@end
