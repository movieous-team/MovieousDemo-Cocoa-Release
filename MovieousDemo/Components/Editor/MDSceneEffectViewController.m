//
//  MDSceneEffectViewController.m
//  MovieousDemo
//
//  Created by Chris Wang on 2018/10/30.
//  Copyright © 2018 Movieous Team. All rights reserved.
//

#import "MDSceneEffectViewController.h"
#import "MDSharedCenter.h"
#import "MDFilter.h"
#import "MDGlobalSettings.h"

#define SNAPSHOT_COUNT 10

@interface SceneEffectLine : NSObject

@property (nonatomic, assign) float start;
@property (nonatomic, assign) float length;
@property (nonatomic, strong) UIColor *color;

@end

@implementation SceneEffectLine

@end

@interface SceneEffectCoverView : UIView

@property (nonatomic, strong) NSMutableArray<SceneEffectLine *> *lines;

@end

@implementation SceneEffectCoverView

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        _lines = [NSMutableArray array];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    for (SceneEffectLine *line in _lines) {
        [line.color setStroke];
        CGSize size = rect.size;
        CGContextSetLineWidth(ctx, size.height);
        UIBezierPath *path = [UIBezierPath bezierPath];
        [path moveToPoint:CGPointMake(size.width * line.start, size.height / 2)];
        [path addLineToPoint:CGPointMake(size.width * (line.start + line.length), size.height / 2)];
        CGContextAddPath(ctx, path.CGPath);
        CGContextSetBlendMode(ctx, kCGBlendModeCopy);
        CGContextStrokePath(ctx);
    }
}

@end

@interface SceneEffectSnapshotCell : UICollectionViewCell

@property (strong, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation SceneEffectSnapshotCell

@end

@interface SceneEffectCell : UICollectionViewCell

@property (strong, nonatomic) IBOutlet UIButton *effectButton;
@property (strong, nonatomic) IBOutlet UILabel *effectNameLabel;

@end

@implementation SceneEffectCell

@end

@interface MDSceneEffectViewController ()

@end

@implementation MDSceneEffectViewController

- (void)viewWillAppear:(BOOL)animated {
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    self.navigationController.navigationController.interactivePopGestureRecognizer.enabled = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    self.navigationController.navigationController.interactivePopGestureRecognizer.enabled = YES;
}

@end

@interface SceneEffectView : UIView
<
UICollectionViewDelegate,
UICollectionViewDataSource
>
@property (strong, nonatomic) IBOutlet UICollectionView *snapshotsView;
@property (strong, nonatomic) IBOutlet UIView *seekerView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *seekerPosition;
@property (strong, nonatomic) IBOutlet SceneEffectCoverView *coverView;
@property (strong, nonatomic) IBOutlet UILabel *tipsLabel;

@end

@implementation SceneEffectView {
    NSArray<MSVImageGeneratorResult *> *_generatorResults;
    MSVEditor *_editor;
    NSTimeInterval _duration;
    BOOL _seeking;
    NSTimeInterval _currentEffectStartTime;
    SceneEffectLine *_currentLine;
    BOOL _playing;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    _editor = MDSharedCenter.sharedCenter.editor;
    _currentEffectStartTime = -1;
    if (_editor.draft.timeRange.duration > 0) {
        _duration = _editor.draft.timeRange.duration;
    } else {
        _duration = _editor.draft.duration;
    }
    if (MDGlobalSettings.sharedInstance.vendorType != VendorTypeFaceunity && MDGlobalSettings.sharedInstance.vendorType != VendorTypeTuSDK) {
        _tipsLabel.text = @"当前只有 Faceunity 和 TuSDK 供应商支持滤镜特效，请在设置界面选择对应供应商";
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
    [self syncUIWithEffect];
    [self addObservers];
}

- (void)dealloc {
    [self removeObservers];
    [_editor.draft.imageGenerator.innerImageGenerator cancelAllCGImageGeneration];
}

- (void)syncUIWithEffect {
    if (!_duration) {
        return;
    }
    _seekerPosition.constant = _snapshotsView.frame.size.width * (_editor.currentTime - _editor.draft.timeRange.startTime) / _duration;
    for (MDSceneEffect *effect in ((MDFilter *)MDFilter.sharedInstance).sceneEffects) {
        UIColor *color;
        NSUInteger index = [kFUSceneEffectCodes indexOfObject:effect.sceneCode];
        if (index == NSNotFound) {
            color = kTuSDKSceneEffectColors[[kTuSDKSceneEffectCodes indexOfObject:effect.sceneCode]];
        } else {
            color = kFUSceneEffectColors[index];
        }
        SceneEffectLine *line = [SceneEffectLine new];
        line.color = color;
        line.start = effect.timeRange.startTime / _duration;
        line.length = effect.timeRange.duration / _duration;
        [_coverView.lines addObject:line];
        [_coverView setNeedsDisplay];
    }
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
    _seekerPosition.constant = _snapshotsView.frame.size.width * (_editor.currentTime - _editor.draft.timeRange.startTime) / _duration;
    NSTimeInterval effectDuration = _editor.currentTime - _currentEffectStartTime;
    // 可能存在误差，所以做一下判断
    if (effectDuration >= 0) {
        _currentLine.length = effectDuration / _duration;
    }
    [_coverView setNeedsDisplay];
}

- (void)addObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentTimeUpdated:) name:kMSVEditorCurrentTimeUpdatedNotification object:_editor];
}

