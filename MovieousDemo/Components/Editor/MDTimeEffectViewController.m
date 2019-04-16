//
//  MDTimeEffectViewController.m
//  MovieousDemo
//
//  Created by Chris Wang on 2018/10/30.
//  Copyright © 2018 Movieous Team. All rights reserved.
//

#import "MDTimeEffectViewController.h"
#import "MDSharedCenter.h"
#import <SVProgressHUD/SVProgressHUD.h>

#define SNAPSHOT_COUNT 10

@interface TimeEffectCell : UICollectionViewCell

@property (strong, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation TimeEffectCell

@end

@interface TimeEffectView : UIView
<
UICollectionViewDataSource,
UICollectionViewDelegate
>
@property (strong, nonatomic) IBOutlet UICollectionView *snapshotsView;
@property (strong, nonatomic) IBOutlet UIImageView *effectStartView;
@property (strong, nonatomic) IBOutlet UIView *seekerView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *effectStartPosition;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *seekerPosition;

@end

@implementation TimeEffectView {
    NSArray<MSVImageGeneratorResult *> *_generatorResults;
    MSVEditor *_editor;
    NSTimeInterval _duration;
    BOOL _seeking;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    _editor = MDSharedCenter.sharedCenter.editor;
    if (_editor.draft.timeRange.duration > 0) {
        _duration = _editor.draft.timeRange.duration;
    } else {
        _duration = 0;
        for (MSVMainTrackClip *clip in _editor.draft.mainTrackClips) {
            _duration += clip.durationAtMainTrack;
        }
    }
    MovieousWeakSelf
    [_editor.draft.imageGenerator generateImagesWithCompletionHandler:^(NSArray<MSVImageGeneratorResult *> * _Nullable results, AVAssetImageGeneratorResult result, NSError * _Nullable error) {
        MovieousStrongSelf
        if (result == AVAssetImageGeneratorSucceeded) {
            strongSelf->_generatorResults = results;
            dispatch_async(dispatch_get_main_queue(), ^{
                [strongSelf.snapshotsView reloadData];
            });
        } else if (result == AVAssetImageGeneratorFailed) {
            SHOW_ERROR_ALERT_FOR(UIApplication.sharedApplication.keyWindow.rootViewController);
        }
    }];
    [self addObservers];
    [self syncUIWithEffect];
}

- (void)dealloc {
    [self removeObservers];
    [_editor.draft.imageGenerator.innerImageGenerator cancelAllCGImageGeneration];
}

- (void)syncUIWithEffect {
    if (_editor.draft.timeEffects.count > 0) {
        id obj = _editor.draft.timeEffects[0];
        if ([obj isKindOfClass:MSVSpeedEditorEffect.class]) {
            MSVSpeedEditorEffect *effect = (MSVSpeedEditorEffect *)obj;
            _effectStartView.hidden = NO;
            _effectStartPosition.constant = _snapshotsView.frame.size.width * effect.timeRangeAtMainTrack.startTime / _duration;
        } else if ([obj isKindOfClass:MSVRepeatEditorEffect.class]) {
            MSVRepeatEditorEffect *effect = (MSVRepeatEditorEffect *)obj;
            _effectStartView.backgroundColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:1];
            _effectStartView.hidden = NO;
            _effectStartPosition.constant = _snapshotsView.frame.size.width * effect.timeRangeAtMainTrack.startTime / _duration;
        }
    }
}

- (void)addObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentTimeUpdated:) name:kMSVEditorCurrentTimeUpdatedNotification object:_editor];
}

- (void)removeObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)currentTimeUpdated:(NSNotification *)notification {
    if (_seeking) {
        return;
    }
    _seekerPosition.constant = _snapshotsView.frame.size.width * ([_editor.draft getOriginalTimeFromEffectedTime:_editor.currentTime] - _editor.draft.timeRange.startTime) / _duration;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _generatorResults.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    TimeEffectCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"TimeEffectCell" forIndexPath:indexPath];
    cell.imageView.image = _generatorResults[indexPath.row].image;
    return cell;
}

