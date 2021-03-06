//
//  MDSTBeautyFilterView.m
//  MovieousDemo
//
//  Created by Chris Wang on 2019/1/18.
//  Copyright © 2019 Movieous Team. All rights reserved.
//

#import "MDSTBeautyFilterView.h"
#import "STManager.h"
#import "STScrollTitleView.h"
#import "STFilterView.h"
#import "STBeautySlider.h"
#import "STBMPCollectionView.h"
#import "STBmpStrengthView.h"
#import "st_mobile_makeup.h"

@interface MDSTBeautyFilterView ()
<
STBeautySliderDelegate,
STBMPCollectionViewDelegate,
STBmpStrengthViewDelegate
>

@property (nonatomic, readwrite, strong) UIView *beautyContainerView;
@property (nonatomic, readwrite, strong) UIView *filterCategoryView;
@property (nonatomic, readwrite, strong) UIView *filterSwitchView;
@property (nonatomic, readwrite, strong) STFilterView *filterView;
@property (nonatomic, strong) STScrollTitleView *beautyScrollTitleViewNew;
@property (nonatomic, strong) STNewBeautyCollectionView *beautyCollectionView;
@property (nonatomic, readwrite, strong) UIView *filterStrengthView;
@property (nonatomic, readwrite, strong) UISlider *filterStrengthSlider;
@property (nonatomic, strong) UILabel *lblFilterStrength;
@property (nonatomic, readwrite, strong) NSMutableArray *arrBeautyViews;
@property (nonatomic, strong) STBeautySlider *beautySlider;
@property (nonatomic, assign) STEffectsType curEffectBeautyType;
@property (nonatomic, assign) STBeautyType curBeautyBeautyType;
@property (nonatomic, readwrite, strong) UIView *beautyShapeView;
@property (nonatomic, strong) UIView *beautyBodyView;
@property (nonatomic, readwrite, strong) NSMutableArray<STViewButton *> *arrFilterCategoryViews;
@property (nonatomic, strong) STBMPCollectionView *bmpColView;
@property (nonatomic, strong) STBmpStrengthView *bmpStrenghView;

@end

@implementation MDSTBeautyFilterView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.beautyContainerView];
        [self addSubview:self.filterStrengthView];
        [self addSubview:self.beautySlider];
        [self resetSettings];
    }
    return self;
}

- (void)resetSettings {
    self.lblFilterStrength.text = @"65";
    self.filterStrengthSlider.value = 0.65;
    
    STManager.sharedManager.currentSelectedFilterModel.isSelected = NO;
    [self refreshFilterCategoryState:STEffectsTypeNone];
    
    self.beautyCollectionView.selectedModel = nil;
    [self.beautyCollectionView reloadData];
    [STManager.sharedManager resetSettings];
}

- (UIView *)beautyContainerView {
    
    if (!_beautyContainerView) {
        _beautyContainerView = [[UIView alloc] initWithFrame:CGRectMake(0, 40, SCREEN_WIDTH, 175)];
        _beautyContainerView.backgroundColor = [UIColor clearColor];
        [_beautyContainerView addSubview:self.beautyScrollTitleViewNew];
        
        UIView *whiteLineView = [[UIView alloc] initWithFrame:CGRectMake(0, 40, SCREEN_WIDTH, 1)];
        whiteLineView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.3];
        [_beautyContainerView addSubview:whiteLineView];
        
        [_beautyContainerView addSubview:self.filterCategoryView];
        [_beautyContainerView addSubview:self.filterView];
        [_beautyContainerView addSubview:self.bmpColView];
        [_beautyContainerView addSubview:self.beautyCollectionView];
        
        [self.arrBeautyViews addObject:self.filterCategoryView];
        [self.arrBeautyViews addObject:self.filterView];
        [self.arrBeautyViews addObject:self.beautyCollectionView];
    }
    return _beautyContainerView;
}

- (STScrollTitleView *)beautyScrollTitleViewNew {
    if (!_beautyScrollTitleViewNew) {
        
        NSArray *beautyCategory = @[@"基础美颜", @"美形", @"微整形", @"美妆",@"滤镜", @"调整"];
        NSArray *beautyType = @[@(STEffectsTypeBeautyBase),
                                @(STEffectsTypeBeautyShape),
                                @(STEffectsTypeBeautyMicroSurgery),
                                @(STEffectsTypeBeautyMakeUp),
                                @(STEffectsTypeBeautyFilter),
                                @(STEffectsTypeBeautyAdjust)];
        
        STWeakSelf;
        _beautyScrollTitleViewNew = [[STScrollTitleView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 40) titles:beautyCategory effectsType:beautyType titleOnClick:^(STTitleViewItem *titleView, NSInteger index, STEffectsType type) {
            [weakSelf handleEffectsType:type];
        }];
        _beautyScrollTitleViewNew.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    }
    return _beautyScrollTitleViewNew;
}

