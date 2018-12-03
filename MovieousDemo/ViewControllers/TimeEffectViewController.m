//
//  TimeEffectViewController.m
//  MovieousDemo
//
//  Created by Chris Wang on 2018/10/30.
//  Copyright © 2018 Movieous Team. All rights reserved.
//

#import "TimeEffectViewController.h"
#import "MSVEditor+Extentions.h"

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
    NSMutableArray *_snapshots;
    MSVEditor *_editor;
    NSTimeInterval _duration;
    BOOL _seeking;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    _editor = [MSVEditor sharedInstance];
    if (_editor.draft.timeRange.duration > 0) {
        _duration = _editor.draft.timeRange.duration;
    } else {
        _duration = 0;
        for (MSVMainTrackClip *clip in _editor.draft.mainTrackClips) {
            _duration += clip.durationAtMainTrack;
        }
    }
    _snapshots = [NSMutableArray array];
    __weak typeof(self) wSelf = self;
    [_editor.draft generateSnapshotsWithCount:SNAPSHOT_COUNT  withinTimeRange:YES completionHanler:^(NSTimeInterval timestamp, UIImage *snapshot, NSError *error) {
        __strong typeof(wSelf) strongSelf = wSelf;
        if (!error) {
            [strongSelf->_snapshots addObject:snapshot];
            if (strongSelf->_snapshots.count == SNAPSHOT_COUNT) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [strongSelf.snapshotsView reloadData];
                });
            }
        }
    }];
    [self addObservers];
    [self syncUIWithEffect];
}

- (void)syncUIWithEffect {
    for (id obj in _editor.draft.effects) {
        if ([obj isKindOfClass:MSVSpeedEffect.class]) {
            MSVSpeedEffect *effect = (MSVSpeedEffect *)obj;
            _effectStartView.hidden = NO;
            _effectStartPosition.constant = _snapshotsView.frame.size.width * effect.timeRangeAtMainTrack.startTime / _duration;
            return;
        } else if ([obj isKindOfClass:MSVRepeatEffect.class]) {
            MSVRepeatEffect *effect = (MSVRepeatEffect *)obj;
            _effectStartView.backgroundColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:1];
            _effectStartView.hidden = NO;
            _effectStartPosition.constant = _snapshotsView.frame.size.width * effect.timeRangeAtMainTrack.startTime / _duration;
            return;
        }
    }
}

- (void)dealloc {
    [self removeObservers];
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
    _seekerPosition.constant = _snapshotsView.frame.size.width * ([_editor.draft removeEffectFromTime:_editor.currentTime] - _editor.draft.timeRange.startTime) / _duration;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _snapshots.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    TimeEffectCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"TimeEffectCell" forIndexPath:indexPath];
    cell.imageView.image = _snapshots[indexPath.row];
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
        [_editor seekToTime:[_editor.draft applyEffectToTime:_editor.draft.timeRange.startTime + _duration * _seekerPosition.constant / _snapshotsView.frame.size.width] completionHandler:nil];
    } else {
        __weak typeof(self) wSelf = self;
        [_editor seekToTime:[_editor.draft applyEffectToTime:_editor.draft.timeRange.startTime +  _duration * _seekerPosition.constant / _snapshotsView.frame.size.width] completionHandler:^(BOOL finished) {
            __strong typeof(wSelf) strongSelf = wSelf;
            strongSelf->_seeking = NO;
        }];
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
        [_editor seekToTime:[_editor.draft applyEffectToTime:_editor.draft.timeRange.startTime + _duration * _effectStartPosition.constant / _snapshotsView.frame.size.width] completionHandler:nil];
    } else {
        [_editor.draft beginChangeTransaction];
        _editor.draft.timeRange = [_editor.draft removeEffectFromTimeRange:_editor.draft.timeRange];
        for (id effect in _editor.draft.effects) {
            if ([effect isKindOfClass:MSVRepeatEffect.class]) {
                NSTimeInterval effectStartTime = _duration * _effectStartPosition.constant / _snapshotsView.frame.size.width;
                ((MSVRepeatEffect *)effect).timeRangeAtMainTrack = (MovieousTimeRange) {
                    effectStartTime,
                    1,
                };
                break;
            } else if ([effect isKindOfClass:MSVSpeedEffect.class]) {
                NSTimeInterval effectStartTime = _duration * _effectStartPosition.constant / _snapshotsView.frame.size.width;
                ((MSVSpeedEffect *)effect).timeRangeAtMainTrack = (MovieousTimeRange) {
                    effectStartTime,
                    1,
                };
                break;
            }
        }
        _editor.draft.timeRange = [_editor.draft applyEffectToTimeRange:_editor.draft.timeRange];
        [_editor.draft commitChangeWithError:nil];
        _seekerView.hidden = NO;
        [_editor play];
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
    [_editor.draft beginChangeTransaction];
    _editor.draft.timeRange = [_editor.draft removeEffectFromTimeRange:_editor.draft.timeRange];
    _effectStartView.hidden = YES;
    NSMutableArray *effects = [NSMutableArray array];
    for (id obj in _editor.draft.effects) {
        if (![obj isKindOfClass:MSVRepeatEffect.class] && ![obj isKindOfClass:MSVSpeedEffect.class]) {
            [effects addObject:obj];
        }
    }
    NSError *error;
    [_editor.draft updateEffects:effects error:&error];
    if (error) {
        SHOW_ERROR_ALERT_FOR(self.window.rootViewController);
        return;
    }
    if (_editor.draft.mainTrackClips.count > 0 && _editor.draft.mainTrackClips[0].reverse == YES) {
        NSMutableArray *clips = [NSMutableArray array];
        for (MSVMainTrackClip *clip in _editor.draft.mainTrackClips) {
            [clip setReverse:NO progressHandler:nil completionHandler:nil];
            [clips insertObject:clip atIndex:0];
        }
        [_editor.draft updateMainTrackClips:clips error:&error];
        if (error) {
            SHOW_ERROR_ALERT_FOR(self.window.rootViewController);
            return;
        }
    }
    [_editor.draft commitChangeWithError:&error];
    if (error) {
        SHOW_ERROR_ALERT_FOR(self.window.rootViewController);
        return;
    }
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
    _editor.draft.timeRange = [_editor.draft removeEffectFromTimeRange:_editor.draft.timeRange];
    NSMutableArray *effects = [NSMutableArray array];
    for (id obj in _editor.draft.effects) {
        if (![obj isKindOfClass:MSVRepeatEffect.class] && ![obj isKindOfClass:MSVSpeedEffect.class]) {
            [effects addObject:obj];
        }
    }
    NSTimeInterval effectStartTime = _duration * _effectStartPosition.constant / _snapshotsView.frame.size.width;
    MSVRepeatEffect *repeatEffect = [MSVRepeatEffect new];
    repeatEffect.timeRangeAtMainTrack = (MovieousTimeRange) {
        effectStartTime,
        1,
    };
    repeatEffect.count = 3;
    [effects addObject:repeatEffect];
    NSError *error;
    [_editor.draft updateEffects:effects error:&error];
    if (error) {
        NSLog(@"error:%@", error.localizedDescription);
    }
    _editor.draft.timeRange = [_editor.draft applyEffectToTimeRange:_editor.draft.timeRange];
    [_editor.draft commitChangeWithError:nil];
}

