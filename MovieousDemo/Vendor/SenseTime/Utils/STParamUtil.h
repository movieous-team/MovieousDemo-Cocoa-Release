//
//  STParamUtil.h
//
//  Created by HaifengMay on 16/11/5.
//  Copyright © 2016年 SenseTime. All rights reserved.
//

/*
 * function: 主要用来获取一些系统的参数，如 CPU占用率，帧率等
 */
#import <Foundation/Foundation.h>
#import "st_mobile_human_action.h"
#import "st_mobile_common.h"
#import "st_mobile_beautify.h"

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#define STWeakSelf __weak __typeof(self) weakSelf = self;


typedef NS_ENUM(NSInteger, STTitleViewStyle) {
    STTitleViewStyleOnlyImage = 0,
    STTitleViewStyleOnlyCharacter
};

typedef NS_ENUM(NSInteger, STEffectsType) {
    
    STEffectsTypeNone = 0,
    
    STEffectsTypeSticker2D,
    STEffectsTypeStickerAvatar,
    STEffectsTypeSticker3D,
    STEffectsTypeStickerGesture,
    STEffectsTypeStickerSegment,
    STEffectsTypeStickerFaceChange,
    STEffectsTypeStickerFaceDeformation,
    STEffectsTypeStickerParticle,
    STEffectsTypeStickerNew,
    
    STEffectsTypeObjectTrack,
    
    STEffectsTypeBeautyFilter,
    STEffectsTypeBeautyBase,
    STEffectsTypeBeautyShape,
    STEffectsTypeBeautyBody,
    
    STEffectsTypeFilterPortrait,
    STEffectsTypeFilterScenery,
    STEffectsTypeFilterStillLife,
    STEffectsTypeFilterDeliciousFood,
    
};

void addSubModel(st_handle_t handle, NSString* modelName);
void setBeautifyParam(st_handle_t beautifyHandle, st_beautify_type type, float value);
float getBodyRatio(float value);
float getNewBodyRatio(float value);
float getLongLegsRatio(float value);
float getShouldersValue(float value);
float getThinLegValue(float value);

@interface STParamUtil : NSObject

/*
 * 返回CPU占用率的分子（分母为100）
 */
+ (float) getCpuUsage;


/**
 获取通用物体素材路径

 @return 路径数组
 */
+ (NSArray *)getTrackerPaths;


/**
 获取特定类型贴纸素材路径

 @param type STEffectsType
 @return 路径数组
 */
+ (NSArray *)getStickerPathsByType:(STEffectsType)type;


/**
 获取特定类型滤镜路径

 @param type STEffectsType
 @return 路径数组
 */
+ (NSArray *)getFilterModelPathsByType:(STEffectsType)type;

@end
