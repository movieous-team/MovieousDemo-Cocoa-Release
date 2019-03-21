//
//  MDParticleEffectViewController.m
//  MovieousDemo
//
//  Created by Chris Wang on 2018/11/11.
//  Copyright © 2018 Movieous Team. All rights reserved.
//

#import "MDParticleEffectViewController.h"
#import "MDSharedCenter.h"
#import "TuSDKManager.h"
#import "FilterParamItemView.h"
#import "TuSDKFramework.h"

#define SNAPSHOT_COUNT 10

@interface MagicEffectParamView : UIView
<
FilterParamItemViewDelegate,
TuSDKICSeekBarDelegate
>

@end

@implementation MagicEffectParamView {
    // 大小调节滑动条
    FilterParamItemView *_sizeParamItemView;
    // 颜色调整滑动条
    TuSDKICSeekBar *_colorSeekBar;
    // 粒子特效大小
    CGFloat _particleSize;
    // 粒子特效颜色
    UIColor *_particleColor;
}

- (void)layoutSubviews {
    [self removeAllSubviews];
    CGFloat paramWidthRate = 1;
    _sizeParamItemView = [[FilterParamItemView alloc] initWithFrame:CGRectMake(self.lsqGetSizeWidth * (1 - paramWidthRate) / 2 , 0, self.lsqGetSizeWidth * paramWidthRate, self.lsqGetSizeHeight * 0.5)];
    _sizeParamItemView.itemDelegate = self;
    [_sizeParamItemView initParamViewWith:NSLocalizedString(@"lsq_movieEditor_effect_sizeTitle",@"大小") originProgress:0];
    _sizeParamItemView.mainColor = [UIColor whiteColor];
    [self addSubview: _sizeParamItemView];
    
    // 颜色调节滑动条
    CGFloat colorSeekBarX = 60;
    _colorSeekBar = [TuSDKICSeekBar initWithFrame:CGRectMake(colorSeekBarX, self.lsqGetSizeHeight * 0.5, self.lsqGetSizeWidth - 20 - colorSeekBarX, self.lsqGetSizeHeight * 0.5)];
    _colorSeekBar.delegate = self;
    _colorSeekBar.progress = 0;
    _colorSeekBar.aboveView.backgroundColor = [UIColor clearColor];
    _colorSeekBar.dragView.backgroundColor = lsqRGBA(244, 161, 24, 0.7);
    [self addSubview:_colorSeekBar];
    
    UIImageView *iv = [[UIImageView alloc]initWithFrame:_colorSeekBar.belowView.bounds];
    iv.image = [UIImage imageNamed:@"style_default_2.0_moviEditor_gradientColor"];
    [_colorSeekBar.belowView addSubview:iv];
    
    UILabel *colorTitlelabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.lsqGetSizeHeight * 0.5, colorSeekBarX, self.lsqGetSizeHeight * 0.5)];
    colorTitlelabel.text = NSLocalizedString(@"lsq_movieEditor_effect_colorTitle",@"颜色");
    colorTitlelabel.font = [UIFont systemFontOfSize:12];
    colorTitlelabel.textColor = _sizeParamItemView.mainColor;
    colorTitlelabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:colorTitlelabel];
    
    _particleSize = 0;
    _particleColor = [self getColorFromGradientImageWithProgress:0];
}

// 根据progress 取图片中对应点的位置
- (UIColor *)getColorFromGradientImageWithProgress:(CGFloat)progress;
{
    if (progress <= 0) return lsqRGBA(244, 161, 24, 0.7);
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_6_1
    int bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast;
#else
    int bitmapInfo = kCGImageAlphaPremultipliedLast;
#endif
    
    UIImage *image = [UIImage imageNamed:@"style_default_2.0_moviEditor_gradientColor"];
    CGSize imageSize = image.size;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 imageSize.width,
                                                 imageSize.height,
                                                 8,//bits per component
                                                 imageSize.width*4,
                                                 colorSpace,
                                                 bitmapInfo);
    
    CGRect drawRect = CGRectMake(0, 0, imageSize.width, imageSize.height);
    CGContextDrawImage(context, drawRect, image.CGImage);
    CGColorSpaceRelease(colorSpace);
    
    // 取对应点的像素值
    unsigned char* data = (unsigned char *)CGBitmapContextGetData(context);
    if (data == NULL) return nil;
    int offset = 4 * (int)(imageSize.width * progress);
    UIColor *resultColor = [UIColor colorWithRed:data[offset]/255.0 green:data[offset + 1]/255.0 blue:data[offset + 2]/255.0 alpha:1];
    CGContextRelease(context);
    
    return resultColor;
}