- (STFilterView *)filterView {
    
    if (!_filterView) {
        _filterView = [[STFilterView alloc] initWithFrame:CGRectMake(SCREEN_WIDTH, 41, SCREEN_WIDTH, 134)];
        _filterView.leftView.imageView.image = [UIImage imageNamed:@"still_life_highlighted"];
        _filterView.leftView.titleLabel.text = @"静物";
        _filterView.leftView.titleLabel.textColor = [UIColor whiteColor];
        
        _filterView.filterCollectionView.arrSceneryFilterModels = STManager.sharedManager.arrSceneryFilterModels;
        _filterView.filterCollectionView.arrPortraitFilterModels = STManager.sharedManager.arrPortraitFilterModels;
        _filterView.filterCollectionView.arrStillLifeFilterModels = STManager.sharedManager.arrStillLifeFilterModels;
        _filterView.filterCollectionView.arrDeliciousFoodFilterModels = STManager.sharedManager.arrDeliciousFoodFilterModels;
        
        STWeakSelf;
        _filterView.filterCollectionView.delegateBlock = ^(STCollectionViewDisplayModel *model) {
            [weakSelf handleFilterChanged:model];
        };
        _filterView.block = ^{
            [UIView animateWithDuration:0.5 animations:^{
                weakSelf.filterCategoryView.frame = CGRectMake(0, weakSelf.filterCategoryView.frame.origin.y, SCREEN_WIDTH, 134);
                weakSelf.filterView.frame = CGRectMake(SCREEN_WIDTH, weakSelf.filterView.frame.origin.y, SCREEN_WIDTH, 134);
            }];
            weakSelf.filterStrengthView.hidden = YES;
        };
    }
    return _filterView;
}

- (void)handleFilterChanged:(STCollectionViewDisplayModel *)model {
    [STManager.sharedManager handleFilterChanged:model];
    
    if (STManager.sharedManager.bFilter) {
        self.filterStrengthView.hidden = NO;
    } else {
        self.filterStrengthView.hidden = YES;
    }
    
    self.filterStrengthSlider.value = STManager.sharedManager.fFilterStrength;
    [self refreshFilterCategoryState:model.modelType];
}

- (STBMPCollectionView *)bmpColView
{
    if (!_bmpColView) {
        _bmpColView = [[STBMPCollectionView alloc] initWithFrame:CGRectMake(0, 41, SCREEN_WIDTH, 220)];
        _bmpColView.delegate = self;
        _bmpColView.hidden = YES;
        _bmpStrenghView = [[STBmpStrengthView alloc] initWithFrame:CGRectMake(0, SCREEN_HEIGHT - 260 - 35.5, SCREEN_WIDTH, 35.5)];
        _bmpStrenghView.backgroundColor = [UIColor clearColor];
        _bmpStrenghView.hidden = YES;
        _bmpStrenghView.delegate = self;
        [self addSubview:_bmpStrenghView];
    }
    return _bmpColView;
}

#pragma STBmpStrengthViewDelegate
- (void)sliderValueDidChange:(float)value
{
    [_bmpStrenghView updateSliderValue:value];
    [STManager.sharedManager sliderValueDidChange:value];
}