- (IBAction)seekViewPanned:(UIPanGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        _seeking = YES;
        [_editor pause];
    } else if (sender.state == UIGestureRecognizerStateChanged) {
        CGFloat destPosition = _seekerPosition.constant + [sender translationInView:_snapshotsView].x;
        if (destPosition <= 0) {
            _seekerPosition.constant = 0;
        } else if (destPosition >= _snapshotsView.frame.size.width) {
            _seekerPosition.constant = _snapshotsView.frame.size.width;
        } else {
            _seekerPosition.constant = destPosition;
        }
        [sender setTranslation:CGPointZero inView:_snapshotsView];
        [_editor seekToTime:[_editor.draft getEffectedTimeFromOriginalTime:_editor.draft.timeRange.startTime + _duration * _seekerPosition.constant / _snapshotsView.frame.size.width] accurate:YES];
    } else {
        [_editor seekToTime:[_editor.draft getEffectedTimeFromOriginalTime:_editor.draft.timeRange.startTime +  _duration * _seekerPosition.constant / _snapshotsView.frame.size.width] accurate:YES];
        _seeking = NO;
    }
}

- (IBAction)effectStartViewPanned:(UIPanGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        _seekerView.hidden = YES;
        [_editor pause];
    } else if (sender.state == UIGestureRecognizerStateChanged) {
        CGFloat destPosition = _effectStartPosition.constant + [sender translationInView:_snapshotsView].x;
        if (destPosition <= 0) {
            _effectStartPosition.constant = 0;
        } else if (destPosition >= _snapshotsView.frame.size.width) {
            _effectStartPosition.constant = _snapshotsView.frame.size.width;
        } else {
            _effectStartPosition.constant = destPosition;
        }
        [sender setTranslation:CGPointZero inView:_snapshotsView];
        [_editor seekToTime:[_editor.draft getEffectedTimeFromOriginalTime:_editor.draft.timeRange.startTime + _duration * _effectStartPosition.constant / _snapshotsView.frame.size.width] accurate:YES];
    } else {
        if (_editor.draft.timeEffects.count > 0) {
            [_editor.draft beginChangeTransaction];
            _editor.draft.timeRange = [_editor.draft getOriginalTimeRangeFromEffectedTimeRange:_editor.draft.timeRange];
            id effect = _editor.draft.timeEffects[0];
            if ([effect isKindOfClass:MSVRepeatEditorEffect.class]) {
                NSTimeInterval effectStartTime = _duration * _effectStartPosition.constant / _snapshotsView.frame.size.width;
                ((MSVRepeatEditorEffect *)effect).timeRangeAtMainTrack = (MovieousTimeRange) {
                    effectStartTime,
                    1,
                };
            } else if ([effect isKindOfClass:MSVSpeedEditorEffect.class]) {
                NSTimeInterval effectStartTime = _duration * _effectStartPosition.constant / _snapshotsView.frame.size.width;
                ((MSVSpeedEditorEffect *)effect).timeRangeAtMainTrack = (MovieousTimeRange) {
                    effectStartTime,
                    1,
                };
            }
            _editor.draft.timeRange = [_editor.draft getEffectedRangeTimeFromOriginalTimeRange:_editor.draft.timeRange];
            [_editor.draft commitChangeWithError:nil];
            _seekerView.hidden = NO;
            [_editor play];
        }
    }
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    // 使用 1.5 倍的预览条高度作为几个控件能够接收拖拽事件的区域
    CGFloat WH = _snapshotsView.frame.size.height * 1.5;
    CGRect effectStartRect = CGRectMake(_effectStartView.center.x - WH/2, _effectStartView.center.y - WH/2, WH, WH);
    CGRect seekerRect = CGRectMake(_seekerView.center.x - WH/2, _seekerView.center.y - WH/2, WH, WH);
    if (CGRectContainsPoint(effectStartRect, point) && !_effectStartView.hidden) {
        return _effectStartView;
    } else if (CGRectContainsPoint(seekerRect, point)) {
        return _seekerView;
    } else {
        return [super hitTest:point withEvent:event];
    }
}

