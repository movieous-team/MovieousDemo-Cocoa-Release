//
//  MDTitleViewController.m
//  MovieousDemo
//
//  Created by Chris Wang on 2019/3/16.
//  Copyright © 2019 Movieous Team. All rights reserved.
//

#import "MDTitleViewController.h"

@interface MDTitleViewController ()

@end

@implementation MDTitleViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)titleAButtonPressed:(UIButton *)sender {
    SHOW_ALERT(@"提示", @"功能暂未开放，敬请期待", @"好的呢");
}

- (IBAction)titleBButtonPressed:(UIButton *)sender {
    SHOW_ALERT(@"提示", @"功能暂未开放，敬请期待", @"好的呢");
}

@end
