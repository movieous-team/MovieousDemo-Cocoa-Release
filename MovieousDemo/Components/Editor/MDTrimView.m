//
//  MDTrimView.m
//  MovieousDemo
//
//  Created by Chris Wang on 2018/10/29.
//  Copyright © 2018 Movieous Team. All rights reserved.
//

#import "MDTrimView.h"
#import "MDSharedCenter.h"

#define SNAPSHOT_COUNT 10
#define MIN_DURATION 3

@interface TrimCell : UICollectionViewCell

@property (strong, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation TrimCell

@end

@interface MDTrimViewController : UIViewController

@end

@implementation MDTrimViewController

- (void)viewWillAppear:(BOOL)animated {
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    self.navigationController.navigationController.interactivePopGestureRecognizer.enabled = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    self.navigationController.navigationController.interactivePopGestureRecognizer.enabled = NO;
}

@end

@interface MDTrimView ()
<
UICollectionViewDataSource,
UICollectionViewDelegate
>

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *leftDragviewPosition;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *rightDragviewPosition;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *seekerPosition;
@property (strong, nonatomic) IBOutlet UICollectionView *snapshotsView;
@property (strong, nonatomic) IBOutlet UIView *previewContainer;
@property (strong, nonatomic) IBOutlet UILabel *currentTimeLabel;
@property (strong, nonatomic) IBOutlet UIImageView *leftDragView;
@property (strong, nonatomic) IBOutlet UIImageView *rightDragView;
@property (strong, nonatomic) IBOutlet UIView *seekerView;
@property (strong, nonatomic) IBOutlet UIView *bottomContainer;
@property (strong, nonatomic) IBOutlet UISegmentedControl *speedSegmentControl;
@property (strong, nonatomic) IBOutlet UIView *imageDurationContainer;
@property (strong, nonatomic) IBOutlet UITextField *durationTextField;

@end

@implementation MDTrimView {
    NSArray<MSVImageGeneratorResult *> *_generatorResults;
    MSVEditor *_editor;
    NSTimeInterval _duration;
    BOOL _seeking;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    _editor = MDSharedCenter.sharedCenter.editor;
    _duration = _editor.draft.duration;
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
    if (_editor.draft.mainTrackClips.count > 0 && _editor.draft.mainTrackClips.firstObject.type == MSVClipTypeImage) {
        _speedSegmentControl.hidden = YES;
        _imageDurationContainer.hidden = NO;
        _durationTextField.text = [NSString stringWithFormat:@"%.1f", _editor.draft.duration];
    } else {
        _speedSegmentControl.hidden = NO;
        _imageDurationContainer.hidden = YES;
    }
    [self addObservers];
    [self syncUIWithDraft];
}

- (void)dealloc {
    [self removeObservers];
    [_editor.draft.imageGenerator.innerImageGenerator cancelAllCGImageGeneration];
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
    // 保证不会跳出有效时间范围
    if (_editor.draft.timeRange.duration > 0) {
        if (_editor.currentTime < _editor.draft.timeRange.startTime || _editor.currentTime > _editor.draft.timeRange.startTime + _editor.draft.timeRange.duration) {
            return;
        }
    } else {
        if (_editor.currentTime < 0 || _editor.currentTime > _duration) {
            return;
        }
    }
    _seekerPosition.constant = _snapshotsView.frame.size.width * _editor.currentTime / _duration;
}

- (void)syncUIWithDraft {
    _currentTimeLabel.text = [NSString stringWithFormat:@"已选取%.1f秒", _duration];
    if (_editor.draft.mainTrackClips.count > 0 && _editor.draft.mainTrackClips.firstObject.type == MSVClipTypeImage) {
        _durationTextField.text = [NSString stringWithFormat:@"%.1f", _duration];
    } else {
        if (_editor.draft.timeRange.duration > 0) {
            CGFloat leftDistance = _snapshotsView.frame.size.width * _editor.draft.timeRange.startTime / _duration;
            if (leftDistance > _snapshotsView.frame.size.width) {
                leftDistance = _snapshotsView.frame.size.width;
            } else if (leftDistance < 0) {
                leftDistance = 0;
            }
            _leftDragviewPosition.constant = leftDistance;
            CGFloat rightDistance = _snapshotsView.frame.size.width * (_duration - _editor.draft.timeRange.startTime - _editor.draft.timeRange.duration) / _duration;
            if (rightDistance > _snapshotsView.frame.size.width) {
                rightDistance = _snapshotsView.frame.size.width;
            } else if (rightDistance < 0) {
                rightDistance = 0;
            }
            _rightDragviewPosition.constant = rightDistance;
        }
        if (_editor.draft.mainTrackClips.count > 0) {
            MSVMainTrackClip *clip = _editor.draft.mainTrackClips[0];
            if (clip.speed <= 0.6) {
                _speedSegmentControl.selectedSegmentIndex = 0;
            } else if (clip.speed <= 0.8) {
                _speedSegmentControl.selectedSegmentIndex = 1;
            } else if (clip.speed <= 1.1) {
                _speedSegmentControl.selectedSegmentIndex = 2;
            } else if (clip.speed <= 1.6) {
                _speedSegmentControl.selectedSegmentIndex = 3;
            } else {
                _speedSegmentControl.selectedSegmentIndex = 4;
            }
        }
    }
}

- (IBAction)resetButtonPressed:(id)sender {
    _leftDragviewPosition.constant = 0;
    _rightDragviewPosition.constant = 0;
    if (_speedSegmentControl.hidden) {
        _durationTextField.text = @"3.0";
        [self applyNewDuration];
    } else {
        _speedSegmentControl.selectedSegmentIndex = 2;
        [self applyNewSpeed];
    }
}

- (IBAction)speedValueChanged:(UISegmentedControl *)sender {
    [self applyNewSpeed];
}

- (void)applyNewSpeed {
    float speed = 1;
    switch (_speedSegmentControl.selectedSegmentIndex) {
        case 0:
            speed = 0.5;
            break;
        case 1:
            speed = 2.0 / 3;
            break;
        case 2:
            speed = 1;
            break;
        case 3:
            speed = 1.5;
            break;
        case 4:
            speed = 2;
            break;
        default:
            break;
    }
    [_editor.draft beginChangeTransaction];
    for (MSVMainTrackClip *clip in _editor.draft.mainTrackClips) {
        clip.speed = speed;
    }
    NSError *error;
    if (![_editor.draft commitChangeWithError:&error]) {
        SHOW_ERROR_ALERT_FOR(self.window.rootViewController);
        return;
    }
    _duration = _editor.draft.duration;
    [self applyNewCut];
    [self refreshTimeLabel];
}

- (IBAction)leftDragviewPanned:(UIPanGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        _seekerView.hidden = YES;
        [_editor pause];
    } else if (sender.state == UIGestureRecognizerStateChanged) {
        CGFloat destPosition = _leftDragviewPosition.constant + [sender translationInView:_snapshotsView].x;
        CGFloat maxPosition = _snapshotsView.frame.size.width - _rightDragviewPosition.constant - _snapshotsView.frame.size.width * MIN_DURATION / _duration;
        if (maxPosition < 0) {
            maxPosition = 0;
        }
        if (destPosition >= maxPosition) {
            _leftDragviewPosition.constant = maxPosition;
        } else if (destPosition <= 0) {
            _leftDragviewPosition.constant = 0;
        } else {
            _leftDragviewPosition.constant = destPosition;
        }
        [sender setTranslation:CGPointZero inView:_snapshotsView];
        [self refreshTimeLabel];
        [_editor seekToTime:_duration *  _leftDragviewPosition.constant / _snapshotsView.frame.size.width accurate:YES];
    } else {
        _seekerView.hidden = NO;
        [self applyNewCut];
    }
}