#pragma STBMPCollectionViewDelegate
- (void)didSelectedDetailModel:(STBMPModel *)model
{
    
    if (model.m_index == 0) {
        _bmpStrenghView.hidden = YES;
    }else{
        _bmpStrenghView.hidden = NO;
    }
    
    switch (model.m_bmpType) {
        case STBMPTYPE_EYE:
            [_bmpStrenghView updateSliderValue:STManager.sharedManager.bmp_Eye_Value];
            break;
        case STBMPTYPE_EYELINER:
            [_bmpStrenghView updateSliderValue:STManager.sharedManager.bmp_EyeLiner_Value];
            break;
        case STBMPTYPE_EYELASH:
            [_bmpStrenghView updateSliderValue:STManager.sharedManager.bmp_EyeLash_Value];
            break;
        case STBMPTYPE_LIP:
            [_bmpStrenghView updateSliderValue:STManager.sharedManager.bmp_Lip_Value];
            break;
        case STBMPTYPE_BROW:
            [_bmpStrenghView updateSliderValue:STManager.sharedManager.bmp_Brow_Value];
            break;
        case STBMPTYPE_FACE:
            [_bmpStrenghView updateSliderValue:STManager.sharedManager.bmp_Face_Value];
            break;
        case STBMPTYPE_BLUSH:
            [_bmpStrenghView updateSliderValue:STManager.sharedManager.bmp_Blush_Value];
            break;
        case STBMPTYPE_EYEBALL:
            [_bmpStrenghView updateSliderValue:STManager.sharedManager.bmp_Eyeball_Value];
            break;
        case STBMPTYPE_COUNT:
            break;
    }
    [STManager.sharedManager didSelectedDetailModel:model];
}

- (void)backToMainView
{
    self.bmpStrenghView.hidden = YES;
}

- (STNewBeautyCollectionView *)beautyCollectionView {
    
    if (!_beautyCollectionView) {
        
        STWeakSelf;
        
        _beautyCollectionView = [[STNewBeautyCollectionView alloc] initWithFrame:CGRectMake(0, 41, SCREEN_WIDTH, 220) models:STManager.sharedManager.baseBeautyModels delegateBlock:^(STNewBeautyCollectionViewModel *model) {
            
            [weakSelf handleBeautyTypeChanged:model];
            
            
        }];
        
        _beautyCollectionView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
        
        [_beautyCollectionView reloadData];
    }
    return _beautyCollectionView;
}

- (UIView *)filterStrengthView {
    
    if (!_filterStrengthView) {
        
        _filterStrengthView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 40)];
        _filterStrengthView.backgroundColor = [UIColor clearColor];
        _filterStrengthView.hidden = YES;
        
        UILabel *leftLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, 10, 40)];
        leftLabel.textColor = [UIColor whiteColor];
        leftLabel.font = [UIFont systemFontOfSize:11];
        leftLabel.text = @"0";
        [_filterStrengthView addSubview:leftLabel];
        
        UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(40, 0, SCREEN_WIDTH - 90, 40)];
        slider.thumbTintColor = UIColorFromRGB(0x9e4fcb);
        slider.minimumTrackTintColor = UIColorFromRGB(0x9e4fcb);
        slider.maximumTrackTintColor = [UIColor whiteColor];
        slider.value = 1;
        [slider addTarget:self action:@selector(filterSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
        _filterStrengthSlider = slider;
        [_filterStrengthView addSubview:slider];
        
        UILabel *rightLabel = [[UILabel alloc] initWithFrame:CGRectMake(SCREEN_WIDTH - 40, 0, 20, 40)];
        rightLabel.textColor = [UIColor whiteColor];
        rightLabel.font = [UIFont systemFontOfSize:11];
        rightLabel.text = [NSString stringWithFormat:@"%d", (int)(STManager.sharedManager.fFilterStrength * 100)];
        _lblFilterStrength = rightLabel;
        [_filterStrengthView addSubview:rightLabel];
    }
    return _filterStrengthView;
}

- (void)filterSliderValueChanged:(UISlider *)sender {
    STManager.sharedManager.fFilterStrength = sender.value;
    _lblFilterStrength.text = [NSString stringWithFormat:@"%d", (int)(sender.value * 100)];
}

- (NSMutableArray *)arrBeautyViews {
    if (!_arrBeautyViews) {
        _arrBeautyViews = [NSMutableArray array];
    }
    return _arrBeautyViews;
}

