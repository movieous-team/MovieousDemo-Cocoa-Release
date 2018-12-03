//
//  TuSDKAudioResample.h
//  TuSDKVideo
//
//  Created by Clear Hu on 2018/7/22.
//  Copyright © 2018年 TuSDK. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "TuSDKAudioInfo.h"

/** 音频重采样同步器 */
@protocol TuSDKAudioResampleSync <NSObject>
/**
 * 同步音频重采样后数据
 *
 * @param output    数据缓存
 */
- (void)syncAudioResampleOutputBuffer:(CMSampleBufferRef) output;
@end

/** 音频重采样接口 */
@protocol TuSDKAudioResample <NSObject>

/** 音频重采样同步器 */
@property (nonatomic, weak) id<TuSDKAudioResampleSync> mediaSync;

/** 切换采样格式 */
@property (nonatomic, retain) TuSDKAudioTrackInfo *inputInfo;

/**
 * 改变音频播放速度 [变速不变调, 音调设置将失效]
 *
 * @param speed 0 > speed
 */
@property (nonatomic) float speed;

/***
 * 改变音频序列
 * @param reverse 是否倒序
 */
@property (nonatomic) BOOL reverse;

/** 设置开始时间戳 [微秒] */
@property (nonatomic) long long startPrefixTimeUs;

/** 获取最后输入时间 [微秒] */
@property (nonatomic, readonly) long long lastInputTimeUs;

/** 获取前置时间 [微秒] */
@property (nonatomic, readonly) long long prefixTimeUs;

/** 是否需要重采样 */
@property (nonatomic, readonly) BOOL needResample;

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

/** 释放重采样器 */
- (void) destory;
@end

/** 音频重采样器工厂 */
@interface TuSDKAudioResampleFactory : NSObject
/** 创建音频重采样器 */
+ (id<TuSDKAudioResample>) buildWithAudioInfo:(TuSDKAudioTrackInfo *) info;
@end
