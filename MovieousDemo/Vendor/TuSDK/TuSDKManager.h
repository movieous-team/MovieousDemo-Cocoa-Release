//
//  TuSDKManager.h
//  MovieousDemo
//
//  Created by Chris Wang on 2019/1/22.
//  Copyright © 2019 Movieous Team. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "TuSDKFramework.h"

NS_ASSUME_NONNULL_BEGIN

@interface TuSDKManager : NSObject

+ (instancetype)sharedManager;
- (void)setupResources;
- (void)releaseResources;

- (CVPixelBufferRef)processPixelBuffer:(CVPixelBufferRef)pixelBuffer;
- (CVPixelBufferRef)syncProcessPixelBuffer:(CVPixelBufferRef)pixelBuffer frameTime:(CMTime)currentTime;
- (void)destroyFrameData;
- (void)handleStickerChange:(TuSDKPFStickerGroup *)sticker;
- (NSArray<TuSDKMediaEffectData *> *)mediaEffectsWithType:(TuSDKMediaEffectDataType)effectType;
- (void)removeMediaEffectsWithType:(TuSDKMediaEffectDataType)effectType;
- (BOOL)addMediaEffect:(TuSDKMediaEffectData *)mediaEffect;
- (void)removeMediaEffect:(TuSDKMediaEffectData *)mediaEffect;

@end

NS_ASSUME_NONNULL_END