- (void)handleBeautyTypeChanged:(STNewBeautyCollectionViewModel *)model {
    
    float preType = self.curBeautyBeautyType;
    float preValue = self.beautySlider.value;
    float curValue = -2;
    float lblVal = -2;
    
    self.curBeautyBeautyType = model.beautyType;
    
    self.beautySlider.hidden = NO;
    
    
    switch (model.beautyType) {
            
        case STBeautyTypeNone:
        case STBeautyTypeWhiten:
        case STBeautyTypeRuddy:
        case STBeautyTypeDermabrasion:
        case STBeautyTypeDehighlight:
        case STBeautyTypeShrinkFace:
        case STBeautyTypeEnlargeEyes:
        case STBeautyTypeShrinkJaw:
        case STBeautyTypeThinFaceShape:
        case STBeautyTypeNarrowNose:
        case STBeautyTypeContrast:
        case STBeautyTypeSaturation:
        case STBeautyTypeNarrowFace:
        case STBeautyTypeRoundEye:
        case STBeautyTypeAppleMusle:
        case STBeautyTypeProfileRhinoplasty:
        case STBeautyTypeBrightEye:
        case STBeautyTypeRemoveDarkCircles:
        case STBeautyTypeWhiteTeeth:
        case STBeautyTypeOpenCanthus:
        case STBeautyTypeRemoveNasolabialFolds:
            
            
            curValue = model.beautyValue / 50.0 - 1;
            lblVal = (curValue + 1) * 50.0;
            
            break;
            
            
        case STBeautyTypeChin:
        case STBeautyTypeHairLine:
        case STBeautyTypeLengthNose:
        case STBeautyTypeMouthSize:
        case STBeautyTypeLengthPhiltrum:
        case STBeautyTypeEyeAngle:
        case STBeautyTypeEyeDistance:
            
            curValue = model.beautyValue / 100.0;
            lblVal = curValue * 100.0;
            
            break;
    }
    
    if (curValue == preValue && preType != model.beautyType) {
        
        if (lblVal > 9.9 && lblVal < 10.0) {
            lblVal = 10;
        }
        
        self.beautySlider.valueLabel.text = [NSString stringWithFormat:@"%d", (int)lblVal];
    }
    self.beautySlider.value = curValue;
}

- (UISlider *)beautySlider {
    if (!_beautySlider) {
        
        _beautySlider = [[STBeautySlider alloc] initWithFrame:CGRectMake(40, 0, SCREEN_WIDTH - 90, 40)];
        _beautySlider.thumbTintColor = UIColorFromRGB(0x9e4fcb);
        _beautySlider.minimumTrackTintColor = UIColorFromRGB(0x9e4fcb);
        _beautySlider.maximumTrackTintColor = [UIColor whiteColor];
        _beautySlider.minimumValue = -1;
        _beautySlider.maximumValue = 1;
        _beautySlider.value = 0;
        _beautySlider.hidden = YES;
        _beautySlider.delegate = self;
        [_beautySlider addTarget:self action:@selector(beautySliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    }
    return _beautySlider;
}

- (void)beautySliderValueChanged:(UISlider *)sender {
    
    
    //[-1,1] -> [0,1]
    float value1 = (sender.value + 1) / 2;
    
    //[-1,1]
    float value2 = sender.value;
    
    STNewBeautyCollectionViewModel *model = self.beautyCollectionView.selectedModel;
    
    //    model.beautyValue = value * 100;
    
    //    [self.beautyCollectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:model.modelIndex inSection:0]]];
    
    switch (model.beautyType) {
            
        case STBeautyTypeNone:
            break;
        case STBeautyTypeWhiten:
            STManager.sharedManager.fWhitenStrength = value1;
            model.beautyValue = value1 * 100;
            break;
        case STBeautyTypeRuddy:
            STManager.sharedManager.fReddenStrength = value1;
            model.beautyValue = value1 * 100;
            break;
        case STBeautyTypeDermabrasion:
            STManager.sharedManager.fSmoothStrength = value1;
            model.beautyValue = value1 * 100;
            break;
        case STBeautyTypeDehighlight:
            STManager.sharedManager.fDehighlightStrength = value1;
            model.beautyValue = value1 * 100;
            break;
        case STBeautyTypeShrinkFace:
            STManager.sharedManager.fShrinkFaceStrength = value1;
            model.beautyValue = value1 * 100;
            break;
        case STBeautyTypeNarrowFace:
            STManager.sharedManager.fNarrowFaceStrength = value1;
            model.beautyValue = value1 * 100;
            break;
        case STBeautyTypeEnlargeEyes:
            STManager.sharedManager.fEnlargeEyeStrength = value1;
            model.beautyValue = value1 * 100;
            break;
        case STBeautyTypeShrinkJaw:
            STManager.sharedManager.fShrinkJawStrength = value1;
            model.beautyValue = value1 * 100;
            break;
        case STBeautyTypeThinFaceShape:
            STManager.sharedManager.fThinFaceShapeStrength = value1;
            model.beautyValue = value1 * 100;
            break;
        case STBeautyTypeChin:
            STManager.sharedManager.fChinStrength = value2;
            model.beautyValue = value2 * 100;
            break;
        case STBeautyTypeHairLine:
            STManager.sharedManager.fHairLineStrength = value2;
            model.beautyValue = value2 * 100;
            break;
        case STBeautyTypeNarrowNose:
            STManager.sharedManager.fNarrowNoseStrength = value1;
            model.beautyValue = value1 * 100;
            break;
        case STBeautyTypeLengthNose:
            STManager.sharedManager.fLongNoseStrength = value2;
            model.beautyValue = value2 * 100;
            break;
        case STBeautyTypeMouthSize:
            STManager.sharedManager.fMouthStrength = value2;
            model.beautyValue = value2 * 100;
            break;
        case STBeautyTypeLengthPhiltrum:
            STManager.sharedManager.fPhiltrumStrength = value2;
            model.beautyValue = value2 * 100;
            break;
        case STBeautyTypeContrast:
            STManager.sharedManager.fContrastStrength = value1;
            model.beautyValue = value1 * 100;
            break;
        case STBeautyTypeSaturation:
            STManager.sharedManager.fSaturationStrength = value1;
            model.beautyValue = value1 * 100;
            break;
        case STBeautyTypeAppleMusle:
            STManager.sharedManager.fAppleMusleStrength = value1;
            model.beautyValue = value1 * 100;
            break;
        case STBeautyTypeProfileRhinoplasty:
            STManager.sharedManager.fProfileRhinoplastyStrength = value1;
            model.beautyValue = value1 * 100;
            break;
        case STBeautyTypeBrightEye:
            STManager.sharedManager.fBrightEyeStrength = value1;
            model.beautyValue = value1 * 100;
            break;
        case STBeautyTypeRemoveDarkCircles:
            STManager.sharedManager.fRemoveDarkCirclesStrength = value1;
            model.beautyValue = value1 * 100;
            break;
        case STBeautyTypeWhiteTeeth:
            STManager.sharedManager.fWhiteTeethStrength = value1;
            model.beautyValue = value1 * 100;
            break;
        case STBeautyTypeEyeDistance:
            STManager.sharedManager.fEyeDistanceStrength = value2;
            model.beautyValue = value2 * 100;
            break;
        case STBeautyTypeEyeAngle:
            STManager.sharedManager.fEyeAngleStrength = value2;
            model.beautyValue = value2 * 100;
            break;
        case STBeautyTypeOpenCanthus:
            STManager.sharedManager.fOpenCanthusStrength = value1;
            model.beautyValue = value1 * 100;
            break;
        case STBeautyTypeRemoveNasolabialFolds:
            STManager.sharedManager.fRemoveNasolabialFoldsStrength = value1;
            model.beautyValue = value1 * 100;
            break;
    }
    [self.beautyCollectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:model.modelIndex inSection:0]]];
}

