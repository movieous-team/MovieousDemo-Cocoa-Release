//
//  VolumeView.m
//  MovieousDemo
//
//  Created by Chris Wang on 2018/10/27.
//  Copyright © 2018 Movieous Team. All rights reserved.
//

#import "VolumeViewController.h"
#import "MSVEditor+Extentions.h"
#include <mach/mach_time.h>

@interface VolumeViewController ()

@property (strong, nonatomic) IBOutlet UILabel *musicLabel;
@property (strong, nonatomic) IBOutlet UISlider *musicSlider;
@property (strong, nonatomic) IBOutlet UISlider *originalSlider;
@property (strong, nonatomic) IBOutlet UILabel *originalLabel;

@end

@implementation VolumeViewController {
    MSVEditor *_editor;
}

- (void)viewDidLoad {
    _editor = MSVEditor.sharedInstance;
}

- (void)viewWillAppear:(BOOL)animated {
    if (_editor.draft.mainTrackClips.count == 0) {
        _originalLabel.enabled = NO;
        _originalSlider.enabled = NO;
    } else {
        _originalLabel.enabled = YES;
        _originalSlider.enabled = YES;
        _originalSlider.value = _editor.draft.mainTrackClips[0].volume;
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

// 原声静音
- (IBAction)muteButtonPressed:(UIButton *)sender {
    _originalSlider.value = 0;
    [self originalVolumeChanged:_originalSlider];
}

@end