/**
 参数改变时的回调
 */
- (void)filterParamItemView:(FilterParamItemView *)filterParamItemView changedProgress:(CGFloat)progress {
    _particleSize = progress;
    [[NSNotificationCenter defaultCenter] postNotificationName:kMagicEffectSizeUpdatedNotification object:self userInfo:@{@"size": @(progress)}];
}

/**
 *  进度改变
 *
 *  @param seekbar  百分比控制条
 *  @param progress 进度百分比
 */
- (void)onTuSDKICSeekBar:(TuSDKICSeekBar *)seekbar changedProgress:(CGFloat)progress {
    UIColor *newColor = [self getColorFromGradientImageWithProgress:progress];;
    _colorSeekBar.dragView.backgroundColor = newColor;
    _particleColor = newColor;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kMagicEffectColorUpdatedNotification object:self userInfo:@{@"color": newColor}];
}

@end

@interface MagicEffectLine : NSObject

@property (nonatomic, assign) float start;
@property (nonatomic, assign) float length;
@property (nonatomic, strong) UIColor *color;

@end

@implementation MagicEffectLine

@end

@interface MagicEffectCoverView : UIView

@property (nonatomic, strong) NSMutableArray<MagicEffectLine *> *lines;

@end

@implementation MagicEffectCoverView

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        _lines = [NSMutableArray array];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    for (MagicEffectLine *line in _lines) {
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

@interface MagicEffectSnapshotCell : UICollectionViewCell

@property (strong, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation MagicEffectSnapshotCell

@end

@interface MagicEffectCell : UICollectionViewCell

@property (strong, nonatomic) IBOutlet UIButton *effectButton;
@property (strong, nonatomic) IBOutlet UILabel *effectNameLabel;

@end

@implementation MagicEffectCell

@end

@interface MDParticleEffectViewController ()

@property (strong, nonatomic) IBOutlet UIButton *doneButton;

@end

@implementation MDParticleEffectViewController

- (void)viewDidLoad {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(beginEditEffectParams:) name:kMagicEffectBeginEditParamNotification object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)beginEditEffectParams:(NSNotification *)notification {
    _doneButton.hidden = NO;
}

- (IBAction)doneButtonPressed:(UIButton *)sender {
    _doneButton.hidden = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:kMagicEffectEndEditParamNotification object:self];
}

- (void)viewWillAppear:(BOOL)animated {
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    self.navigationController.navigationController.interactivePopGestureRecognizer.enabled = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    self.navigationController.navigationController.interactivePopGestureRecognizer.enabled = YES;
}

@end

@interface MagicEffectSelectView : UIView
<
UICollectionViewDelegate,
UICollectionViewDataSource
>

@property (strong, nonatomic) IBOutlet UICollectionView *snapshotsView;
@property (strong, nonatomic) IBOutlet UIView *seekerView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *seekerPosition;
@property (strong, nonatomic) IBOutlet MagicEffectCoverView *coverView;
@property (strong, nonatomic) IBOutlet UICollectionView *effectsCollectionView;
@property (strong, nonatomic) IBOutlet MagicEffectParamView *magicEffectParamView;

@end

@implementation MagicEffectSelectView {
    NSMutableArray *_snapshots;
    MSVEditor *_editor;
    NSTimeInterval _duration;
    BOOL _seeking;
    MagicEffectLine *_currentLine;
    BOOL _playing;
    NSString *_selectedEffectCode;
    TuSDKMediaParticleEffectData *_currentEffect;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    _editor = MDSharedCenter.sharedCenter.editor;
    if (_editor.draft.timeRange.duration > 0) {
        _duration = _editor.draft.timeRange.duration;
    } else {
        _duration = _editor.draft.duration;
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
    [self syncUIWithEffect];
    [self addObservers];
}

- (void)syncUIWithEffect {
    _seekerPosition.constant = _snapshotsView.frame.size.width * (_editor.currentTime - _editor.draft.timeRange.startTime) / _duration;
    for (TuSDKMediaParticleEffectData *effect in [TuSDKManager.sharedManager mediaEffectsWithType:TuSDKMediaEffectDataTypeParticle]) {
        UIColor *color = kVideoPaticleColors[[kVideoParticleCodes indexOfObject:effect.effectsCode]];
        MagicEffectLine *line = [MagicEffectLine new];
        line.color = color;
        line.start = effect.atTimeRange.startSeconds / _duration;
        line.length = effect.atTimeRange.durationSeconds / _duration;
        [_coverView.lines addObject:line];
        [_coverView setNeedsDisplay];
    }
}

- (void)dealloc {
    [self removeObservers];
    [[NSNotificationCenter defaultCenter] postNotificationName:kMagicEffectEndEditNotification object:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:kMagicEffectEndEditParamNotification object:self];
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
    NSTimeInterval effectDuration = _editor.currentTime - _currentEffect.atTimeRange.startSeconds;
    // 可能存在误差，所以做一下判断
    if (effectDuration >= 0) {
        _currentLine.length = effectDuration / _duration;
    }
    [_coverView setNeedsDisplay];
}

- (void)addObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentTimeUpdated:) name:kMSVEditorCurrentTimeUpdatedNotification object:_editor];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(endEditEffectParams:) name:kMagicEffectEndEditParamNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(previewTouchesBegan:) name:kPreviewTouchesBegan object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(previewTouchesMoved:) name:kPreviewTouchesMoved object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(previewTouchesEnded:) name:kPreviewTouchesEnded object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(previewTouchesCancelled:) name:kPreviewTouchesCancelled object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(magicEffectSizeUpdated:) name:kMagicEffectSizeUpdatedNotification object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(magicEffectColorUpdated:) name:kMagicEffectColorUpdatedNotification object:nil];
}

