//
//  MDEditorPreviewContainerView.m
//  MovieousDemo
//
//  Created by Chris Wang on 2019/1/17.
//  Copyright © 2019 Movieous Team. All rights reserved.
//

#import "MDEditorPreviewContainerView.h"
#import "MDSharedCenter.h"
#import "MDImageStickerViewController.h"
#import "MDFrameView.h"

// 边框和框内的图片之间的距离
#define FrameViewMargin 10

#define DeleteButtonWidth 20

@interface MDEditorPreviewContainerView ()
<
UIGestureRecognizerDelegate
>

@end

@implementation MDEditorPreviewContainerView {
    UITapGestureRecognizer *_tapGestureRecognizer;
    UIPanGestureRecognizer *_panGestureRecognizer;
    UIPinchGestureRecognizer *_pinchGestureRecognizer;
    UIRotationGestureRecognizer *_rotationGestureRecognizer;
    MDFrameView *_frameView;
    UIButton *_deleteStickerButton;
    BOOL _stickerSelected;
    BOOL _stickerPanStarted;
    CGPoint _lastTranslation;
    CGFloat _lastScale;
    CGFloat _lastRotation;
    MSVImageStickerEditorEffect *_selectedImageStickerEffect;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    _frameView = [MDFrameView new];
    _frameView.hidden = YES;
    _frameView.frameWidth = 2;
    _frameView.margin = DeleteButtonWidth / 2;
    [self addSubview:_frameView];
    _deleteStickerButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _deleteStickerButton.bounds = CGRectMake(0, 0, DeleteButtonWidth, DeleteButtonWidth);
    [_deleteStickerButton setImage:[UIImage imageNamed:@"delete"] forState:UIControlStateNormal];
    [_deleteStickerButton addTarget:self action:@selector(deleteStickerButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [_frameView addSubview:_deleteStickerButton];
    MDSharedCenter.sharedCenter.graffitiView.brush = [MSVBrush brushWithLineWidth:10 lineColor:UIColor.whiteColor];
    MDSharedCenter.sharedCenter.graffitiView.hidden = YES;
    [self addSubview:MDSharedCenter.sharedCenter.graffitiView];
    _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
    _tapGestureRecognizer.delegate = self;
    _tapGestureRecognizer.cancelsTouchesInView = NO;
    [self addGestureRecognizer:_tapGestureRecognizer];
    _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panned:)];
    _panGestureRecognizer.delegate = self;
    _panGestureRecognizer.cancelsTouchesInView = NO;
    [self addGestureRecognizer:_panGestureRecognizer];
    _pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinched:)];
    _pinchGestureRecognizer.delegate = self;
    _pinchGestureRecognizer.cancelsTouchesInView = NO;
    [self addGestureRecognizer:_pinchGestureRecognizer];
    _rotationGestureRecognizer = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(rotated:)];
    _rotationGestureRecognizer.delegate = self;
    _rotationGestureRecognizer.cancelsTouchesInView = NO;
    [self addGestureRecognizer:_rotationGestureRecognizer];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (void)layoutSubviews {
    _preview.frame = self.bounds;
    MDSharedCenter.sharedCenter.graffitiView.frame = MDSharedCenter.sharedCenter.editor.contentFrame;
}

- (void)deleteStickerButtonPressed:(UIButton *)sender {
    if (!_selectedImageStickerEffect) {
        return;
    }
    NSMutableArray *basicEffects = [NSMutableArray arrayWithArray:MDSharedCenter.sharedCenter.editor.draft.basicEffects];
    [basicEffects removeObject:_selectedImageStickerEffect];
    NSError *error;
    if (![MDSharedCenter.sharedCenter.editor.draft updateBasicEffects:basicEffects error:&error]) {
        SHOW_ERROR_ALERT_FOR(UIApplication.sharedApplication.keyWindow.rootViewController);
    }
    _frameView.hidden = YES;
}

