//
//  EditorViewController.m
//  MovieousDemo
//
//  Created by Chris Wang on 2018/10/5.
//  Copyright © 2018 Movieous Team. All rights reserved.
//

#import "EditorViewController.h"
#import <MovieousShortVideo/MovieousShortVideo.h>
#import "ShortVideoFilter.h"
#import "MSVEditor+Extentions.h"
#import "FUManager.h"
#import "STManager.h"
#import "MSVEditor+Extentions.h"
#import "UploaderViewController.h"

@interface PreviewContainerView : UIView

@property (nonatomic, strong) UIView *preview;

@end

@implementation PreviewContainerView

- (void)layoutSubviews {
    [self insertSubview:_preview atIndex:0];
    _preview.frame = self.bounds;
}

// 粒子特效需要监控的手势
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    CGPoint location = [touches.objectEnumerator.nextObject locationInView:self];
    CGRect contentFrame = MSVEditor.sharedInstance.contentFrame;
    if (CGRectContainsPoint(contentFrame, location)) {
        location = CGPointMake((location.x - contentFrame.origin.x) / contentFrame.size.width, (location.y - contentFrame.origin.y) / contentFrame.size.height);
        [[NSNotificationCenter defaultCenter] postNotificationName:kPreviewTouchesBegan object:self userInfo:@{@"location": [NSValue valueWithCGPoint:location]}];
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    CGPoint location = [touches.objectEnumerator.nextObject locationInView:self];
    CGRect contentFrame = MSVEditor.sharedInstance.contentFrame;
    if (CGRectContainsPoint(contentFrame, location)) {
        location = CGPointMake((location.x - contentFrame.origin.x) / contentFrame.size.width, (location.y - contentFrame.origin.y) / contentFrame.size.height);
        [[NSNotificationCenter defaultCenter] postNotificationName:kPreviewTouchesMoved object:self userInfo:@{@"location": [NSValue valueWithCGPoint:location]}];
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    CGPoint location = [touches.objectEnumerator.nextObject locationInView:self];
    CGRect contentFrame = MSVEditor.sharedInstance.contentFrame;
    if (CGRectContainsPoint(contentFrame, location)) {
        location = CGPointMake((location.x - contentFrame.origin.x) / contentFrame.size.width, (location.y - contentFrame.origin.y) / contentFrame.size.height);
        [[NSNotificationCenter defaultCenter] postNotificationName:kPreviewTouchesEnded object:self userInfo:@{@"location": [NSValue valueWithCGPoint:location]}];
    }
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    CGPoint location = [touches.objectEnumerator.nextObject locationInView:self];
    CGRect contentFrame = MSVEditor.sharedInstance.contentFrame;
    if (CGRectContainsPoint(contentFrame, location)) {
        location = CGPointMake((location.x - contentFrame.origin.x) / contentFrame.size.width, (location.y - contentFrame.origin.y) / contentFrame.size.height);
        [[NSNotificationCenter defaultCenter] postNotificationName:kPreviewTouchesCancelled object:self userInfo:@{@"location": [NSValue valueWithCGPoint:location]}];
    }
}

@end

@interface EditorViewController ()
<
MSVEditorDelegate
>

@property (strong, nonatomic) IBOutlet PreviewContainerView *previewContainer;
@property (strong, nonatomic) IBOutlet UIImageView *playImage;
@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *tapGesture;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *bottomViewHeight;

@end

@implementation EditorViewController {
    MSVEditor *_editor;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSError *error;

    // 如果不需要对之前采集的多短视频在编辑阶段进行分段处理，那么可以分离出允许继续在编辑阶段调整的部分，然后导出为一个完整的视频再进行处理，这样可以保证编辑操作都具有最高的处理效率，Demo 直接使用录制生成的草稿对象以便调整灵活调整
    _editor = [MSVEditor createSharedInstanceWithDraft:_draft error:&error];
    if (error) {
        SHOW_ERROR_ALERT;
        return;
    }
    _editor.delegate = self;
    _previewContainer.preview = _editor.preview;
    _editor.loop = YES;
    // 添加外部滤镜来对视频进行自定义处理
    MSVExternalFilterEffect *effect = [MSVExternalFilterEffect new];
    effect.externalFilterClass = ShortVideoFilter.class;
    [_editor.draft updateEffects:@[effect] error:&error];
    if (error) {
        SHOW_ERROR_ALERT;
        return;
    }
    // 初始化 FUManager
    [[FUManager shareManager] destoryItems];
    [[FUManager shareManager] loadFilter];
    [[FUManager shareManager] setAsyncTrackFaceEnable:YES];
    [[FUManager shareManager] setBeautyDefaultParameters];
    [[STManager sharedManager] cancelStickerAndObjectTrack];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(beginEditingBottom:) name:kBeginEditingInBottomViewNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(endEditingBottom:) name:kEndEditingInBottomViewNotification object:nil];
    // 粒子特效需要用到的事件监控
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(effectBeginEdit:) name:kMagicEffectBeginEditNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(effectEndEdit:) name:kMagicEffectEndEditNotification object:nil];
}

- (void)dealloc {
    [MSVEditor clearSharedInstance];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidAppear:(BOOL)animated {
    [_editor play];
}

- (void)viewWillDisappear:(BOOL)animated {
    [_editor pause];
}

- (void)effectBeginEdit:(NSNotification *)notification {
    _tapGesture.enabled = NO;
}

- (void)effectEndEdit:(NSNotification *)notification {
    _tapGesture.enabled = YES;
}

- (void)beginEditingBottom:(NSNotification *)notification {
    _bottomViewHeight.constant += 50;
}

- (void)endEditingBottom:(NSNotification *)notification {
    _bottomViewHeight.constant -= 50;
}

- (void)viewWillAppear:(BOOL)animated {
    self.navigationController.navigationBarHidden = NO;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:UploaderViewController.class]) {
        UploaderViewController *controller = (UploaderViewController *)segue.destinationViewController;
        controller.draft = _editor.draft;
    }
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (IBAction)previewTapped:(UITapGestureRecognizer *)sender {
    if (_editor.playing) {
        [_editor pause];
    } else {
        [_editor play];
    }
}

- (void)editor:(MSVEditor *)editor playStateChanged:(BOOL)playing {
    if (playing) {
        _playImage.hidden = YES;
    } else {
        _playImage.hidden = NO;
    }
}

@end