- (void)endEditEffectParams:(NSNotification *)notification {
    _effectsCollectionView.hidden = NO;
    _magicEffectParamView.hidden = YES;
}

- (void)previewTouchesBegan:(NSNotification *)notification {
    if (_selectedEffectCode) {
        _currentEffect = [[TuSDKMediaParticleEffectData alloc] initWithEffectsCode:_selectedEffectCode];
        _currentEffect.atTimeRange = [TuSDKTimeRange makeTimeRangeWithStartSeconds:_editor.currentTime endSeconds:1000];
        [TuSDKManager.sharedManager addMediaEffect:_currentEffect];
        _currentLine = [MagicEffectLine new];
        _currentLine.color = kVideoPaticleColors[[kVideoParticleCodes indexOfObject:_selectedEffectCode]];
        _currentLine.start = _editor.currentTime / _duration;
        [_coverView.lines addObject:_currentLine];
    }
    [_currentEffect updateParticleEmitPosition:[notification.userInfo[@"location"] CGPointValue] withCurrentTime:CMTimeMakeWithSeconds(_editor.currentTime, 10000)];
    [_editor play];
}

- (void)previewTouchesMoved:(NSNotification *)notification {
    [_currentEffect updateParticleEmitPosition:[notification.userInfo[@"location"] CGPointValue] withCurrentTime:CMTimeMakeWithSeconds(_editor.currentTime, 10000)];
}