- (void)setDefaultValue {
    self.curEffectBeautyType = STEffectsTypeBeautyBase;
}

- (void)handleEffectsType:(STEffectsType)type {
    
    switch (type) {
        case STEffectsTypeBeautyFilter:
        case STEffectsTypeBeautyBase:
        case STEffectsTypeBeautyShape:
        case STEffectsTypeBeautyMicroSurgery:
        case STEffectsTypeBeautyAdjust:
            self.curEffectBeautyType = type;
            break;
        case STEffectsTypeBeautyMakeUp:
            self.curEffectBeautyType = type;
            break;
        default:
            break;
    }
    
    if (type != STEffectsTypeBeautyFilter) {
        self.filterStrengthView.hidden = YES;
    }
    
    if (type == self.beautyCollectionView.selectedModel.modelType) {
        self.beautySlider.hidden = NO;
    } else {
        self.beautySlider.hidden = YES;
    }
    
    switch (type) {
        case STEffectsTypeBeautyFilter:
            
            self.filterCategoryView.hidden = NO;
            self.filterView.hidden = NO;
            self.beautyCollectionView.hidden = YES;
            
            self.filterCategoryView.center = CGPointMake(SCREEN_WIDTH / 2, self.filterCategoryView.center.y);
            self.filterView.center = CGPointMake(SCREEN_WIDTH * 3 / 2, self.filterView.center.y);
            
            _bmpColView.hidden = YES;
            _bmpStrenghView.hidden = YES;
            
            break;
            
        case STEffectsTypeBeautyMakeUp:
            self.beautyCollectionView.hidden = YES;
            self.filterCategoryView.hidden = YES;
            self.filterView.hidden = YES;
            
            _bmpColView.hidden = NO;
            
        case STEffectsTypeNone:
            break;
            
        case STEffectsTypeBeautyShape:
            
            [self hideBeautyViewExcept:self.beautyShapeView];
            self.filterStrengthView.hidden = YES;
            
            self.beautyCollectionView.hidden = NO;
            self.filterCategoryView.hidden = YES;
            self.beautyCollectionView.models = STManager.sharedManager.beautyShapeModels;
            [self.beautyCollectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
            
            _bmpColView.hidden = YES;
            _bmpStrenghView.hidden = YES;
            
            break;
            
        case STEffectsTypeBeautyBase:
            
            self.filterStrengthView.hidden = YES;
            [self hideBeautyViewExcept:self.beautyCollectionView];
            
            self.beautyCollectionView.hidden = NO;
            self.filterCategoryView.hidden = YES;
            self.beautyCollectionView.models = STManager.sharedManager.baseBeautyModels;
            [self.beautyCollectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
            
            _bmpColView.hidden = YES;
            _bmpStrenghView.hidden = YES;
            
            break;
            
        case STEffectsTypeBeautyMicroSurgery:
            
            
            [self hideBeautyViewExcept:self.beautyCollectionView];
            self.beautyCollectionView.hidden = NO;
            self.filterCategoryView.hidden = YES;
            self.beautyCollectionView.models = STManager.sharedManager.microSurgeryModels;
            [self.beautyCollectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
            
            _bmpColView.hidden = YES;
            _bmpStrenghView.hidden = YES;
            
            break;
            
        case STEffectsTypeBeautyAdjust:
            [self hideBeautyViewExcept:self.beautyCollectionView];
            self.beautyCollectionView.hidden = NO;
            self.filterCategoryView.hidden = YES;
            self.beautyCollectionView.models = STManager.sharedManager.adjustModels;
            [self.beautyCollectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
            
            _bmpColView.hidden = YES;
            _bmpStrenghView.hidden = YES;
            
            break;
            
            
        case STEffectsTypeBeautyBody:
            
            self.filterStrengthView.hidden = YES;
            [self hideBeautyViewExcept:self.beautyBodyView];
            break;
            
        default:
            break;
    }
    
}

- (void)hideBeautyViewExcept:(UIView *)view {
    
    for (UIView *beautyView in self.arrBeautyViews) {
        
        beautyView.hidden = !(view == beautyView);
    }
}

- (UIView *)filterCategoryView {
    
    if (!_filterCategoryView) {
        
        _filterCategoryView = [[UIView alloc] initWithFrame:CGRectMake(0, 41, SCREEN_WIDTH, 134)];
        _filterCategoryView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
        
        
        STViewButton *portraitViewBtn = [[[NSBundle mainBundle] loadNibNamed:@"STViewButton" owner:nil options:nil] firstObject];
        portraitViewBtn.tag = STEffectsTypeFilterPortrait;
        portraitViewBtn.backgroundColor = [UIColor clearColor];
        portraitViewBtn.frame =  CGRectMake(SCREEN_WIDTH / 2 - 143, 30, 33, 60);
        portraitViewBtn.imageView.image = [UIImage imageNamed:@"portrait"];
        portraitViewBtn.imageView.highlightedImage = [UIImage imageNamed:@"portrait_highlighted"];
        portraitViewBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        portraitViewBtn.titleLabel.textColor = [UIColor whiteColor];
        portraitViewBtn.titleLabel.highlightedTextColor = [UIColor whiteColor];
        portraitViewBtn.titleLabel.text = @"人物";
        
        for (UIGestureRecognizer *recognizer in portraitViewBtn.gestureRecognizers) {
            [portraitViewBtn removeGestureRecognizer:recognizer];
        }
        UITapGestureRecognizer *portraitRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(switchFilterType:)];
        [portraitViewBtn addGestureRecognizer:portraitRecognizer];
        [self.arrFilterCategoryViews addObject:portraitViewBtn];
        [_filterCategoryView addSubview:portraitViewBtn];
        
        
        
        STViewButton *sceneryViewBtn = [[[NSBundle mainBundle] loadNibNamed:@"STViewButton" owner:nil options:nil] firstObject];
        sceneryViewBtn.tag = STEffectsTypeFilterScenery;
        sceneryViewBtn.backgroundColor = [UIColor clearColor];
        sceneryViewBtn.frame =  CGRectMake(SCREEN_WIDTH / 2 - 60, 30, 33, 60);
        sceneryViewBtn.imageView.image = [UIImage imageNamed:@"scenery"];
        sceneryViewBtn.imageView.highlightedImage = [UIImage imageNamed:@"scenery_highlighted"];
        sceneryViewBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        sceneryViewBtn.titleLabel.textColor = [UIColor whiteColor];
        sceneryViewBtn.titleLabel.highlightedTextColor = [UIColor whiteColor];
        sceneryViewBtn.titleLabel.text = @"风景";
        
        for (UIGestureRecognizer *recognizer in sceneryViewBtn.gestureRecognizers) {
            [sceneryViewBtn removeGestureRecognizer:recognizer];
        }
        UITapGestureRecognizer *sceneryRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(switchFilterType:)];
        [sceneryViewBtn addGestureRecognizer:sceneryRecognizer];
        [self.arrFilterCategoryViews addObject:sceneryViewBtn];
        [_filterCategoryView addSubview:sceneryViewBtn];
        
        
        
        STViewButton *stillLifeViewBtn = [[[NSBundle mainBundle] loadNibNamed:@"STViewButton" owner:nil options:nil] firstObject];
        stillLifeViewBtn.tag = STEffectsTypeFilterStillLife;
        stillLifeViewBtn.backgroundColor = [UIColor clearColor];
        stillLifeViewBtn.frame =  CGRectMake(SCREEN_WIDTH / 2 + 27, 30, 33, 60);
        stillLifeViewBtn.imageView.image = [UIImage imageNamed:@"still_life"];
        stillLifeViewBtn.imageView.highlightedImage = [UIImage imageNamed:@"still_life_highlighted"];
        stillLifeViewBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        stillLifeViewBtn.titleLabel.textColor = [UIColor whiteColor];
        stillLifeViewBtn.titleLabel.highlightedTextColor = [UIColor whiteColor];
        stillLifeViewBtn.titleLabel.text = @"静物";
        
        for (UIGestureRecognizer *recognizer in stillLifeViewBtn.gestureRecognizers) {
            [stillLifeViewBtn removeGestureRecognizer:recognizer];
        }
        UITapGestureRecognizer *stillLifeRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(switchFilterType:)];
        [stillLifeViewBtn addGestureRecognizer:stillLifeRecognizer];
        [self.arrFilterCategoryViews addObject:stillLifeViewBtn];
        [_filterCategoryView addSubview:stillLifeViewBtn];
        
        
        
        STViewButton *deliciousFoodViewBtn = [[[NSBundle mainBundle] loadNibNamed:@"STViewButton" owner:nil options:nil] firstObject];
        deliciousFoodViewBtn.tag = STEffectsTypeFilterDeliciousFood;
        deliciousFoodViewBtn.backgroundColor = [UIColor clearColor];
        deliciousFoodViewBtn.frame =  CGRectMake(SCREEN_WIDTH / 2 + 110, 30, 33, 60);
        deliciousFoodViewBtn.imageView.image = [UIImage imageNamed:@"delicious_food"];
        deliciousFoodViewBtn.imageView.highlightedImage = [UIImage imageNamed:@"delicious_food_highlighted"];
        deliciousFoodViewBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        deliciousFoodViewBtn.titleLabel.textColor = [UIColor whiteColor];
        deliciousFoodViewBtn.titleLabel.highlightedTextColor = [UIColor whiteColor];
        deliciousFoodViewBtn.titleLabel.text = @"美食";
        
        for (UIGestureRecognizer *recognizer in deliciousFoodViewBtn.gestureRecognizers) {
            [deliciousFoodViewBtn removeGestureRecognizer:recognizer];
        }
        UITapGestureRecognizer *deliciousFoodRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(switchFilterType:)];
        [deliciousFoodViewBtn addGestureRecognizer:deliciousFoodRecognizer];
        [self.arrFilterCategoryViews addObject:deliciousFoodViewBtn];
        [_filterCategoryView addSubview:deliciousFoodViewBtn];
        
    }
    return _filterCategoryView;
}