- (IBAction)reverseButtonPressed:(UIButton *)sender {
    if (_editor.draft.mainTrackClips.count > 0 && _editor.draft.mainTrackClips[0].reverse == YES) {
        return;
    }
    [_editor pause];
    UIProgressView *progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    [self addSubview:progressView];
    __weak typeof(self) wSelf = self;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
        __strong typeof(wSelf) strongSelf = wSelf;
        [strongSelf->_editor.draft beginChangeTransaction];
        int clipCount = (int)strongSelf->_editor.draft.mainTrackClips.count;
        NSMutableArray *mainTrackClips = [NSMutableArray array];
        __block NSError *error;
        for (int i = clipCount - 1; i >= 0; i-- ) {
            MSVMainTrackClip *clip = strongSelf->_editor.draft.mainTrackClips[i];
            dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
            [clip setReverse:YES progressHandler:^(float progress) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [progressView setProgress:(i + progress) / clipCount animated:YES];
                });
            } completionHandler:^(NSError *reverseError) {
                error = reverseError;
                if (!error) {
                    [mainTrackClips addObject:strongSelf->_editor.draft.mainTrackClips[i]];
                } else {
                    SHOW_ERROR_ALERT_FOR(strongSelf.window.rootViewController);
                }
                dispatch_semaphore_signal(semaphore);
            }];
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            if (error) {
                break;
            }
        }
        if (error) {
            SHOW_ERROR_ALERT_FOR(strongSelf.window.rootViewController);
            return;
        }
        [strongSelf->_editor.draft updateMainTrackClips:mainTrackClips error:&error];
        if (error) {
            SHOW_ERROR_ALERT_FOR(strongSelf.window.rootViewController);
            return;
        }
        [strongSelf->_editor.draft commitChangeWithError:&error];
        if (error) {
            SHOW_ERROR_ALERT_FOR(strongSelf.window.rootViewController);
            return;
        }
        [strongSelf->_editor play];
    });
}

- (IBAction)slowMotionButtonPressed:(id)sender {
    _effectStartView.backgroundColor = [UIColor colorWithRed:0 green:1 blue:0 alpha:1];
    _effectStartPosition.constant = _snapshotsView.frame.size.width / 2;
    _effectStartView.hidden = NO;
    [self refreshMotionEffect];
}

- (void)refreshMotionEffect {
    [_editor.draft beginChangeTransaction];
    _editor.draft.timeRange = [_editor.draft removeEffectFromTimeRange:_editor.draft.timeRange];
    NSMutableArray *effects = [NSMutableArray array];
    for (id obj in _editor.draft.effects) {
        if (![obj isKindOfClass:MSVRepeatEffect.class] && ![obj isKindOfClass:MSVSpeedEffect.class]) {
            [effects addObject:obj];
        }
    }
    NSTimeInterval effectStartTime = _duration * _effectStartPosition.constant / _snapshotsView.frame.size.width;
    MSVSpeedEffect *speedEffect = [MSVSpeedEffect new];
    speedEffect.timeRangeAtMainTrack = (MovieousTimeRange) {
        effectStartTime,
        1,
    };
    speedEffect.speed = 0.5;
    [effects addObject:speedEffect];
    NSError *error;
    [_editor.draft updateEffects:effects error:&error];
    if (error) {
        NSLog(@"error:%@", error.localizedDescription);
    }
    _editor.draft.timeRange = [_editor.draft applyEffectToTimeRange:_editor.draft.timeRange];
    [_editor.draft commitChangeWithError:nil];
}

@end

@interface TimeEffectViewController ()

@end

@implementation TimeEffectViewController

- (void)viewWillAppear:(BOOL)animated {
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    self.navigationController.navigationController.interactivePopGestureRecognizer.enabled = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    self.navigationController.navigationController.interactivePopGestureRecognizer.enabled = YES;
}

@end
