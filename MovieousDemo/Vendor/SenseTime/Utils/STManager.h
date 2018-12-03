//
//  STManager.h
//  MovieousDemo
//
//  Created by Chris Wang on 2018/11/15.
//  Copyright © 2018 Movieous Team. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "STTriggerView.h"
#import "STCollectionView.h"

@class STManager;
@protocol STManagerDelegate <NSObject>

@optional
- (void)manager:(STManager *)manager commonObjectCenterDidUpdated:(CGPoint)center;

@end

@interface STManager : NSObject

@property (nonatomic, weak) id<STManagerDelegate> delegate;

@property (nonatomic, assign) AVCaptureDevicePosition devicePosition;
@property (nonatomic, assign) BOOL isVideoMirrored;
@property (nonatomic, assign) BOOL isComparing;

@property (nonatomic, readwrite, assign) BOOL bAttribute;
@property (nonatomic, readwrite, assign) BOOL bBeauty;
@property (nonatomic, readwrite, assign) BOOL bSticker;
@property (nonatomic, readwrite, assign) BOOL bTracker;
@property (nonatomic, readwrite, assign) BOOL bFilter;

//beauty value
@property (nonatomic, assign) float fSmoothStrength;
@property (nonatomic, assign) float fReddenStrength;
@property (nonatomic, assign) float fWhitenStrength;
@property (nonatomic, assign) float fEnlargeEyeStrength;
@property (nonatomic, assign) float fShrinkFaceStrength;
@property (nonatomic, assign) float fShrinkJawStrength;

@property (nonatomic, assign) float fContrastStrength;
@property (nonatomic, assign) float fSaturationStrength;

@property (nonatomic, assign) float fDehighlightStrength;

@property (nonatomic, readwrite, strong) NSArray *arrNewStickers;
@property (nonatomic, readwrite, strong) NSArray *arr2DStickers;
@property (nonatomic, readwrite, strong) NSArray *arrAvatarStickers;
@property (nonatomic, readwrite, strong) NSArray *arr3DStickers;
@property (nonatomic, readwrite, strong) NSArray *arrGestureStickers;
@property (nonatomic, readwrite, strong) NSArray *arrSegmentStickers;
@property (nonatomic, readwrite, strong) NSArray *arrFacedeformationStickers;
@property (nonatomic, readwrite, strong) NSArray *arrObjectTrackers;
@property (nonatomic, readwrite, strong) NSArray *arrFaceChangeStickers;
@property (nonatomic, strong) NSArray *arrParticleStickers;
@property (nonatomic, strong) STTriggerView *triggerView;

+ (instancetype)sharedManager;

- (CVPixelBufferRef)processPixelBuffer:(CVPixelBufferRef)pixelBuffer;

- (void)commonObjectViewStartTrackingFrame:(CGRect)frame;

- (void)commonObjectViewFinishTrackingFrame:(CGRect)frame;

- (void)handleStickerChanged:(STCollectionViewDisplayModel *)model;

- (void)cancelStickerAndObjectTrack;

@end
