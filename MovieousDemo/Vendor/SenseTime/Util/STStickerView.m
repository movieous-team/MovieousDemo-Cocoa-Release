//
//  STStickerView.m
//  MovieousDemo
//
//  Created by Chris Wang on 2019/1/22.
//  Copyright © 2019 Movieous Team. All rights reserved.
//

#import "STStickerView.h"
#import "STScrollTitleView.h"
#import "STCollectionView.h"
#import "STManager.h"

@interface STStickerView ()
<
STManagerDelegate
>

@property (nonatomic, readwrite, strong) UIView *specialEffectsContainerView;
@property (nonatomic, readwrite, strong) UIImageView *noneStickerImageView;
@property (nonatomic, readwrite, strong) STScrollTitleView *scrollTitleView;
@property (nonatomic, readwrite, strong) STCollectionView *collectionView;
@property (nonatomic, readwrite, strong) STCollectionView *objectTrackCollectionView;
@property (nonatomic, assign) STEffectsType curEffectStickerType;
@property (nonatomic, readwrite, strong) NSArray<STCollectionViewDisplayModel *> *arr2DModels;
@property (nonatomic, readwrite, strong) NSArray<STCollectionViewDisplayModel *> *arr3DModels;
@property (nonatomic, readwrite, strong) NSArray<STCollectionViewDisplayModel *> *arrGestureModels;
@property (nonatomic, readwrite, strong) NSArray<STCollectionViewDisplayModel *> *arrSegmentModels;
@property (nonatomic, readwrite, strong) NSArray<STCollectionViewDisplayModel *> *arrFaceDeformationModels;
@property (nonatomic, readwrite, strong) NSArray<STCollectionViewDisplayModel *> *arrFilterModels;
@property (nonatomic, readwrite, strong) NSArray<STCollectionViewDisplayModel *> *arrObjectTrackModels;

@end

@implementation STStickerView

- (void)awakeFromNib {
    [super awakeFromNib];
    STManager.sharedManager.delegate = self;
    self.commonObjectContainerView = [[STCommonObjectContainerView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
    self.commonObjectContainerView.delegate = STManager.sharedManager;
    [self addSubview:self.specialEffectsContainerView];
}

- (UIView *)specialEffectsContainerView {
    if (!_specialEffectsContainerView) {
        _specialEffectsContainerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 230)];
        _specialEffectsContainerView.backgroundColor = [UIColor clearColor];
        
        UIView *noneStickerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 57, 40)];
        noneStickerView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
        noneStickerView.layer.shadowColor = UIColorFromRGB(0x141618).CGColor;
        noneStickerView.layer.shadowOpacity = 0.5;
        noneStickerView.layer.shadowOffset = CGSizeMake(3, 3);
        
        UIImage *image = [UIImage imageNamed:@"none_sticker.png"];
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake((57 - image.size.width) / 2, (40 - image.size.height) / 2, image.size.width, image.size.height)];
        imageView.contentMode = UIViewContentModeCenter;
        imageView.image = image;
        imageView.highlightedImage = [UIImage imageNamed:@"none_sticker_selected.png"];
        _noneStickerImageView = imageView;
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapNoneSticker:)];
        [noneStickerView addGestureRecognizer:tapGesture];
        
        [noneStickerView addSubview:imageView];
        
        UIView *whiteLineView = [[UIView alloc] initWithFrame:CGRectMake(56, 3, 1, 34)];
        whiteLineView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.3];
        [noneStickerView addSubview:whiteLineView];
        
        UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 40, SCREEN_WIDTH, 1)];
        lineView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.3];
        [_specialEffectsContainerView addSubview:lineView];
        
        [_specialEffectsContainerView addSubview:noneStickerView];
        [_specialEffectsContainerView addSubview:self.scrollTitleView];
        [_specialEffectsContainerView addSubview:self.collectionView];
        [_specialEffectsContainerView addSubview:self.objectTrackCollectionView];
        
        UIView *blankView = [[UIView alloc] initWithFrame:CGRectMake(0, 181, SCREEN_WIDTH, 50)];
        blankView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
        [_specialEffectsContainerView addSubview:blankView];
    }
    return _specialEffectsContainerView;
}