- (void)tapped:(UITapGestureRecognizer *)sender {
    CGPoint location = [sender locationInView:self];
    if (CGRectContainsPoint([_frameView convertRect:_deleteStickerButton.frame toView:self], location)) {
        return;
    }
    CGRect contentFrame = MDSharedCenter.sharedCenter.editor.contentFrame;
    _stickerSelected = NO;
    _selectedImageStickerEffect = nil;
    _frameView.hidden = YES;
    for (int i = (int)MDSharedCenter.sharedCenter.editor.draft.basicEffects.count - 1; i >= 0; i--) {
        id<MSVBasicEditorEffect> effect = MDSharedCenter.sharedCenter.editor.draft.basicEffects[i];
        // 只处理贴纸面板添加进去的贴纸，文字等由贴纸功能实现的特效不在这里处理
        if (![effect.ID isEqualToString:kImageStickerEffectID]) {
            continue;
        }
        if ([effect isKindOfClass:MSVImageStickerEditorEffect.class]) {
            MSVImageStickerEditorEffect *imageStickerEffect = (MSVImageStickerEditorEffect *)effect;
            CGSize videoSize = MDSharedCenter.sharedCenter.editor.draft.videoSize;
            CGRect imageStickerFrame = CGRectMake(contentFrame.origin.x + imageStickerEffect.destRect.origin.x / videoSize.width * contentFrame.size.width, contentFrame.origin.y + imageStickerEffect.destRect.origin.y / videoSize.width * contentFrame.size.width, imageStickerEffect.destRect.size.width / videoSize.width * contentFrame.size.width, imageStickerEffect.destRect.size.height / videoSize.height * contentFrame.size.height);
            if (CGRectContainsPoint(imageStickerFrame, location)) {
                _stickerSelected = YES;
                _selectedImageStickerEffect = imageStickerEffect;
                _frameView.bounds = CGRectMake(0, 0, imageStickerFrame.size.width + 2 * FrameViewMargin + _frameView.margin, imageStickerFrame.size.height + 2 * FrameViewMargin + _frameView.margin);
                _frameView.center = CGPointMake(CGRectGetMidX(imageStickerFrame), CGRectGetMidY(imageStickerFrame));
                _frameView.transform = CGAffineTransformMakeRotation(imageStickerEffect.rotation);
                _frameView.hidden = NO;
                _deleteStickerButton.center = CGPointMake(_frameView.bounds.size.width - _frameView.margin - _frameView.frameWidth / 2, _frameView.margin + _frameView.frameWidth / 2);
                break;
            }
        }
    }
}

- (void)panned:(UIPanGestureRecognizer *)sender {
    if (_stickerSelected) {
        CGPoint location = [sender locationInView:self];
        if (sender.state == UIGestureRecognizerStateBegan) {
            if (CGRectContainsPoint(_frameView.frame, location)) {
                _lastTranslation = [sender translationInView:self];
                _stickerPanStarted = YES;
            } else {
                _stickerPanStarted = NO;
            }
        } else {
            if (_stickerPanStarted) {
                CGRect contentFrame = MDSharedCenter.sharedCenter.editor.contentFrame;
                CGSize videoSize = MDSharedCenter.sharedCenter.editor.draft.videoSize;
                CGPoint translation = [sender translationInView:self];
                CGPoint translationDelta = CGPointMake(translation.x - _lastTranslation.x, translation.y - _lastTranslation.y);
                _lastTranslation = translation;
                _selectedImageStickerEffect.destRect = CGRectMake(_selectedImageStickerEffect.destRect.origin.x + translationDelta.x / contentFrame.size.width * videoSize.width, _selectedImageStickerEffect.destRect.origin.y + translationDelta.y / contentFrame.size.height * videoSize.height, _selectedImageStickerEffect.destRect.size.width, _selectedImageStickerEffect.destRect.size.height);
                _frameView.center = CGPointMake(_frameView.center.x + translationDelta.x, _frameView.center.y + translationDelta.y);
                _deleteStickerButton.center = CGPointMake(_frameView.bounds.size.width - _frameView.margin - _frameView.frameWidth / 2, _frameView.margin + _frameView.frameWidth / 2);
            }
        }
    }
}

