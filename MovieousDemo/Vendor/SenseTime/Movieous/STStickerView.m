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
#import "EffectsCollectionView.h"
#import "EffectsCollectionViewCell.h"

@interface STStickerView ()
<
STManagerDelegate
>

@property (nonatomic, readwrite, strong) UIView *specialEffectsContainerView;
@property (nonatomic, readwrite, strong) UIImageView *noneStickerImageView;
@property (nonatomic, readwrite, strong) STScrollTitleView *scrollTitleView;

@property (nonatomic , strong) EffectsCollectionView *effectsList;
@property (nonatomic, readwrite, strong) STFilterCollectionView *filterCollectionView;

@property (nonatomic, assign) STEffectsType curEffectStickerType;
@property (nonatomic, readwrite, strong) NSArray<STCollectionViewDisplayModel *> *arr2DModels;
@property (nonatomic, readwrite, strong) NSArray<STCollectionViewDisplayModel *> *arr3DModels;
@property (nonatomic, readwrite, strong) NSArray<STCollectionViewDisplayModel *> *arrGestureModels;
@property (nonatomic, readwrite, strong) NSArray<STCollectionViewDisplayModel *> *arrSegmentModels;
@property (nonatomic, readwrite, strong) NSArray<STCollectionViewDisplayModel *> *arrFaceDeformationModels;
@property (nonatomic, readwrite, strong) NSArray<STCollectionViewDisplayModel *> *arrFilterModels;
@property (nonatomic, readwrite, strong) NSArray<STCollectionViewDisplayModel *> *arrObjectTrackModels;

@property (nonatomic , strong) NSArray *arrCurrentModels;

@end

@implementation STStickerView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        STManager.sharedManager.delegate = self;
        [self addSubview:self.specialEffectsContainerView];
        [self resetSettings];
    }
    return self;
}

- (void)resetSettings {
    self.noneStickerImageView.highlighted = YES;
}

- (UIView *)specialEffectsContainerView {
    if (!_specialEffectsContainerView) {
        _specialEffectsContainerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 181)];
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
        [_specialEffectsContainerView addSubview:self.effectsList];
        
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
                                      @(STEffectsTypeStickerMy),
                                      @(STEffectsTypeStickerNew),
                                      @(STEffectsTypeSticker2D),
                                      @(STEffectsTypeStickerAvatar),
                                      @(STEffectsTypeSticker3D),
                                      @(STEffectsTypeStickerGesture),
                                      @(STEffectsTypeStickerSegment),
                                      @(STEffectsTypeStickerFaceDeformation),
                                      @(STEffectsTypeStickerFaceChange),
                                      @(STEffectsTypeStickerParticle),
//                                      @(STEffectsTypeObjectTrack)
                                      ];
        
        NSArray *normalImages = @[
                                  [UIImage imageNamed:@"native.png"],
                                  [UIImage imageNamed:@"new_sticker.png"],
                                  [UIImage imageNamed:@"2d.png"],
                                  [UIImage imageNamed:@"avatar.png"],
                                  [UIImage imageNamed:@"3d.png"],
                                  [UIImage imageNamed:@"sticker_gesture.png"],
                                  [UIImage imageNamed:@"sticker_segment.png"],
                                  [UIImage imageNamed:@"sticker_face_deformation.png"],
                                  [UIImage imageNamed:@"face_painting.png"],
                                  [UIImage imageNamed:@"particle_effect.png"],
//                                  [UIImage imageNamed:@"common_object_track.png"]
                                  ];
        NSArray *selectedImages = @[
                                    [UIImage imageNamed:@"native_selected.png"],
                                    [UIImage imageNamed:@"new_sticker_selected.png"],
                                    [UIImage imageNamed:@"2d_selected.png"],
                                    [UIImage imageNamed:@"avatar_selected.png"],
                                    [UIImage imageNamed:@"3d_selected.png"],
                                    [UIImage imageNamed:@"sticker_gesture_selected.png"],
                                    [UIImage imageNamed:@"sticker_segment_selected.png"],
                                    [UIImage imageNamed:@"sticker_face_deformation_selected.png"],
                                    [UIImage imageNamed:@"face_painting_selected.png"],
                                    [UIImage imageNamed:@"particle_effect_selected.png"],
//                                    [UIImage imageNamed:@"common_object_track_selected.png"]
                                    ];
        
        
        _scrollTitleView = [[STScrollTitleView alloc] initWithFrame:CGRectMake(57, 0, SCREEN_WIDTH - 57, 40) normalImages:normalImages selectedImages:selectedImages effectsType:stickerTypeArray titleOnClick:^(STTitleViewItem *titleView, NSInteger index, STEffectsType type) {
            
            [weakSelf handleEffectsType:type];
        }];
        
        _scrollTitleView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    }
    return _scrollTitleView;
}