- (IBAction)rightDragviewPanned:(UIPanGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        _seekerView.hidden = YES;
        [_editor pause];
    } else if (sender.state == UIGestureRecognizerStateChanged) {
        CGFloat destPosition = _rightDragviewPosition.constant - [sender translationInView:_snapshotsView].x;
        CGFloat maxPosition = _snapshotsView.frame.size.width - _leftDragviewPosition.constant - _snapshotsView.frame.size.width * MIN_DURATION / _duration;
        if (maxPosition < 0) {
            maxPosition = 0;
        }
        if (destPosition >= maxPosition) {
            _rightDragviewPosition.constant = maxPosition;
        } else if (destPosition <= 0) {
            _rightDragviewPosition.constant = 0;
        } else {
            _rightDragviewPosition.constant = destPosition;
        }
        [sender setTranslation:CGPointZero inView:_snapshotsView];
        [self refreshTimeLabel];
        [_editor seekToTime:_duration * (_snapshotsView.frame.size.width - _rightDragviewPosition.constant) / _snapshotsView.frame.size.width accurate:YES];
    } else {
        _seekerView.hidden = NO;
        [self applyNewCut];
    }
}

- (void)refreshTimeLabel {
    float selectedDuration = _duration * (_snapshotsView.frame.size.width - _rightDragviewPosition.constant - _leftDragviewPosition.constant) / _snapshotsView.frame.size.width;
    _currentTimeLabel.text = [NSString stringWithFormat:@"已选取%.1f秒", selectedDuration];
}

