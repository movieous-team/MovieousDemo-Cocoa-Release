//
//  SpecialEffectViewController.m
//  MovieousDemo
//
//  Created by Chris Wang on 2018/10/30.
//  Copyright © 2018 Movieous Team. All rights reserved.
//

#import "SpecialEffectViewController.h"

@interface SpecialEffectViewController ()

@property (strong, nonatomic) IBOutlet UIView *filterEffectContainerView;
@property (strong, nonatomic) IBOutlet UIView *timeEffectContainerView;

@end

@implementation SpecialEffectViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)segValueChanged:(UISegmentedControl *)sender {
    if (sender.selectedSegmentIndex == 0) {
        _filterEffectContainerView.hidden = NO;
        _timeEffectContainerView.hidden = YES;
    } else {
        _filterEffectContainerView.hidden = YES;
        _timeEffectContainerView.hidden = NO;
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