- (void)removeObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setEffectStart:(id)effectCode color:(UIColor *)color {
    MDFilter *filter = [MDFilter sharedInstance];
    MDSceneEffect *effect = [MDSceneEffect new];
    effect.sceneCode = effectCode;
    _currentEffectStartTime = _editor.currentTime;
    [filter.sceneEffects addObject:effect];
    _currentLine = [SceneEffectLine new];
    _currentLine.color = color;
    _currentLine.start = _editor.currentTime / _duration;
    [_coverView.lines addObject:_currentLine];
    _editor.loop = NO;
    [_editor play];
}

- (void)setEffectEnd {
    MDFilter *filter = [MDFilter sharedInstance];
    MDSceneEffect *effect = filter.sceneEffects.lastObject;
    NSTimeInterval effectDuration = _editor.currentTime - _currentEffectStartTime;
    if (effectDuration > 0) {
        // 修复误差
        effectDuration += 0.003 * _duration;
        effect.timeRange = (MovieousTimeRange) {
            _currentEffectStartTime,
            effectDuration,
        };
        _currentLine.length = effectDuration / _duration;
    } else {
        [filter.sceneEffects removeObject:effect];
        [_coverView.lines removeObject:_currentLine];
    }
    _editor.loop = YES;
    [_editor pause];
    [_coverView setNeedsDisplay];
    _currentLine = nil;
    _currentEffectStartTime = -1;
}

- (IBAction)seekViewPanned:(UIPanGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        _seeking = YES;
        _playing = _editor.playing;
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
        [_editor seekToTime:_editor.draft.timeRange.startTime + _duration * _seekerPosition.constant / _snapshotsView.frame.size.width accurate:YES];
    } else {
        [_editor seekToTime:_editor.draft.timeRange.startTime +  _duration * _seekerPosition.constant / _snapshotsView.frame.size.width accurate:YES];
        _seeking = NO;
    }
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    // 使用 1.5 倍的预览条高度作为几个控件能够接收拖拽事件的区域
    CGFloat WH = _snapshotsView.frame.size.height * 1.5;
    CGRect seekerRect = CGRectMake(_seekerView.center.x - WH/2, _seekerView.center.y - WH/2, WH, WH);
    if (CGRectContainsPoint(seekerRect, point)) {
        return _seekerView;
    } else {
        return [super hitTest:point withEvent:event];
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (collectionView.tag == 0) {
        return _generatorResults.count;
    } else {
        if (MDGlobalSettings.sharedInstance.vendorType == VendorTypeFaceunity) {
            return kFUSceneEffectCodes.count + 1;
        } else if (MDGlobalSettings.sharedInstance.vendorType == VendorTypeTuSDK) {
            return kTuSDKSceneEffectCodes.count + 1;
        } else {
            return 0;
        }
    }
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    // 缩略图
    if (collectionView.tag == 0) {
        SceneEffectSnapshotCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"SceneEffectSnapshotCell" forIndexPath:indexPath];
        cell.imageView.image = _generatorResults[indexPath.row].image;
        return cell;
    } else {
        SceneEffectCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"SceneEffectCell" forIndexPath:indexPath];
        cell.effectButton.tag = indexPath.row;
        NSString *title, *imageName;
        if (indexPath.row == 0) {
            title = @"NO";
            imageName = @"noitem";
        } else {
            if (MDGlobalSettings.sharedInstance.vendorType == VendorTypeFaceunity) {
                title = kFUSceneEffectCodes[indexPath.row - 1];
                imageName = kFUSceneEffectCodes[indexPath.row - 1];
            } else if (MDGlobalSettings.sharedInstance.vendorType == VendorTypeTuSDK) {
                title = [NSString stringWithFormat:@"lsq_filter_%@", kTuSDKSceneEffectCodes[indexPath.row - 1]];
                title = NSLocalizedString(title,@"特效");
                imageName = [NSString stringWithFormat:@"lsq_filter_thumb_%@.jpg",kTuSDKSceneEffectCodes[indexPath.row - 1]];
            }
        }
        cell.effectNameLabel.text = title;
        [cell.effectButton setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
        return cell;
    }
}

- (IBAction)effectButtonTouchDown:(UIButton *)sender {
    if (sender.tag == 0) {
        [self setEffectStart:[NSNull null] color:[UIColor clearColor]];
    } else if (sender.tag <= kFUSceneEffectCodes.count) {
        [self setEffectStart:kFUSceneEffectCodes[sender.tag - 1] color:kFUSceneEffectColors[sender.tag - 1]];
    } else {
        [self setEffectStart:kTuSDKSceneEffectCodes[sender.tag - kFUSceneEffectCodes.count - 1] color:kTuSDKSceneEffectColors[sender.tag - kFUSceneEffectCodes.count - 1]];
    }
}

- (IBAction)effectButtonTouchUp:(UIButton *)sender {
    [self setEffectEnd];
}

@end