- (IBAction)noEffectButtonPressed:(UIButton *)sender {
    _effectStartView.hidden = YES;
    NSError *error;
    if (_editor.draft.timeEffects.count) {
        [_editor.draft beginChangeTransaction];
        _editor.draft.timeRange = [_editor.draft getOriginalTimeRangeFromEffectedTimeRange:_editor.draft.timeRange];
        [_editor.draft updateTimeEffects:nil error:&error];
        if (error) {
            SHOW_ERROR_ALERT_FOR(self.window.rootViewController);
            return;
        }
        [_editor.draft commitChangeWithError:&error];
        if (error) {
            SHOW_ERROR_ALERT_FOR(self.window.rootViewController);
            return;
        }
    }
    _editor.draft.reverseVideo = NO;
    [_editor play];
}

- (IBAction)repeatButtonPressed:(UIButton *)sender {
    _effectStartView.backgroundColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:1];
    _effectStartPosition.constant = _snapshotsView.frame.size.width / 2;
    _effectStartView.hidden = NO;
    [self refreshRepeatEffect];
    [_editor play];
}

- (void)refreshRepeatEffect {
    [_editor.draft beginChangeTransaction];
    _editor.draft.timeRange = [_editor.draft getOriginalTimeRangeFromEffectedTimeRange:_editor.draft.timeRange];
    NSTimeInterval effectStartTime = _duration * _effectStartPosition.constant / _snapshotsView.frame.size.width;
    MSVRepeatEditorEffect *repeatEffect = [MSVRepeatEditorEffect new];
    repeatEffect.timeRangeAtMainTrack = (MovieousTimeRange) {
        effectStartTime,
        1,
    };
    repeatEffect.count = 3;
    NSError *error;
    [_editor.draft updateTimeEffects:@[repeatEffect] error:&error];
    if (error) {
        SHOW_ERROR_ALERT_FOR(UIApplication.sharedApplication.keyWindow.rootViewController);
    }
    _editor.draft.reverseVideo = NO;
    _editor.draft.timeRange = [_editor.draft getEffectedRangeTimeFromOriginalTimeRange:_editor.draft.timeRange];
    [_editor.draft commitChangeWithError:nil];
}

- (IBAction)reverseButtonPressed:(UIButton *)sender {
    _effectStartView.hidden = YES;
    _editor.draft.reverseVideo = YES;
    if (_editor.draft.timeEffects.count > 0) {
        NSError *error;
        [_editor.draft updateTimeEffects:nil error:&error];
        if (error) {
            SHOW_ERROR_ALERT_FOR(UIApplication.sharedApplication.keyWindow.rootViewController);
        }
    }
}

- (IBAction)slowMotionButtonPressed:(id)sender {
    _effectStartView.backgroundColor = [UIColor colorWithRed:0 green:1 blue:0 alpha:1];
    _effectStartPosition.constant = _snapshotsView.frame.size.width / 2;
    _effectStartView.hidden = NO;
    [self refreshMotionEffect];
}

- (void)refreshMotionEffect {
    [_editor.draft beginChangeTransaction];
    _editor.draft.timeRange = [_editor.draft getOriginalTimeRangeFromEffectedTimeRange:_editor.draft.timeRange];
    NSTimeInterval effectStartTime = _duration * _effectStartPosition.constant / _snapshotsView.frame.size.width;
    MSVSpeedEditorEffect *speedEffect = [MSVSpeedEditorEffect new];
    speedEffect.timeRangeAtMainTrack = (MovieousTimeRange) {
        effectStartTime,
        1,
    };
    speedEffect.speed = 0.5;
    NSError *error;
    [_editor.draft updateTimeEffects:@[speedEffect] error:&error];
    if (error) {
        NSLog(@"error:%@", error.localizedDescription);
    }
    _editor.draft.reverseVideo = NO;
    _editor.draft.timeRange = [_editor.draft getEffectedRangeTimeFromOriginalTimeRange:_editor.draft.timeRange];
    [_editor.draft commitChangeWithError:nil];
}

@end

@interface MDTimeEffectViewController ()

@end

@implementation MDTimeEffectViewController

- (void)viewWillAppear:(BOOL)animated {
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    self.navigationController.navigationController.interactivePopGestureRecognizer.enabled = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    self.navigationController.navigationController.interactivePopGestureRecognizer.enabled = YES;
}

@end
