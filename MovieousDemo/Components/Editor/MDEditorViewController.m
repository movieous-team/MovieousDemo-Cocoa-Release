//
//  MDEditorViewController.m
//  MovieousDemo
//
//  Created by Chris Wang on 2018/10/5.
//  Copyright © 2018 Movieous Team. All rights reserved.
//

#import "MDEditorViewController.h"
#import <MovieousShortVideo/MovieousShortVideo.h>
#import "MDShortVideoFilter.h"
#import "MDSharedCenter.h"
#import "FUManager.h"
#import "STManager.h"
#import "MDUploaderViewController.h"
#import "MDEditorPreviewContainerView.h"
#import "MDImageStickerViewController.h"

@interface MDEditorViewController ()
<
MSVEditorDelegate
>

@property (strong, nonatomic) IBOutlet MDEditorPreviewContainerView *previewContainer;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *bottomViewHeight;
@property (strong, nonatomic) IBOutlet UIButton *playButton;

@end

@implementation MDEditorViewController {
    MSVEditor *_editor;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [MDSharedCenter.sharedCenter instantiateProperties];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(beginEditingBottom:) name:kBeginEditingInBottomViewNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(endEditingBottom:) name:kEndEditingInBottomViewNotification object:nil];
}

- (void)dealloc {
    [MDSharedCenter.sharedCenter clearProperties];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSError *error;
    // 如果不需要对之前采集的多短视频在编辑阶段进行分段处理，那么可以分离出允许继续在编辑阶段调整的部分，然后导出为一个完整的视频再进行处理，这样可以保证编辑操作都具有最高的处理效率，Demo 直接使用录制生成的草稿对象以便灵活调整
    _editor = MDSharedCenter.sharedCenter.editor;
    [_editor updateDraft:_draft error:&error];
    if (error) {
        SHOW_ERROR_ALERT;
        return;
    }
    _editor.delegate = self;
    _previewContainer.preview = _editor.preview;
    _editor.loop = YES;
    // 添加外部滤镜来对视频进行自定义处理
    MSVExternalFilterEffect *effect = [MSVExternalFilterEffect new];
    effect.externalFilterClass = MDShortVideoFilter.class;
    [_editor.draft updateBasicEffects:@[effect] error:&error];
    if (error) {
        SHOW_ERROR_ALERT;
        return;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [_editor play];
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
    [_editor pause];
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
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
    if ([segue.destinationViewController isKindOfClass:MDUploaderViewController.class]) {
        MDUploaderViewController *controller = (MDUploaderViewController *)segue.destinationViewController;
        controller.draft = _editor.draft;
    }
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (IBAction)playButtonPressed:(UIButton *)sender {
    if (_editor.playing) {
        [_editor pause];
        [_playButton setTitle:@"播放" forState:UIControlStateNormal];
    } else {
        [_editor play];
        [_playButton setTitle:@"暂停" forState:UIControlStateNormal];
    }
}

- (void)editor:(MSVEditor *)editor playStateChanged:(BOOL)playing {
    if (playing) {
        [_playButton setTitle:@"暂停" forState:UIControlStateNormal];
    } else {
        [_playButton setTitle:@"播放" forState:UIControlStateNormal];
    }
}

@end