- (void)handleEffectsType:(STEffectsType)type {
    
    switch (type) {
            
        case STEffectsTypeStickerMy:
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
            
        case STEffectsTypeStickerMy:
        case STEffectsTypeStickerNew:
        case STEffectsTypeSticker2D:
        case STEffectsTypeStickerAvatar:
        case STEffectsTypeStickerFaceDeformation:
        case STEffectsTypeStickerSegment:
        case STEffectsTypeSticker3D:
        case STEffectsTypeStickerGesture:
        case STEffectsTypeStickerFaceChange:
        case STEffectsTypeStickerParticle:
            self.arrCurrentModels = [STManager.sharedManager.effectsDataSource objectForKey:@(type)];
            [self.effectsList reloadData];
            
            self.effectsList.hidden = NO;
            
            break;
            
        default:
            break;
    }
    
}

- (void)onTapNoneSticker:(UITapGestureRecognizer *)tapGesture {
    
    [self cancelStickerAndObjectTrack];
    
    self.noneStickerImageView.highlighted = YES;
}

- (void)cancelStickerAndObjectTrack {
    [STManager.sharedManager handleStickerChanged:nil];
    [STManager.sharedManager cancelStickerAndObjectTrack];
}

- (EffectsCollectionView *)effectsList
{
    if (!_effectsList) {
        
        __weak typeof(self) weakSelf = self;
        _effectsList = [[EffectsCollectionView alloc] initWithFrame:CGRectMake(0, 41, SCREEN_WIDTH, 140)];
        [_effectsList registerNib:[UINib nibWithNibName:@"EffectsCollectionViewCell"
                                                 bundle:[NSBundle mainBundle]]
       forCellWithReuseIdentifier:@"EffectsCollectionViewCell"];
        _effectsList.numberOfSectionsInView = ^NSInteger(STCustomCollectionView *collectionView) {
            
            return 1;
        };
        _effectsList.numberOfItemsInSection = ^NSInteger(STCustomCollectionView *collectionView, NSInteger section) {
            
            return weakSelf.arrCurrentModels.count;
        };
        _effectsList.cellForItemAtIndexPath = ^UICollectionViewCell *(STCustomCollectionView *collectionView, NSIndexPath *indexPath) {
            
            static NSString *strIdentifier = @"EffectsCollectionViewCell";
            
            EffectsCollectionViewCell *cell = (EffectsCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:strIdentifier forIndexPath:indexPath];
            
            NSArray *arrModels = weakSelf.arrCurrentModels;
            
            if (arrModels.count) {
                
                EffectsCollectionViewCellModel *model = arrModels[indexPath.item];
                
                if (model.iEffetsType != STEffectsTypeStickerMy) {
                    
                    id cacheObj = [STManager.sharedManager.thumbnailCache objectForKey:model.material.strMaterialFileID];
                    
                    if (cacheObj && [cacheObj isKindOfClass:[UIImage class]]) {
                        
                        model.imageThumb = cacheObj;
                    }else{
                        
                        model.imageThumb = [UIImage imageNamed:@"none"];
                    }
                }
                
                cell.model = model;
                
                return cell;
            }else{
                
                cell.model = nil;
                
                return cell;
            }
        };
        _effectsList.didSelectItematIndexPath = ^(STCustomCollectionView *collectionView, NSIndexPath *indexPath) {
            
            NSArray *arrModels = weakSelf.arrCurrentModels;
            
            [STManager.sharedManager handleStickerChanged:arrModels[indexPath.item]];
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.effectsList reloadData];
            });
        };
    }
    
    return _effectsList;
}

- (void)manager:(STManager *)manager fetchMaterialSuccess:(STEffectsType)iType {
    if (iType == self.curEffectStickerType) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self.effectsList reloadData];
        });
    }
}

- (void)manager:(STManager *)manager fetchListDone:(NSArray *)arrLocalModels {
    self.arrCurrentModels = arrLocalModels;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self.effectsList reloadData];
    });
}

- (void)manager:(STManager *)manager cachedThumbnail:(EffectsCollectionViewCellModel *)model {
    if (self.curEffectStickerType == model.iEffetsType) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self.effectsList reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:model.indexOfItem inSection:0]]];
        });
    }
}

- (void)manager:(STManager *)manager modelUpdated:(EffectsCollectionViewCellModel *)model {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.effectsList reloadData];
    });
}

@end