- (void)switchFilterType:(UITapGestureRecognizer *)recognizer {
    
    [UIView animateWithDuration:0.5 animations:^{
        self.filterCategoryView.frame = CGRectMake(-SCREEN_WIDTH, self.filterCategoryView.frame.origin.y, SCREEN_WIDTH, 134);
        self.filterView.frame = CGRectMake(0, self.filterView.frame.origin.y, SCREEN_WIDTH, 134);
    }];
    
    if (STManager.sharedManager.currentSelectedFilterModel.modelType == recognizer.view.tag && STManager.sharedManager.currentSelectedFilterModel.isSelected) {
        self.filterStrengthView.hidden = NO;
    } else {
        self.filterStrengthView.hidden = YES;
    }
    
    //    self.filterStrengthView.hidden = !(self.currentSelectedFilterModel.modelType == recognizer.view.tag);
    
    switch (recognizer.view.tag) {
            
        case STEffectsTypeFilterPortrait:
            
            _filterView.leftView.imageView.image = [UIImage imageNamed:@"portrait_highlighted"];
            _filterView.leftView.titleLabel.text = @"人物";
            _filterView.filterCollectionView.arrModels = _filterView.filterCollectionView.arrPortraitFilterModels;
            
            break;
            
            
        case STEffectsTypeFilterScenery:
            
            _filterView.leftView.imageView.image = [UIImage imageNamed:@"scenery_highlighted"];
            _filterView.leftView.titleLabel.text = @"风景";
            _filterView.filterCollectionView.arrModels = _filterView.filterCollectionView.arrSceneryFilterModels;
            
            break;
            
        case STEffectsTypeFilterStillLife:
            
            _filterView.leftView.imageView.image = [UIImage imageNamed:@"still_life_highlighted"];
            _filterView.leftView.titleLabel.text = @"静物";
            _filterView.filterCollectionView.arrModels = _filterView.filterCollectionView.arrStillLifeFilterModels;
            
            break;
            
        case STEffectsTypeFilterDeliciousFood:
            
            _filterView.leftView.imageView.image = [UIImage imageNamed:@"delicious_food_highlighted"];
            _filterView.leftView.titleLabel.text = @"美食";
            _filterView.filterCollectionView.arrModels = _filterView.filterCollectionView.arrDeliciousFoodFilterModels;
            
            break;
            
        default:
            break;
    }
    
    [_filterView.filterCollectionView reloadData];
}