- (STScrollTitleView *)scrollTitleView {
    if (!_scrollTitleView) {
        
        STWeakSelf;
        
        NSArray *stickerTypeArray = @[
                                      @(STEffectsTypeStickerNew),
                                      @(STEffectsTypeSticker2D),
                                      @(STEffectsTypeStickerAvatar),
                                      @(STEffectsTypeSticker3D),
                                      @(STEffectsTypeStickerGesture),
                                      @(STEffectsTypeStickerSegment),
                                      @(STEffectsTypeStickerFaceDeformation),
                                      @(STEffectsTypeStickerFaceChange),
                                      @(STEffectsTypeStickerParticle),
                                      @(STEffectsTypeObjectTrack)];
        
        NSArray *normalImages = @[
                                  [UIImage imageNamed:@"new_sticker.png"],
                                  [UIImage imageNamed:@"2d.png"],
                                  [UIImage imageNamed:@"avatar.png"],
                                  [UIImage imageNamed:@"3d.png"],
                                  [UIImage imageNamed:@"sticker_gesture.png"],
                                  [UIImage imageNamed:@"sticker_segment.png"],
                                  [UIImage imageNamed:@"sticker_face_deformation.png"],
                                  [UIImage imageNamed:@"face_painting.png"],
                                  [UIImage imageNamed:@"particle_effect.png"],
                                  [UIImage imageNamed:@"common_object_track.png"]
                                  ];
        NSArray *selectedImages = @[
                                    [UIImage imageNamed:@"new_sticker_selected.png"],
                                    [UIImage imageNamed:@"2d_selected.png"],
                                    [UIImage imageNamed:@"avatar_selected.png"],
                                    [UIImage imageNamed:@"3d_selected.png"],
                                    [UIImage imageNamed:@"sticker_gesture_selected.png"],
                                    [UIImage imageNamed:@"sticker_segment_selected.png"],
                                    [UIImage imageNamed:@"sticker_face_deformation_selected.png"],
                                    [UIImage imageNamed:@"face_painting_selected.png"],
                                    [UIImage imageNamed:@"particle_effect_selected.png"],
                                    [UIImage imageNamed:@"common_object_track_selected.png"]
                                    ];
        
        
        _scrollTitleView = [[STScrollTitleView alloc] initWithFrame:CGRectMake(57, 0, SCREEN_WIDTH - 57, 40) normalImages:normalImages selectedImages:selectedImages effectsType:stickerTypeArray titleOnClick:^(STTitleViewItem *titleView, NSInteger index, STEffectsType type) {
            [weakSelf handleEffectsType:type];
        }];
        
        _scrollTitleView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    }
    return _scrollTitleView;
}

- (STCollectionView *)collectionView {
    if (!_collectionView) {
        _collectionView = [[STCollectionView alloc] initWithFrame:CGRectMake(0, 41, SCREEN_WIDTH, 140) withModels:nil andDelegateBlock:^(STCollectionViewDisplayModel *model) {
            
            [STManager.sharedManager handleStickerChanged:model];
        }];
        
        _collectionView.arr2DModels = STManager.sharedManager.arr2DStickers;
        _collectionView.arr3DModels = STManager.sharedManager.arr3DStickers;
        _collectionView.arrGestureModels = STManager.sharedManager.arrGestureStickers;
        _collectionView.arrSegmentModels = STManager.sharedManager.arrSegmentStickers;
        _collectionView.arrFaceDeformationModels = STManager.sharedManager.arrFacedeformationStickers;
        
        _collectionView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
        
    }
    return _collectionView;
}

- (void)handleEffectsType:(STEffectsType)type {
    
    //    self.curEffectType = type;
    
    switch (type) {
            
        case STEffectsTypeSticker2D:
        case STEffectsTypeStickerAvatar:
        case STEffectsTypeSticker3D:
        case STEffectsTypeStickerGesture:
        case STEffectsTypeStickerSegment:
        case STEffectsTypeStickerFaceChange:
        case STEffectsTypeStickerFaceDeformation:
        case STEffectsTypeStickerParticle:
        case STEffectsTypeStickerNew:
        case STEffectsTypeObjectTrack:
            self.curEffectStickerType = type;
            break;
        default:
            break;
    }
    
    switch (type) {
            
        case STEffectsTypeStickerNew:
            self.objectTrackCollectionView.hidden = YES;
            self.collectionView.hidden = NO;
            self.collectionView.arrModels = [STManager.sharedManager getStickerModelsByType:STEffectsTypeStickerNew];
            [self.collectionView reloadData];
            
            break;
            
        case STEffectsTypeSticker2D:
            self.objectTrackCollectionView.hidden = YES;
            self.collectionView.hidden = NO;
            self.collectionView.arrModels = STManager.sharedManager.arr2DStickers;
            [self.collectionView reloadData];
            break;
            
        case STEffectsTypeStickerAvatar:
            self.objectTrackCollectionView.hidden = YES;
            self.collectionView.hidden = NO;
            self.collectionView.arrModels = STManager.sharedManager.arrAvatarStickers;
            [self.collectionView reloadData];
            break;
            
        case STEffectsTypeStickerFaceDeformation:
            self.objectTrackCollectionView.hidden = YES;
            self.collectionView.hidden = NO;
            self.collectionView.arrModels = STManager.sharedManager.arrFacedeformationStickers;
            [self.collectionView reloadData];
            break;
            
        case STEffectsTypeStickerSegment:
            self.objectTrackCollectionView.hidden = YES;
            self.collectionView.hidden = NO;
            self.collectionView.arrModels = STManager.sharedManager.arrSegmentStickers;
            [self.collectionView reloadData];
            break;
            
        case STEffectsTypeStickerGesture:
            self.objectTrackCollectionView.hidden = YES;
            self.collectionView.hidden = NO;
            self.collectionView.arrModels = STManager.sharedManager.arrGestureStickers;
            [self.collectionView reloadData];
            break;
            
        case STEffectsTypeSticker3D:
            self.objectTrackCollectionView.hidden = YES;
            self.collectionView.hidden = NO;
            self.collectionView.arrModels = STManager.sharedManager.arr3DStickers;
            [self.collectionView reloadData];
            break;
            
        case STEffectsTypeObjectTrack:
            [NSNotificationCenter.defaultCenter postNotificationName:kSTStickerViewShouldChangeToBackCameraNotification object:self];
            
            [self resetCommonObjectViewPosition];
            
            self.objectTrackCollectionView.arrModels = STManager.sharedManager.arrObjectTrackers;
            self.objectTrackCollectionView.hidden = NO;
            self.collectionView.hidden = YES;
            [self.objectTrackCollectionView reloadData];
            break;
            
        case STEffectsTypeStickerFaceChange:
            
            self.objectTrackCollectionView.hidden = YES;
            self.collectionView.hidden = NO;
            self.collectionView.arrModels = STManager.sharedManager.arrFaceChangeStickers;
            [self.collectionView reloadData];
            
            break;
            
        case STEffectsTypeStickerParticle:
            self.objectTrackCollectionView.hidden = YES;
            self.collectionView.hidden = NO;
            self.collectionView.arrModels = STManager.sharedManager.arrParticleStickers;
            [self.collectionView reloadData];
            break;
            
        case STEffectsTypeNone:
            break;

        default:
            break;
    }
    
}

