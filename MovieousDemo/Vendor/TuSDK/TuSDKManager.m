//
//  TuSDKManager.m
//  MovieousDemo
//
//  Created by Chris Wang on 2019/1/22.
//  Copyright © 2019 Movieous Team. All rights reserved.
//

#import "TuSDKManager.h"

@implementation TuSDKManager {
    TuSDKFilterProcessor *_filterProcessor;
}

+ (instancetype)sharedManager {
    static TuSDKManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [TuSDKManager new];
    });
    return manager;
}

- (void)setupResources {
    // 传入图像的方向是否为原始朝向(相机采集的原始朝向)，SDK 将依据该属性来调整人脸检测时图片的角度。如果没有对图片进行旋转，则为 YES
    BOOL isOriginalOrientation = NO;
    
    _filterProcessor = [[TuSDKFilterProcessor alloc] initWithFormatType:kCVPixelFormatType_32BGRA isOriginalOrientation:isOriginalOrientation];
    // 默认关闭动态贴纸功能，即关闭人脸识别功能
    _filterProcessor.enableLiveSticker = YES;
}

- (void)releaseResources {
    _filterProcessor = nil;
}

- (CVPixelBufferRef)processPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    return [_filterProcessor syncProcessPixelBuffer:pixelBuffer];
}

- (CVPixelBufferRef)syncProcessPixelBuffer:(CVPixelBufferRef)pixelBuffer frameTime:(CMTime)currentTime {
    return [_filterProcessor syncProcessPixelBuffer:pixelBuffer frameTime:currentTime];
}

- (void)destroyFrameData {
    [_filterProcessor destroyFrameData];
}

- (void)handleStickerChange:(TuSDKPFStickerGroup *)sticker {
    if (!sticker) {
        // 为nil时 移除已有贴纸组
        [_filterProcessor removeMediaEffectsWithType:TuSDKMediaEffectDataTypeSticker];
    }
    
    // 添加贴纸特效
    TuSDKMediaStickerEffectData *stickerEffect = [[TuSDKMediaStickerEffectData alloc] initWithStickerGroup:sticker];
    [_filterProcessor addMediaEffect:stickerEffect];
}

- (NSArray<TuSDKMediaEffectData *> *)mediaEffectsWithType:(TuSDKMediaEffectDataType)effectType {
    return [_filterProcessor mediaEffectsWithType:effectType];
}

- (void)removeMediaEffectsWithType:(TuSDKMediaEffectDataType)effectType {
    [_filterProcessor removeMediaEffectsWithType:effectType];
}

- (BOOL)addMediaEffect:(TuSDKMediaEffectData *)mediaEffect {
    return [_filterProcessor addMediaEffect:mediaEffect];
}

- (void)removeMediaEffect:(TuSDKMediaEffectData *)mediaEffect {
    [_filterProcessor removeMediaEffect:mediaEffect];
}

@end
