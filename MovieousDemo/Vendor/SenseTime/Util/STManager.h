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
#import "STCommonObjectContainerView.h"

@class STManager;
@protocol STManagerDelegate <NSObject>

@optional
- (void)manager:(STManager *)manager commonObjectCenterDidUpdated:(CGPoint)center rect:(st_rect_t)rect;

@end

@interface STManager : NSObject
<
STCommonObjectContainerViewDelegate
>

@property (nonatomic, weak) id<STManagerDelegate> delegate;

@property (nonatomic, strong) NSArray<STNewBeautyCollectionViewModel *> *microSurgeryModels;
@property (nonatomic, strong) NSArray<STNewBeautyCollectionViewModel *> *baseBeautyModels;
@property (nonatomic, strong) NSArray<STNewBeautyCollectionViewModel *> *beautyShapeModels;
@property (nonatomic, strong) NSArray<STNewBeautyCollectionViewModel *> *adjustModels;

@property (nonatomic, assign) AVCaptureDevicePosition devicePosition;
@property (nonatomic, assign) BOOL isVideoMirrored;
@property (nonatomic, assign) BOOL isComparing;
@property (nonatomic, assign) BOOL isFrontCamera;

@property (nonatomic, readwrite, assign) BOOL bAttribute;
@property (nonatomic, readwrite, assign) BOOL bBeauty;
@property (nonatomic, readwrite, assign) BOOL bSticker;
@property (nonatomic, readwrite, assign) BOOL bTracker;
@property (nonatomic, readwrite, assign) BOOL bFilter;

//beauty value
@property (nonatomic, assign) float fWhitenStrength;
@property (nonatomic, assign) float fReddenStrength;
@property (nonatomic, assign) float fSmoothStrength;
@property (nonatomic, assign) float fDehighlightStrength;

@property (nonatomic, assign) float fShrinkFaceStrength;
@property (nonatomic, assign) float fEnlargeEyeStrength;
@property (nonatomic, assign) float fShrinkJawStrength;
@property (nonatomic, assign) float fNarrowFaceStrength;

@property (nonatomic, assign) float fChinStrength;
@property (nonatomic, assign) float fHairLineStrength;
@property (nonatomic, assign) float fNarrowNoseStrength;
@property (nonatomic, assign) float fLongNoseStrength;
@property (nonatomic, assign) float fMouthStrength;
@property (nonatomic, assign) float fPhiltrumStrength;

@property (nonatomic, assign) float fContrastStrength;
@property (nonatomic, assign) float fSaturationStrength;

@property (nonatomic, readwrite, strong) NSArray *arrNewStickers;
@property (nonatomic, readwrite, strong) NSArray *arr2DStickers;
@property (nonatomic, readwrite, strong) NSArray *arrAvatarStickers;
@property (nonatomic, readwrite, strong) NSArray *arr3DStickers;
@property (nonatomic, readwrite, strong) NSArray *arrGestureStickers;
@property (nonatomic, readwrite, strong) NSArray *arrSegmentStickers;
@property (nonatomic, readwrite, strong) NSArray *arrFacedeformationStickers;
@property (nonatomic, readwrite, strong) NSArray *arrObjectTrackers;
@property (nonatomic, readwrite, strong) NSArray *arrFaceChangeStickers;

@property (nonatomic, readwrite, strong) NSArray *arrSceneryFilterModels;
@property (nonatomic, readwrite, strong) NSArray *arrPortraitFilterModels;
@property (nonatomic, readwrite, strong) NSArray *arrStillLifeFilterModels;
@property (nonatomic, readwrite, strong) NSArray *arrDeliciousFoodFilterModels;
@property (nonatomic, assign, getter=isCommonObjectViewAdded) BOOL commonObjectViewAdded;
@property (nonatomic, assign, getter=isCommonObjectViewSetted) BOOL commonObjectViewSetted;

@property (nonatomic, strong) NSArray *arrParticleStickers;
@property (nonatomic, strong) STTriggerView *triggerView;

@property (nonatomic, readwrite, strong) STCollectionViewDisplayModel *currentSelectedFilterModel;

+ (instancetype)sharedManager;

- (void)initResources;

- (void)releaseResources;

- (CVPixelBufferRef)processPixelBuffer:(CVPixelBufferRef)pixelBuffer;

- (void)handleStickerChanged:(STCollectionViewDisplayModel *)model;

- (void)handleFilterChanged:(STCollectionViewDisplayModel *)model;

- (void)cancelStickerAndObjectTrack;

- (void)handleFilterStrenthChange:(float)strenth;

- (NSArray *)getStickerModelsByType:(STEffectsType)type;

- (void)resetCommonObjectViewPosition;

- (void)handleObjectTrackChanged:(STCollectionViewDisplayModel *)model;

- (st_handle_t)hSticker;  // sticker句柄


@end