- (STCollectionView *)objectTrackCollectionView {
    if (!_objectTrackCollectionView) {
        
        __weak typeof(self) weakSelf = self;
        _objectTrackCollectionView = [[STCollectionView alloc] initWithFrame:CGRectMake(0, 41, SCREEN_WIDTH, 140) withModels:nil andDelegateBlock:^(STCollectionViewDisplayModel *model) {
            [weakSelf handleObjectTrackChanged:model];
        }];
        
        _objectTrackCollectionView.arrModels = STManager.sharedManager.arrObjectTrackers;
        _objectTrackCollectionView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    }
    return _objectTrackCollectionView;
}

- (void)onTapNoneSticker:(UITapGestureRecognizer *)tapGesture {
    self.collectionView.selectedModel.isSelected = NO;
    self.objectTrackCollectionView.selectedModel.isSelected = NO;
    
    [self.collectionView reloadData];
    [self.objectTrackCollectionView reloadData];
    
    self.collectionView.selectedModel = nil;
    self.objectTrackCollectionView.selectedModel = nil;
    
    if (STManager.sharedManager.hSticker) {
        
        if (self.commonObjectContainerView.currentCommonObjectView) {
            
            [self.commonObjectContainerView.currentCommonObjectView removeFromSuperview];
        }
    }
    
    [STManager.sharedManager cancelStickerAndObjectTrack];
    
    self.noneStickerImageView.highlighted = YES;
}

- (void)resetCommonObjectViewPosition {
    if (self.commonObjectContainerView.currentCommonObjectView) {
        [STManager.sharedManager resetCommonObjectViewPosition];
        self.commonObjectContainerView.currentCommonObjectView.hidden = NO;
        self.commonObjectContainerView.currentCommonObjectView.onFirst = YES;
        self.commonObjectContainerView.currentCommonObjectView.center = CGPointMake(SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2);
    }
}

- (void)handleObjectTrackChanged:(STCollectionViewDisplayModel *)model {
    
    if (self.collectionView.selectedModel || self.objectTrackCollectionView.selectedModel) {
        self.noneStickerImageView.highlighted = NO;
    } else {
        self.noneStickerImageView.highlighted = YES;
    }
    
    if (self.commonObjectContainerView.currentCommonObjectView) {
        [self.commonObjectContainerView.currentCommonObjectView removeFromSuperview];
    }
    
    if (model.isSelected) {
        UIImage *image = model.image;
        [self.commonObjectContainerView addCommonObjectViewWithImage:image];
        self.commonObjectContainerView.currentCommonObjectView.onFirst = YES;
    }
    [STManager.sharedManager handleObjectTrackChanged:model];
}

- (void)manager:(STManager *)manager commonObjectCenterDidUpdated:(CGPoint)center rect:(st_rect_t)rect {
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (self.commonObjectContainerView.currentCommonObjectView.isOnFirst) {
            //用作同步,防止再次改变currentCommonObjectView的位置
            
        } else if (rect.left == 0 && rect.top == 0 && rect.right == 0 && rect.bottom == 0) {
            
            self.commonObjectContainerView.currentCommonObjectView.hidden = YES;
            
        } else {
            self.commonObjectContainerView.currentCommonObjectView.hidden = NO;
            self.commonObjectContainerView.currentCommonObjectView.center = center;
        }
    });
}

@end