- (void)pinched:(UIPinchGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        _lastScale = 1;
    } else {
        CGFloat deltaScale = sender.scale / _lastScale;
        _lastScale = sender.scale;
        _selectedImageStickerEffect.destRect = CGRectMake(_selectedImageStickerEffect.destRect.origin.x - _selectedImageStickerEffect.destRect.size.width * (deltaScale - 1) / 2, _selectedImageStickerEffect.destRect.origin.y - _selectedImageStickerEffect.destRect.size.height * (deltaScale - 1) / 2, _selectedImageStickerEffect.destRect.size.width * deltaScale, _selectedImageStickerEffect.destRect.size.height * deltaScale);
        CGRect contentFrame = MDSharedCenter.sharedCenter.editor.contentFrame;
        CGSize videoSize = MDSharedCenter.sharedCenter.editor.draft.videoSize;
        CGRect imageStickerFrame = CGRectMake(contentFrame.origin.x + _selectedImageStickerEffect.destRect.origin.x / videoSize.width * contentFrame.size.width, contentFrame.origin.y + _selectedImageStickerEffect.destRect.origin.y / videoSize.width * contentFrame.size.width, _selectedImageStickerEffect.destRect.size.width / videoSize.width * contentFrame.size.width, _selectedImageStickerEffect.destRect.size.height / videoSize.height * contentFrame.size.height);
        _frameView.bounds = CGRectMake(0, 0, imageStickerFrame.size.width + 2 * FrameViewMargin + _frameView.margin, imageStickerFrame.size.height + 2 * FrameViewMargin + _frameView.margin);
        _deleteStickerButton.center = CGPointMake(_frameView.bounds.size.width - _frameView.margin - _frameView.frameWidth / 2, _frameView.margin + _frameView.frameWidth / 2);
    }
}

- (void)rotated:(UIRotationGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        _lastRotation = 0;
    } else {
        CGFloat deltaRotation = sender.rotation - _lastRotation;
        _lastRotation = sender.rotation;
        _selectedImageStickerEffect.rotation = _selectedImageStickerEffect.rotation + deltaRotation;
        _frameView.transform = CGAffineTransformConcat(_frameView.transform, CGAffineTransformMakeRotation(deltaRotation));
    }
}

// 粒子特效需要监控的手势
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    CGPoint location = [touches.objectEnumerator.nextObject locationInView:self];
    CGRect contentFrame = MDSharedCenter.sharedCenter.editor.contentFrame;
    if (CGRectContainsPoint(contentFrame, location)) {
        location = CGPointMake((location.x - contentFrame.origin.x) / contentFrame.size.width, (location.y - contentFrame.origin.y) / contentFrame.size.height);
        [[NSNotificationCenter defaultCenter] postNotificationName:kPreviewTouchesBegan object:self userInfo:@{@"location": [NSValue valueWithCGPoint:location]}];
    }
}

- (void)setPreview:(UIView *)preview {
    [_preview removeFromSuperview];
    _preview = preview;
    [self insertSubview:preview atIndex:0];
}

// 粒子特效相关的手势
//- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
//    CGPoint location = [touches.objectEnumerator.nextObject locationInView:self];
//    CGRect contentFrame = MDSharedCenter.sharedCenter.editor.contentFrame;
//    if (CGRectContainsPoint(contentFrame, location)) {
//        location = CGPointMake((location.x - contentFrame.origin.x) / contentFrame.size.width, (location.y - contentFrame.origin.y) / contentFrame.size.height);
//        [[NSNotificationCenter defaultCenter] postNotificationName:kPreviewTouchesMoved object:self userInfo:@{@"location": [NSValue valueWithCGPoint:location]}];
//    }
//}
//
//- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
//    CGPoint location = [touches.objectEnumerator.nextObject locationInView:self];
//    CGRect contentFrame = MDSharedCenter.sharedCenter.editor.contentFrame;
//    if (CGRectContainsPoint(contentFrame, location)) {
//        location = CGPointMake((location.x - contentFrame.origin.x) / contentFrame.size.width, (location.y - contentFrame.origin.y) / contentFrame.size.height);
//        [[NSNotificationCenter defaultCenter] postNotificationName:kPreviewTouchesEnded object:self userInfo:@{@"location": [NSValue valueWithCGPoint:location]}];
//    }
//}
//
//- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
//    CGPoint location = [touches.objectEnumerator.nextObject locationInView:self];
//    CGRect contentFrame = MDSharedCenter.sharedCenter.editor.contentFrame;
//    if (CGRectContainsPoint(contentFrame, location)) {
//        location = CGPointMake((location.x - contentFrame.origin.x) / contentFrame.size.width, (location.y - contentFrame.origin.y) / contentFrame.size.height);
//        [[NSNotificationCenter defaultCenter] postNotificationName:kPreviewTouchesCancelled object:self userInfo:@{@"location": [NSValue valueWithCGPoint:location]}];
//    }
//}

@end