- (void)previewTouchesEnded:(NSNotification *)notification {
    [_currentEffect updateParticleEmitPosition:[notification.userInfo[@"location"] CGPointValue] withCurrentTime:CMTimeMakeWithSeconds(_editor.currentTime, 10000)];
    _currentEffect.atTimeRange = [TuSDKTimeRange makeTimeRangeWithStartSeconds:_currentEffect.atTimeRange.startSeconds endSeconds:_editor.currentTime];
    _currentLine.length = (_editor.currentTime - _currentEffect.atTimeRange.startSeconds) / _duration;
    _currentEffect = nil;
    _currentLine = nil;
    [_editor pause];
}

- (void)previewTouchesCancelled:(NSNotification *)notification {
    [_currentEffect updateParticleEmitPosition:[notification.userInfo[@"location"] CGPointValue] withCurrentTime:CMTimeMakeWithSeconds(_editor.currentTime, 10000)];
    _currentEffect.atTimeRange = [TuSDKTimeRange makeTimeRangeWithStartSeconds:_currentEffect.atTimeRange.startSeconds endSeconds:_editor.currentTime];
    _currentLine.length = (_editor.currentTime - _currentEffect.atTimeRange.startSeconds) / _duration;
    _currentEffect = nil;
    _currentLine = nil;
    [_editor pause];
}

- (void)magicEffectColorUpdated:(NSNotification *)notification {
}

- (void)removeObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
        [_editor seekToTime:_editor.draft.timeRange.startTime + _duration * _seekerPosition.constant / _snapshotsView.frame.size.width completionHandler:nil];
    } else {
        __weak typeof(self) wSelf = self;
        [_editor seekToTime:_editor.draft.timeRange.startTime +  _duration * _seekerPosition.constant / _snapshotsView.frame.size.width completionHandler:^(BOOL finished) {
            __strong typeof(wSelf) strongSelf = wSelf;
            strongSelf->_seeking = NO;
        }];
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
        return _snapshots.count;
    } else {
        return kVideoParticleCodes.count;
    }
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView.tag == 0) {
        MagicEffectSnapshotCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MagicEffectSnapshotCell" forIndexPath:indexPath];
        cell.imageView.image = _snapshots[indexPath.row];
        return cell;
    } else {
        MagicEffectCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MagicEffectCell" forIndexPath:indexPath];
        cell.effectButton.tag = indexPath.row;
        NSString *title, *imageName;
        NSString *code = kVideoParticleCodes[indexPath.row];
        if ((id)code == [NSNull null]) {
            title = @"discard";
            imageName = @"noitem";
        } else {
            title = [NSString stringWithFormat:@"lsq_filter_%@",code];
            title = NSLocalizedString(title,@"滤镜");
            imageName = [NSString stringWithFormat:@"lsq_filter_thumb_%@.jpg",code];
        }
        cell.effectNameLabel.text = title;
        [cell.effectButton setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
        if ([_selectedEffectCode isEqualToString:code]) {
            cell.effectNameLabel.backgroundColor = [UIColor redColor];
        } else {
            cell.effectNameLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        }
        return cell;
    }
}

- (IBAction)effectButtonPressed:(UIButton *)sender {
    [_editor pause];
    id code = kVideoParticleCodes[sender.tag];
    if (code == [NSNull null]) {
        id effect = [TuSDKManager.sharedManager mediaEffectsWithType:TuSDKMediaEffectDataTypeParticle].lastObject;
        if (effect) {
            [TuSDKManager.sharedManager removeMediaEffect:effect];
            [_coverView.lines removeLastObject];
            [_coverView setNeedsDisplay];
        }
        _selectedEffectCode = nil;
        [[NSNotificationCenter defaultCenter] postNotificationName:kMagicEffectEndEditNotification object:self];
    } else {
        // 第二次点击同一个按键
        if ([_selectedEffectCode isEqualToString:code]) {
            _effectsCollectionView.hidden = YES;
            _magicEffectParamView.hidden = NO;
            [[NSNotificationCenter defaultCenter] postNotificationName:kMagicEffectBeginEditParamNotification object:self];
            return;
        } else {
            _selectedEffectCode = code;
            [[NSNotificationCenter defaultCenter] postNotificationName:kMagicEffectBeginEditNotification object:self];
        }
    }
    [_effectsCollectionView reloadData];
}

@end