- (IBAction)seekViewPanned:(UIPanGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        _seeking = YES;
        [_editor pause];
    } else if (sender.state == UIGestureRecognizerStateChanged) {
        CGFloat destPosition = _seekerPosition.constant + [sender translationInView:_snapshotsView].x;
        CGFloat minPosition = _leftDragviewPosition.constant;
        CGFloat maxPosition = _snapshotsView.frame.size.width - _rightDragviewPosition.constant;
        if (destPosition <= minPosition) {
            _seekerPosition.constant = minPosition;
        } else if (destPosition >= maxPosition) {
            _seekerPosition.constant = maxPosition;
        } else {
            _seekerPosition.constant = destPosition;
        }
        [sender setTranslation:CGPointZero inView:_snapshotsView];
        [_editor seekToTime:_duration * _seekerPosition.constant / _snapshotsView.frame.size.width accurate:YES];
    } else {
        [_editor seekToTime:_duration * _seekerPosition.constant / _snapshotsView.frame.size.width accurate:YES];
        _seeking = NO;
    }
}

- (void)applyNewCut {
    NSTimeInterval startTime = _duration * _leftDragviewPosition.constant / _snapshotsView.frame.size.width;
    NSTimeInterval endTime = _duration - _duration * _rightDragviewPosition.constant / _snapshotsView.frame.size.width;
    _editor.draft.timeRange = (MovieousTimeRange){
        startTime,
        endTime - startTime,
    };
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _generatorResults.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    TrimCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"TrimCell" forIndexPath:indexPath];
    cell.imageView.image = _generatorResults[indexPath.row].image;
    return cell;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    // 使用 1.5 倍的预览条高度作为几个控件能够接收拖拽事件的区域
    CGPoint pointInContainer = [self convertPoint:point toView:_previewContainer];
    CGFloat WH = _previewContainer.frame.size.height * 1.5;
    CGRect leftRect = CGRectMake(_leftDragView.center.x - WH/2, _leftDragView.center.y - WH/2, WH, WH);
    CGRect rightRect = CGRectMake(_rightDragView.center.x - WH/2, _rightDragView.center.y - WH/2, WH, WH);
    CGPoint seekerCenter = [_bottomContainer convertPoint:_seekerView.center toView:_previewContainer];
    CGRect seekerRect = CGRectMake(seekerCenter.x - WH/2, seekerCenter.y - WH/2, WH, WH);
    if (CGRectContainsPoint(seekerRect, pointInContainer)) {
        return _seekerView;
    } else if (CGRectContainsPoint(leftRect, pointInContainer)) {
        return _leftDragView;
    } else if (CGRectContainsPoint(rightRect, pointInContainer)) {
        return _rightDragView;
    } else {
        return [super hitTest:point withEvent:event];
    }
}

- (IBAction)durationEditingEnd:(UITextField *)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:kEndEditingInBottomViewNotification object:self];
    [_editor.draft beginChangeTransaction];
    for (MSVMainTrackClip *clip in _editor.draft.mainTrackClips) {
        clip.durationAtMainTrack = sender.text.floatValue;
    }
    NSError *error;
    if (![_editor.draft commitChangeWithError:&error]) {
        SHOW_ERROR_ALERT_FOR(self.window.rootViewController);
        return;
    }
    _duration = _editor.draft.duration;
    [self applyNewCut];
    [self refreshTimeLabel];
}

- (IBAction)durationEditingBegin:(UITextField *)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:kBeginEditingInBottomViewNotification object:self];
}

- (IBAction)doneDurationEditingPressed:(UIButton *)sender {
    if (_durationTextField.isFirstResponder) {
        [_durationTextField resignFirstResponder];
        [[NSNotificationCenter defaultCenter] postNotificationName:kEndEditingInBottomViewNotification object:self];
        [self applyNewDuration];
    }
}

- (void)applyNewDuration {
    float newValue = _durationTextField.text.floatValue;
    // 不能小于一秒
    if (newValue > 1) {
        [_editor.draft beginChangeTransaction];
        for (MSVMainTrackClip *clip in _editor.draft.mainTrackClips) {
            clip.durationAtMainTrack = newValue;
        }
        NSError *error;
        if (![_editor.draft commitChangeWithError:&error]) {
            SHOW_ERROR_ALERT_FOR(self.window.rootViewController);
            return;
        }
        _duration = _editor.draft.duration;
        [self applyNewCut];
        [self refreshTimeLabel];
    } else {
        _durationTextField.text = [NSString stringWithFormat:@"%.1f", _editor.draft.duration];
    }
}

- (IBAction)viewTapped:(UITapGestureRecognizer *)sender {
    if (_durationTextField.isFirstResponder) {
        [_durationTextField resignFirstResponder];
        [[NSNotificationCenter defaultCenter] postNotificationName:kEndEditingInBottomViewNotification object:self];
        _durationTextField.text = [NSString stringWithFormat:@"%.1f", _editor.draft.duration];
    }
}

@end
