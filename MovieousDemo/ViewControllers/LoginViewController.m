//
//  ViewController.m
//  MovieousDemo
//
//  Created by Chris Wang on 2018/8/16.
//  Copyright © 2018 Movieous Team. All rights reserved.
//

#import "LoginViewController.h"

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.navigationController.navigationBarHidden = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)viewTapped:(id)sender {
    [self.view endEditing:YES];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

@end
