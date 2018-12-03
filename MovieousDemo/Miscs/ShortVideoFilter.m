//
//  ShortVideoFilter.m
//  MovieousDemo
//
//  Created by Chris Wang on 2018/10/23.
//  Copyright © 2018 Movieous Team. All rights reserved.
//

#import "ShortVideoFilter.h"
#import "FUManager.h"
#import "STManager.h"

@implementation SceneEffect

@end

@interface ShortVideoFilter ()

@end

@implementation ShortVideoFilter

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static ShortVideoFilter *filter;
    dispatch_once(&onceToken, ^{
        filter = [[ShortVideoFilter alloc] init];
    });
    return filter;
}

- (instancetype)init {
    if (self = [super init]) {
        _sceneEffects = [NSMutableArray array];
        [self setupTuSDKFilterProcessor];
    }
    return self;
}

// 设置 TuSDK
- (void)setupTuSDKFilterProcessor {
    
    
    // 传入图像的方向是否为原始朝向(相机采集的原始朝向)，SDK 将依据该属性来调整人脸检测时图片的角度。如果没有对图片进行旋转，则为 YES
    BOOL isOriginalOrientation = NO;
    
    _filterProcessor = [[TuSDKFilterProcessor alloc] initWithFormatType:kCVPixelFormatType_32BGRA isOriginalOrientation:isOriginalOrientation];
    // 默认关闭动态贴纸功能，即关闭人脸识别功能
    _filterProcessor.enableLiveSticker = NO;
    
    // 默认添加滤镜效果，sample code，switchFilterWithCode 方法将废弃
    // TuSDKMediaFilterEffectData *filterEffectData = [[TuSDKMediaFilterEffectData alloc] initWithEffectCode:_videoFilters[1]];
    // [_filterProcessor addMediaEffect:filterEffectData];
    // 刷新滤镜栏视图方法，调用前确保_filterView 已经完成初始化
    // [_filterView refreshAdjustParameterV iewWith:filterEffectData.effectCode filterArgs:filterEffectData.filterArgs];
    
    
}

- (CVPixelBufferRef)processPixelBuffer:(CVPixelBufferRef)pixelBuffer sampleTimingInfo:(CMSampleTimingInfo)sampleTimingInfo {
    NSTimeInterval time = CMTimeGetSeconds(sampleTimingInfo.presentationTimeStamp);
    id sceneCode = [NSNull null];
    for (SceneEffect *effect in _sceneEffects) {
        if (MovieousTimeRangeIsEqual(effect.timeRange, kMovieousTimeRangeDefault) ||
            (time >= effect.timeRange.startTime && time <= effect.timeRange.startTime + effect.timeRange.duration)) {
            sceneCode = effect.sceneCode;
        }
    }
    NSArray<TuSDKMediaSceneEffectData *> *mediaEffects = (NSArray<TuSDKMediaSceneEffectData *> *)[_filterProcessor mediaEffectsWithType:TuSDKMediaEffectDataTypeScene];
    if (sceneCode == [NSNull null]) {
        if (![FUManager.shareManager.selectedMusicFilter isEqualToString:@"noitem"]) {
            [FUManager.shareManager loadMusicItem:@"noitem"];
        }
        if (mediaEffects.count > 0) {
            [_filterProcessor removeMediaEffectsWithType:TuSDKMediaEffectDataTypeScene];
        }
    } else if ([kFUSceneEffectCodes indexOfObject:sceneCode] != NSNotFound) {
        if (![FUManager.shareManager.selectedMusicFilter isEqualToString:sceneCode]) {
            [FUManager.shareManager loadMusicItem:sceneCode];
        }
        if (mediaEffects.count > 0) {
            [_filterProcessor removeMediaEffectsWithType:TuSDKMediaEffectDataTypeScene];
        }
        [FUManager.shareManager setMusicTime:time];
    } else {
        if (![FUManager.shareManager.selectedMusicFilter isEqualToString:@"noitem"]) {
            [FUManager.shareManager loadMusicItem:@"noitem"];
        }
        if (mediaEffects.count == 0 ||
            (mediaEffects.count > 0 && ![mediaEffects[0].effectsCode isEqualToString:sceneCode])) {
            TuSDKMediaSceneEffectData *effectData = [[TuSDKMediaSceneEffectData alloc] initWithEffectsCode:sceneCode];
            effectData.atTimeRange = [TuSDKTimeRange makeTimeRangeWithStart:kCMTimeZero end:CMTimeMake(INTMAX_MAX, 1)];
            [_filterProcessor removeMediaEffectsWithType:TuSDKMediaEffectDataTypeScene];
            [_filterProcessor addMediaEffect:effectData];
        }
        // 只有需要使用到 TuSDK 的滤镜时才经过其处理，否则不用处理
        pixelBuffer = [_filterProcessor syncProcessPixelBuffer:pixelBuffer frameTime:sampleTimingInfo.presentationTimeStamp];
    }
    [FUManager.shareManager renderItemsToPixelBuffer:pixelBuffer];
    [_filterProcessor destroyFrameData];
    pixelBuffer = [STManager.sharedManager processPixelBuffer:pixelBuffer];
    return pixelBuffer;
}

@end
