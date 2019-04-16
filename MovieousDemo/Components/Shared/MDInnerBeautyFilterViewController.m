//
//  MDInnerBeautyFilterViewController.m
//  MovieousDemo
//
//  Created by Chris Wang on 2019/4/9.
//  Copyright © 2019 Movieous Team. All rights reserved.
//

#import "MDInnerBeautyFilterViewController.h"
#import "MDSharedCenter.h"

@interface MDInnerBeautyFilterViewController ()

@end

@implementation MDInnerBeautyFilterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)beautyValueChanged:(UISlider *)sender {
    MDSharedCenter.sharedCenter.faceBeautyCaptureEffect.beautyLevel = sender.value;
}

- (IBAction)brightValueChanged:(UISlider *)sender {
    MDSharedCenter.sharedCenter.faceBeautyCaptureEffect.brightLevel = sender.value;
}

- (IBAction)toneValueChanged:(UISlider *)sender {
    MDSharedCenter.sharedCenter.faceBeautyCaptureEffect.toneLevel = sender.value;
}

- (IBAction)filterButtonPressed:(UIButton *)sender {
    sender.selected = !sender.selected;
    if (sender.selected) {
        NSMutableArray *effects = [NSMutableArray arrayWithArray:MDSharedCenter.sharedCenter.recorder.captureEffects];
        [effects addObject:MDSharedCenter.sharedCenter.LUTFilterCaptureEffect];
        MDSharedCenter.sharedCenter.recorder.captureEffects = effects;
    } else {
        NSMutableArray *effects = [NSMutableArray arrayWithArray:MDSharedCenter.sharedCenter.recorder.captureEffects];
        [effects removeObject:MDSharedCenter.sharedCenter.LUTFilterCaptureEffect];
        MDSharedCenter.sharedCenter.recorder.captureEffects = effects;
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
