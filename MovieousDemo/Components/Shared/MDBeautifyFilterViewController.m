//
//  MDBeautifyFilterViewController.m
//  MovieousDemo
//
//  Created by Chris Wang on 2018/10/31.
//  Copyright © 2018 Movieous Team. All rights reserved.
//

#import "MDBeautifyFilterViewController.h"
#import "FUAPIDemoBar.h"
#import "FUManager.h"
#import "MDGlobalSettings.h"
#import "MDSTBeautyFilterPanel.h"
#import "CameraFilterPanelView.h"
#import "CameraBeautyPanelView.h"

@interface MDBeautifyFilterViewController ()
<
FUAPIDemoBarDelegate
>

@property (strong, nonatomic) IBOutlet UIView *innerBeautyFilterPanel;
@property (strong, nonatomic) IBOutlet FUAPIDemoBar *FUBeautyFilterPanel;
@property (strong, nonatomic) IBOutlet MDSTBeautyFilterPanel *STBeautyFilterPanel;

@end

@implementation MDBeautifyFilterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    if (MDGlobalSettings.sharedInstance.vendorType == VendorTypeNone) {
        _innerBeautyFilterPanel.hidden = NO;
    } else if (MDGlobalSettings.sharedInstance.vendorType == VendorTypeFaceunity) {
        _FUBeautyFilterPanel.hidden = NO;
        _FUBeautyFilterPanel.delegate = self;
    } else if (MDGlobalSettings.sharedInstance.vendorType == VendorTypeSenseTime) {
        _STBeautyFilterPanel.hidden = NO;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    if (MDGlobalSettings.sharedInstance.vendorType == VendorTypeFaceunity) {
        // 将 FUManager 的参数同步到 UI
        [self demoBarSetBeautyDefultParams];
    }
}

// 美颜参数改变
- (void)demoBarBeautyParamChanged {
    // 将用户对 UI 的更改同步至 FUManager
    [self syncBeautyParams];
}

- (void)demoBarSetBeautyDefultParams {
    _FUBeautyFilterPanel.delegate = self;
    _FUBeautyFilterPanel.skinDetect = [FUManager shareManager].skinDetectEnable;
    _FUBeautyFilterPanel.heavyBlur = [FUManager shareManager].blurShape;
    _FUBeautyFilterPanel.blurLevel = [FUManager shareManager].blurLevel;
    _FUBeautyFilterPanel.colorLevel = [FUManager shareManager].whiteLevel;
    _FUBeautyFilterPanel.redLevel = [FUManager shareManager].redLevel;
    _FUBeautyFilterPanel.eyeBrightLevel = [FUManager shareManager].eyelightingLevel;
    _FUBeautyFilterPanel.toothWhitenLevel = [FUManager shareManager].beautyToothLevel;
    _FUBeautyFilterPanel.enlargingLevel = [FUManager shareManager].enlargingLevel;
    _FUBeautyFilterPanel.thinningLevel = [FUManager shareManager].thinningLevel;
    _FUBeautyFilterPanel.chinLevel = [FUManager shareManager].jewLevel;
    _FUBeautyFilterPanel.foreheadLevel = [FUManager shareManager].foreheadLevel;
    _FUBeautyFilterPanel.noseLevel = [FUManager shareManager].noseLevel;
    _FUBeautyFilterPanel.mouthLevel = [FUManager shareManager].mouthLevel;
    _FUBeautyFilterPanel.filtersDataSource = [FUManager shareManager].filtersDataSource;
    _FUBeautyFilterPanel.beautyFiltersDataSource = [FUManager shareManager].beautyFiltersDataSource;
    _FUBeautyFilterPanel.filtersCHName = [FUManager shareManager].filtersCHName;
    _FUBeautyFilterPanel.selectedFilter = [FUManager shareManager].selectedFilter;
    _FUBeautyFilterPanel.selectedFilterLevel = [FUManager shareManager].selectedFilterLevel;
}

- (void)syncBeautyParams {
    [FUManager shareManager].skinDetectEnable = _FUBeautyFilterPanel.skinDetect;
    [FUManager shareManager].blurShape = _FUBeautyFilterPanel.heavyBlur;
    [FUManager shareManager].blurLevel = _FUBeautyFilterPanel.blurLevel;
    [FUManager shareManager].whiteLevel = _FUBeautyFilterPanel.colorLevel;
    [FUManager shareManager].redLevel = _FUBeautyFilterPanel.redLevel;
    [FUManager shareManager].eyelightingLevel = _FUBeautyFilterPanel.eyeBrightLevel;
    [FUManager shareManager].beautyToothLevel = _FUBeautyFilterPanel.toothWhitenLevel;
    [FUManager shareManager].enlargingLevel = _FUBeautyFilterPanel.enlargingLevel;
    [FUManager shareManager].thinningLevel = _FUBeautyFilterPanel.thinningLevel;
    [FUManager shareManager].jewLevel = _FUBeautyFilterPanel.chinLevel;
    [FUManager shareManager].foreheadLevel = _FUBeautyFilterPanel.foreheadLevel;
    [FUManager shareManager].noseLevel = _FUBeautyFilterPanel.noseLevel;
    [FUManager shareManager].mouthLevel = _FUBeautyFilterPanel.mouthLevel;
    [FUManager shareManager].selectedFilter = _FUBeautyFilterPanel.selectedFilter;
    [FUManager shareManager].selectedFilterLevel = _FUBeautyFilterPanel.selectedFilterLevel;
}

@end
