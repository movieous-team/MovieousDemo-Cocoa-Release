//
//  EditorPanel.m
//  MovieousDemo
//
//  Created by Chris Wang on 2018/10/27.
//  Copyright © 2018 Movieous Team. All rights reserved.
//

#import "EditorPanel.h"

@interface EditorPanel ()

@property (strong, nonatomic) IBOutlet UIButton *splitButton;
@property (strong, nonatomic) IBOutlet UIView *splitPanel;
@property (strong, nonatomic) IBOutlet UIButton *wordButton;
@property (strong, nonatomic) IBOutlet UIView *wordPanel;
@property (strong, nonatomic) IBOutlet UIButton *pasterButton;
@property (strong, nonatomic) IBOutlet UIView *pasterPanel;
@property (strong, nonatomic) IBOutlet UIButton *musicButton;
@property (strong, nonatomic) IBOutlet UIView *musicPanel;

@end

@implementation EditorPanel

- (IBAction)splitButtonPressed:(UIButton *)sender {
    _splitButton.selected = YES;
    _splitPanel.hidden = NO;
    _wordButton.selected = NO;
    _wordPanel.hidden = YES;
    _pasterButton.selected = NO;
    _pasterPanel.hidden = YES;
    _musicButton.selected = NO;
    _musicPanel.hidden = YES;
}

- (IBAction)wordButtonPressed:(UIButton *)sender {
    _splitButton.selected = NO;
    _splitPanel.hidden = YES;
    _wordButton.selected = YES;
    _wordPanel.hidden = NO;
    _pasterButton.selected = NO;
    _pasterPanel.hidden = YES;
    _musicButton.selected = NO;
    _musicPanel.hidden = YES;
}

- (IBAction)pasterButtonPressed:(UIButton *)sender {
    _splitButton.selected = NO;
    _splitPanel.hidden = YES;
    _wordButton.selected = NO;
    _wordPanel.hidden = YES;
    _pasterButton.selected = YES;
    _pasterPanel.hidden = NO;
    _musicButton.selected = NO;
    _musicPanel.hidden = YES;
}

- (IBAction)musicButtonPressed:(UIButton *)sender {
    _splitButton.selected = NO;
    _splitPanel.hidden = YES;
    _wordButton.selected = NO;
    _wordPanel.hidden = YES;
    _pasterButton.selected = NO;
    _pasterPanel.hidden = YES;
    _musicButton.selected = YES;
    _musicPanel.hidden = NO;
}

@end
