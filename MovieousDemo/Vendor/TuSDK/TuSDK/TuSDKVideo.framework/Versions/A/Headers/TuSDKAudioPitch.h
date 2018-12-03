//
//  TuSDKAudioPitch.h
//  TuSDKVideo
//
//  Created by Clear Hu on 2018/7/22.
//  Copyright © 2018年 TuSDK. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "TuSDKAudioInfo.h"

/** 音频变调同步接口 */
@protocol TuSDKAudioPitchSync <NSObject>
/**
 * 同步音频重变调后数据
 *
 * @param output    数据缓存
 */
- (void)syncAudioPitchOutputBuffer:(CMSampleBufferRef) output;
@end

/** 音频变调接口 */
@protocol TuSDKAudioPitch <NSObject>

/** 音频变调同步接口 */
@property (nonatomic, weak) id<TuSDKAudioPitchSync> mediaSync;

/** 切换采样格式 */
@property (nonatomic, retain) TuSDKAudioTrackInfo *inputInfo;

/**
 * 改变音频音调 [速度设置将失效]
 *
 * @param pitch 0 > pitch [大于1时声音升调，小于1时为降调]
 */
@property (nonatomic) float pitch;

/**
 * 改变音频播放速度 [变速不变调, 音调设置将失效]
 *
 * @param speed 0 > speed
 */
@property (nonatomic) float speed;

/** 是否需要重采样 */
@property (nonatomic, readonly) BOOL needPitch;

/** 重置时间戳 */
- (void) reset;

/** 刷新数据 */
- (void) flush;

/***
 * 入列缓存
 * @param inputBuffer 输入缓存
 * @param isEos 是否为结尾
 * @return 是否已处理
 */
- (BOOL) queueInputBuffer:(CMSampleBufferRef) inputBuffer isEos:(BOOL)eos;

/** 释放变调器 */
- (void) destory;
@end

/** 音频变调器工厂 */
@interface TuSDKAudioPitchFactory : NSObject
/** 创建音频变调器 */
+ (id<TuSDKAudioPitch>) buildWithAudioInfo:(TuSDKAudioTrackInfo *) info;
@end