- (void)refreshFilterCategoryState:(STEffectsType)type {
    
    for (int i = 0; i < self.arrFilterCategoryViews.count; ++i) {
        
        if (self.arrFilterCategoryViews[i].highlighted) {
            self.arrFilterCategoryViews[i].highlighted = NO;
        }
    }
    
    switch (type) {
        case STEffectsTypeFilterPortrait:
            
            self.arrFilterCategoryViews[0].highlighted = YES;
            
            break;
            
        case STEffectsTypeFilterScenery:
            
            self.arrFilterCategoryViews[1].highlighted = YES;
            
            break;
            
        case STEffectsTypeFilterStillLife:
            
            self.arrFilterCategoryViews[2].highlighted = YES;
            
            break;
            
        case STEffectsTypeFilterDeliciousFood:
            
            self.arrFilterCategoryViews[3].highlighted = YES;
            
            break;
            
        default:
            break;
    }
}

- (NSMutableArray *)arrFilterCategoryViews {
    
    if (!_arrFilterCategoryViews) {
        
        _arrFilterCategoryViews = [NSMutableArray array];
    }
    return _arrFilterCategoryViews;
}

- (CGFloat)currentSliderValue:(float)value slider:(UISlider *)slider {
    
    switch (self.curBeautyBeautyType) {
            
        case STBeautyTypeNone:
        case STBeautyTypeWhiten:
        case STBeautyTypeRuddy:
        case STBeautyTypeDermabrasion:
        case STBeautyTypeDehighlight:
        case STBeautyTypeShrinkFace:
        case STBeautyTypeEnlargeEyes:
        case STBeautyTypeShrinkJaw:
        case STBeautyTypeThinFaceShape:
        case STBeautyTypeNarrowNose:
        case STBeautyTypeContrast:
        case STBeautyTypeSaturation:
        case STBeautyTypeNarrowFace:
        case STBeautyTypeRoundEye:
        case STBeautyTypeAppleMusle:
        case STBeautyTypeProfileRhinoplasty:
        case STBeautyTypeBrightEye:
        case STBeautyTypeRemoveDarkCircles:
        case STBeautyTypeWhiteTeeth:
        case STBeautyTypeOpenCanthus:
        case STBeautyTypeRemoveNasolabialFolds:
            value = (value + 1) / 2.0;
            break;
            
        default:
            break;
            
    }
    
    return value;
}


@end
