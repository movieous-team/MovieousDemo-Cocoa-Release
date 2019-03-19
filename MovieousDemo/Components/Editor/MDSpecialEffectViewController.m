//
//  MDSpecialEffectViewController.m
//  MovieousDemo
//
//  Created by Chris Wang on 2018/10/30.
//  Copyright © 2018 Movieous Team. All rights reserved.
//

#import "MDSpecialEffectViewController.h"

@interface MDSpecialEffectViewController ()

@property (strong, nonatomic) IBOutlet UIView *sceneEffectContainerView;
@property (strong, nonatomic) IBOutlet UIView *timeEffectContainerView;

@end

@implementation MDSpecialEffectViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)segValueChanged:(UISegmentedControl *)sender {
    if (sender.selectedSegmentIndex == 0) {
        _sceneEffectContainerView.hidden = NO;
        _timeEffectContainerView.hidden = YES;
    } else {
        _sceneEffectContainerView.hidden = YES;
        _timeEffectContainerView.hidden = NO;
    }
}

@end
