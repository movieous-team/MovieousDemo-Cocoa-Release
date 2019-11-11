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
#import "STCustomMemoryCache.h"
#import "EffectsCollectionViewCell.h"
#import "STBmpModel.h"

NS_ASSUME_NONNULL_BEGIN

@class STManager;
@protocol STManagerDelegate <NSObject>

@optional
- (void)manager:(STManager *)manager commonObjectCenterDidUpdated:(CGPoint)center rect:(st_rect_t)rect;
- (void)manager:(STManager *)manager fetchMaterialSuccess:(STEffectsType)iType;
- (void)manager:(STManager *)manager fetchListDone:(NSArray *)arrLocalModels;
- (void)manager:(STManager *)manager cachedThumbnail:(EffectsCollectionViewCellModel *)model;
- (void)manager:(STManager *)manager modelUpdated:(EffectsCollectionViewCellModel *)model;

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
@property (nonatomic, assign) float fRoundEyeStrength;

@property (nonatomic, assign) float fThinFaceShapeStrength;
@property (nonatomic, assign) float fChinStrength;
@property (nonatomic, assign) float fHairLineStrength;
@property (nonatomic, assign) float fNarrowNoseStrength;
@property (nonatomic, assign) float fLongNoseStrength;
@property (nonatomic, assign) float fMouthStrength;
@property (nonatomic, assign) float fPhiltrumStrength;
@property (nonatomic, assign) float fAppleMusleStrength;
@property (nonatomic, assign) float fProfileRhinoplastyStrength;
@property (nonatomic, assign) float fEyeDistanceStrength;
@property (nonatomic, assign) float fEyeAngleStrength;
@property (nonatomic, assign) float fOpenCanthusStrength;
@property (nonatomic, assign) float fBrightEyeStrength;
@property (nonatomic, assign) float fRemoveDarkCirclesStrength;
@property (nonatomic, assign) float fRemoveNasolabialFoldsStrength;
@property (nonatomic, assign) float fWhiteTeethStrength;

@property (nonatomic, assign) float fContrastStrength;
@property (nonatomic, assign) float fSaturationStrength;

//filter value
@property (nonatomic, assign) float fFilterStrength;

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

@property (nonatomic, strong) NSArray *arrParticleStickers;
@property (nonatomic, strong) STTriggerView *triggerView;

@property (nonatomic, readwrite, strong) STCollectionViewDisplayModel *currentSelectedFilterModel;

@property (nonatomic , strong) STCustomMemoryCache *effectsDataSource;
@property (nonatomic , strong) STCustomMemoryCache *thumbnailCache;

@property (nonatomic, assign) float bmp_Eye_Value;
@property (nonatomic, assign) float bmp_EyeLiner_Value;
@property (nonatomic, assign) float bmp_EyeLash_Value;
@property (nonatomic, assign) float bmp_Lip_Value;
@property (nonatomic, assign) float bmp_Brow_Value;
@property (nonatomic, assign) float bmp_Nose_Value;
@property (nonatomic, assign) float bmp_Face_Value;
@property (nonatomic, assign) float bmp_Blush_Value;
@property (nonatomic, assign) float bmp_Eyeball_Value;

+ (instancetype)sharedManager;

- (void)createResources;

- (void)releaseResources;

- (CVPixelBufferRef)processPixelBuffer:(CVPixelBufferRef)pixelBuffer;

- (void)handleStickerChanged:(STCollectionViewDisplayModel *_Nullable)model;

- (void)handleFilterChanged:(STCollectionViewDisplayModel *)model;

- (void)cancelStickerAndObjectTrack;

- (NSArray *)getStickerModelsByType:(STEffectsType)type;

- (void)sliderValueDidChange:(float)value;
- (void)didSelectedDetailModel:(STBMPModel *)model;
- (void)resetSettings;

@end

NS_ASSUME_NONNULL_END
