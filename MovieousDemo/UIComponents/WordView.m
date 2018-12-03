//
//  WordView.m
//  MovieousDemo
//
//  Created by Chris Wang on 2018/10/28.
//  Copyright © 2018 Movieous Team. All rights reserved.
//

#import "WordView.h"

@interface WordView ()

@property (strong, nonatomic) IBOutlet UIButton *subtitleButton;
@property (strong, nonatomic) IBOutlet UIButton *timeButton;
@property (strong, nonatomic) IBOutlet UIButton *titleButton;
@property (strong, nonatomic) IBOutlet UIView *titlePanel;
@property (strong, nonatomic) IBOutlet UIView *timePanel;
@property (strong, nonatomic) IBOutlet UIView *subtitlePanel;

@end

@implementation WordView

- (IBAction)titleButtonPressed:(id)sender {
    _titleButton.selected = YES;
    _titlePanel.hidden = NO;
    _timeButton.selected = NO;
    _timePanel.hidden = YES;
    _subtitleButton.selected = NO;
    _subtitlePanel.hidden = YES;
}

- (IBAction)timeButtonPressed:(id)sender {
    _titleButton.selected = NO;
    _titlePanel.hidden = YES;
    _timeButton.selected = YES;
    _timePanel.hidden = NO;
    _subtitleButton.selected = NO;
    _subtitlePanel.hidden = YES;
}

- (IBAction)subtitleButtonPressed:(id)sender {
    _titleButton.selected = NO;
    _titlePanel.hidden = YES;
    _timeButton.selected = NO;
    _timePanel.hidden = YES;
    _subtitleButton.selected = YES;
    _subtitlePanel.hidden = NO;
}

@end
