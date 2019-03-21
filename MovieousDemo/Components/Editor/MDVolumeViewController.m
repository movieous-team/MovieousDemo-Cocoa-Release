//
//  VolumeView.m
//  MovieousDemo
//
//  Created by Chris Wang on 2018/10/27.
//  Copyright © 2018 Movieous Team. All rights reserved.
//

#import "MDVolumeViewController.h"
#import "MDSharedCenter.h"
#include <mach/mach_time.h>

@interface MDVolumeViewController ()

@property (strong, nonatomic) IBOutlet UILabel *musicLabel;
@property (strong, nonatomic) IBOutlet UISlider *musicSlider;
@property (strong, nonatomic) IBOutlet UISlider *originalSlider;
@property (strong, nonatomic) IBOutlet UILabel *originalLabel;
@property (strong, nonatomic) IBOutlet UIButton *originalMuteButton;
@property (strong, nonatomic) IBOutlet UISlider *mixSlider;
@property (strong, nonatomic) IBOutlet UILabel *mixLabel;
@property (strong, nonatomic) IBOutlet UIButton *mixMuteButton;

@end

@implementation MDVolumeViewController {
    MSVEditor *_editor;
}

- (void)viewDidLoad {
    _editor = MDSharedCenter.sharedCenter.editor;
}

- (void)viewWillAppear:(BOOL)animated {
    if (_editor.draft.mainTrackClips.count == 0) {
        _originalLabel.enabled = NO;
        _originalSlider.enabled = NO;
        _originalMuteButton.enabled = NO;
    } else {
        _originalLabel.enabled = YES;
        _originalSlider.enabled = YES;
        _originalMuteButton.enabled = YES;
        _originalSlider.value = _editor.draft.mainTrackClips[0].volume;
    }
    if (_editor.draft.videoClips.count == 0) {
        _mixLabel.enabled = NO;
        _mixSlider.enabled = NO;
        _mixMuteButton.enabled = NO;
    } else {
        _mixLabel.enabled = YES;
        _mixSlider.enabled = YES;
        _mixMuteButton.enabled = YES;
        _mixSlider.value = _editor.draft.videoClips[0].volume;
    }
    if (_editor.draft.audioClips.count == 0) {
        _musicLabel.enabled = NO;
        _musicSlider.enabled = NO;
    } else {
        _musicLabel.enabled = YES;
        _musicSlider.enabled = YES;
        _musicSlider.value = _editor.draft.audioClips[0].volume;
    }
}

// 原声音量变化
- (IBAction)originalVolumeChanged:(UISlider *)sender {
    [_editor.draft beginVolumeChangeTransaction];
    for (MSVMainTrackClip *clip in _editor.draft.mainTrackClips) {
        clip.volume = sender.value;
    }
    NSError *error;
    if (![_editor.draft commitVolumeChangeWithError:&error]) {
        SHOW_ERROR_ALERT;
        return;
    }
}

- (IBAction)mixVolumeChanged:(UISlider *)sender {
    [_editor.draft beginVolumeChangeTransaction];
    for (MSVVideoClip *clip in _editor.draft.videoClips) {
        clip.volume = sender.value;
    }
    NSError *error;
    if (![_editor.draft commitVolumeChangeWithError:&error]) {
        SHOW_ERROR_ALERT;
        return;
    }
}

// 背景音乐音量变化
- (IBAction)backgroundVolumeChanged:(UISlider *)sender {
    [_editor.draft beginVolumeChangeTransaction];
    for (MSVAudioClip *clip in _editor.draft.audioClips) {
        clip.volume = sender.value;
    }
    NSError *error;
    if (![_editor.draft commitVolumeChangeWithError:&error]) {
        SHOW_ERROR_ALERT;
        return;
    }
}
- (IBAction)mixMuteButtonPressed:(UIButton *)sender {
    _mixSlider.value = 0;
    [self mixVolumeChanged:_mixSlider];
}

// 原声静音
- (IBAction)originalMuteButtonPressed:(UIButton *)sender {
    _originalSlider.value = 0;
    [self originalVolumeChanged:_originalSlider];
}

@end
