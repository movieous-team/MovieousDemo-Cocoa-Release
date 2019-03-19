//
//  MDShortVideoFilter.m
//  MovieousDemo
//
//  Created by Chris Wang on 2018/10/23.
//  Copyright © 2018 Movieous Team. All rights reserved.
//

#import "MDShortVideoFilter.h"
#import "FUManager.h"
#import "STManager.h"
#import "TuSDKManager.h"
#import "MDGlobalSettings.h"

@implementation MDSceneEffect

@end

@interface MDShortVideoFilter ()

@end

@implementation MDShortVideoFilter

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static MDShortVideoFilter *filter;
    dispatch_once(&onceToken, ^{
        filter = [[MDShortVideoFilter alloc] init];
    });
    return filter;
}

- (instancetype)init {
    if (self = [super init]) {
        _sceneEffects = [NSMutableArray array];
        if (MDGlobalSettings.sharedInstance.vendorType == VendorTypeFaceunity) {
            [[FUManager shareManager] destoryItems];
            [[FUManager shareManager] loadFilter];
            [[FUManager shareManager] setAsyncTrackFaceEnable:YES];
            [[FUManager shareManager] setBeautyDefaultParameters];
        } else if (MDGlobalSettings.sharedInstance.vendorType == VendorTypeSenseTime) {
            [[STManager sharedManager] cancelStickerAndObjectTrack];
        }
    }
    return self;
}

- (CVPixelBufferRef)processPixelBuffer:(CVPixelBufferRef)pixelBuffer sampleTimingInfo:(CMSampleTimingInfo)sampleTimingInfo {
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
    }
    return pixelBuffer;
}

@end
