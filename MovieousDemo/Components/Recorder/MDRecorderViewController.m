//
//  MDRecorderViewController.m
//  MovieousDemo
//
//  Created by Chris Wang on 2018/10/4.
//  Copyright © 2018 Movieous Team. All rights reserved.
//
#import <CoreServices/CoreServices.h>
#import <Photos/Photos.h>

#import <MovieousShortVideo/MovieousShortVideo.h>

#import "MDRecorderViewController.h"
#import "MDProgressBar.h"
#import "MDEditorViewController.h"
#import "NSArray+MDExtension.h"
#import "MDGlobalSettings.h"
#import "MDDynamicStickerView.h"
#import "MDAVPlayerView.h"
#import "MDFilter.h"
#import "MDSharedCenter.h"

#define DefaultMaxRecordingDuration 10

@class MDRecorderMusicViewController;
@protocol MDRecorderMusicViewControllerDelegate <NSObject>

- (void)controller:(MDRecorderMusicViewController *)controller didSelectMusicPath:(NSString *)musicPath;

@end

@interface MDRecorderMusicViewController : UITableViewController

@property (nonatomic, weak) id<MDRecorderMusicViewControllerDelegate> delegate;

@end

@implementation MDRecorderMusicViewController {
    NSString *_bundlePath;
    NSArray<NSString *> *_fileNames;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _bundlePath = [[NSBundle mainBundle] pathForResource:@"BackgroundMusics" ofType:@"bundle"];
    NSError *error;
    _fileNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:_bundlePath error:&error];
    if (error) {
        SHOW_ERROR_ALERT;
        return;
    }
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _fileNames.count + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"BackgroundMusicViewController" forIndexPath:indexPath];
    if (indexPath.row == 0) {
        cell.textLabel.text = @"无";
    } else {
        cell.textLabel.text = _fileNames[indexPath.row - 1];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([_delegate respondsToSelector:@selector(controller:didSelectMusicPath:)]) {
        if (indexPath.row == 0) {
            [_delegate controller:self didSelectMusicPath:nil];
        } else {
            [_delegate controller:self didSelectMusicPath:[_bundlePath stringByAppendingPathComponent:_fileNames[indexPath.row - 1]]];
        }
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

@end

@interface MDRecorderViewController ()
<
MSVRecorderDelegate,
MDRecorderMusicViewControllerDelegate,
UIImagePickerControllerDelegate,
UINavigationControllerDelegate
>

@property (strong, nonatomic) IBOutlet UIButton *startButton;
@property (strong, nonatomic) IBOutlet MDProgressBar *progressBar;
@property (strong, nonatomic) IBOutlet UIImageView *importMediaView;
@property (strong, nonatomic) IBOutlet UISegmentedControl *speedSegment;
@property (strong, nonatomic) IBOutlet UIView *beautyFilterView;
@property (strong, nonatomic) IBOutlet UILabel *tipLabel;
@property (strong, nonatomic) IBOutlet UIView *stickerView;
@property (strong, nonatomic) IBOutlet UILabel *backgroundMusicLabel;
@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *backgroundMusicCollection;
@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *bottomCollection;
@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *topRightCollection;
@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *stickerCollection;
@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *cancelDoneCollection;
@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *importMediaCollection;
@property (strong, nonatomic) IBOutlet UILabel *countDownLabel;
@property (strong, nonatomic) IBOutlet UIButton *closeButton;

@end

@implementation MDRecorderViewController {
    MSVRecorder *_recorder;
    float _speed;
    STCommonObjectContainerView *_commonObjectContainerView;
    AVPlayer *_duetVideoPlayer;
    MDAVPlayerView *_duetPlayerView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // 避免下个页面的返回键出现 <Back 字样
    self.navigationItem.title = @"";
    _speed = 1;
    // Do any additional setup after loading the view.
    MSVRecorderAudioConfiguration *audioConfiguration = [MSVRecorderAudioConfiguration defaultConfiguration];
    MSVRecorderVideoConfiguration *videoConfiguration = [MSVRecorderVideoConfiguration defaultConfiguration];
    videoConfiguration.preferredSessionPreset = AVCaptureSessionPresetiFrame960x540;
    videoConfiguration.size = CGSizeMake(540, 960);
    NSError *error;
    _recorder = [[MSVRecorder alloc] initWithAudioConfiguration:audioConfiguration videoConfiguration:videoConfiguration error:&error];
    if (error) {
        SHOW_ERROR_ALERT;
        return;
    }
    MDSharedCenter.sharedCenter.recorder = _recorder;
    // 设置录制事件回调
    _recorder.delegate = self;
    _recorder.previewScalingMode = MovieousScalingModeAspectFill;
    _recorder.touchToFocusExposureEnabled = YES;
    _recorder.innerFocusViewEnabled = YES;
    MovieousExternalFilterCaptureEffect *externalFilterRecorderEffect = [MovieousExternalFilterCaptureEffect new];
    externalFilterRecorderEffect.externalFilterClass = MDFilter.class;
    MDSharedCenter.sharedCenter.LUTFilterCaptureEffect = [MovieousLUTFilterCaptureEffect new];
    MDSharedCenter.sharedCenter.LUTFilterCaptureEffect.image = [UIImage imageNamed:@"filter_test1"];
    MDSharedCenter.sharedCenter.faceBeautyCaptureEffect = [MovieousFaceBeautyCaptureEffect new];
    _recorder.captureEffects = @[
                                 externalFilterRecorderEffect,
                                 MDSharedCenter.sharedCenter.faceBeautyCaptureEffect,
                                  ];
    _recorder.autoOrientationAdaption = YES;
    // 将预览视图插入视图栈中
    if (_duetVideoURL) {
        CGFloat videoHeight = self.view.frame.size.width / 2 / 720 * 1280;
        CGFloat heightEdge = (self.view.frame.size.height - videoHeight) / 2;
        _recorder.previewView.frame = CGRectMake(0, heightEdge, self.view.frame.size.width / 2, videoHeight);
        // 输出的视频也需要打开前置摄像头镜像，保证拍摄时的预览和编辑时的预览保持一致
        _recorder.mirrorFrontEncoded = YES;
        [_recorder.draft setVideoSize:CGSizeMake(720, 640) error:&error];
        if (error) {
            SHOW_ERROR_ALERT;
            return;
        }
        [self.view insertSubview:_recorder.previewView atIndex:0];
        _duetVideoPlayer = [AVPlayer playerWithURL:_duetVideoURL];
        _duetPlayerView = [MDAVPlayerView playerViewWithPlayer:_duetVideoPlayer];
        _duetPlayerView.frame = CGRectMake(self.view.frame.size.width / 2, heightEdge, self.view.frame.size.width / 2, videoHeight);
        _duetPlayerView.videoGravity = AVLayerVideoGravityResizeAspectFill;
        [self.view insertSubview:_duetPlayerView atIndex:0];
        _backgroundMusicCollection.hidden = YES;
    } else {
        _recorder.previewView.frame = self.view.frame;
        [self.view insertSubview:_recorder.previewView atIndex:0];
    }
    [self getFirstMovieFromPhotoAlbum];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showHint:) name:kShowHintNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(shouldChangeToBack) name:kSTStickerViewShouldChangeToBackCameraNotification object:nil];
    if (MDGlobalSettings.sharedInstance.vendorType == VendorTypeSenseTime) {
        _commonObjectContainerView = ((MDDynamicStickerView *)_stickerView.subviews[0]).STView.commonObjectContainerView;
        [self.view insertSubview:_commonObjectContainerView atIndex:1];
    }
    [self createKiwiView];
}

- (void)createKiwiView {
    [self.view addSubview:MDSharedCenter.sharedCenter.kwUIManager.beautifyFilterView];
    
    [self.view addSubview:MDSharedCenter.sharedCenter.kwUIManager.stickerMenuView];
    
    [self.view addSubview:MDSharedCenter.sharedCenter.kwUIManager.distortionMenuView];
    
    [self.view addSubview:MDSharedCenter.sharedCenter.kwUIManager.beautifyNewView];
    
    [self.view addSubview:MDSharedCenter.sharedCenter.kwUIManager.slideBeautifyMenuView];
    
    [self.view addSubview:MDSharedCenter.sharedCenter.kwUIManager.filterGlobalView];
    
    [self.view addSubview:MDSharedCenter.sharedCenter.kwUIManager.mainMenuView];
    
    [self.view addSubview:MDSharedCenter.sharedCenter.kwUIManager.smiliesStateText];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    MDSharedCenter.sharedCenter.recorder = nil;
    MDSharedCenter.sharedCenter.faceBeautyCaptureEffect = nil;
    MDSharedCenter.sharedCenter.LUTFilterCaptureEffect = nil;
    [(MDFilter *)MDFilter.sharedInstance dispose];
}

- (void)shouldChangeToBack {
    _recorder.preferredDevicePosition = AVCaptureDevicePositionBack;
}

- (void)showHint:(NSNotification *)notification {
    [self showHintWithMessage:notification.userInfo[@"hint"]];
}

- (void)viewWillAppear:(BOOL)animated {
    self.navigationController.navigationBarHidden = YES;
    [(MDFilter *)MDFilter.sharedInstance dispose];
    [(MDFilter *)MDFilter.sharedInstance setup];
    [_recorder startCapturingWithCompletion:^(BOOL audioGranted, NSError *audioError, BOOL videoGranted, NSError *videoError) {
        if (videoError) {
            SHOW_ALERT(@"error", videoError.localizedDescription, @"ok");
            return;
        }
        if (!videoGranted) {
            SHOW_ALERT(@"warning", @"video not authorized", @"ok");
            return;
        }
        if (audioError) {
            SHOW_ALERT(@"error", audioError.localizedDescription, @"ok");
            return;
        }
        if (!audioGranted) {
            SHOW_ALERT(@"warning", @"audio not authorized", @"ok");
            return;
        }
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [_recorder stopCapturing];
    [(MDFilter *)MDFilter.sharedInstance dispose];
    [(MDFilter *)MDFilter.sharedInstance setup];
}

- (IBAction)closeButtonPressed:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)speedValueChanged:(UISegmentedControl *)sender {
    // 极慢 0.5，慢 0.75，正常 1.0，快 1.25，极快 1.5
    _speed = 0.5 + sender.selectedSegmentIndex * 0.25;
    if (_duetVideoPlayer.rate > 0) {
        _duetVideoPlayer.rate = 1.0 / _speed;
    }
}

- (IBAction)startRecordingTouchDown:(UIButton *)sender {
    if (_startButton.selected) {
        [self stopRecordingWithCompletion:nil];
    } else {
        [self startRecording];
    }
}

/// 包含 UI 操作，必须在主线程调用
- (void)startRecording {
    if (_recorder.recordedClipsRealDuration >= DefaultMaxRecordingDuration) {
        [self performSegueWithIdentifier:@"ShowMDEditorViewController" sender:self];
        return;
    }
    MSVClipConfiguration *config = [MSVClipConfiguration defaultConfiguration];
    config.speed = _speed;
    if (_recorder.backgroundAudioConfiguration) {
        config.volume = 0;
    } else {
        config.volume = 1;
    }
    NSError *error;
    if (![_recorder startRecordingWithClipConfiguration:config error:&error]) {
        SHOW_ERROR_ALERT;
        return;
    }
    _duetVideoPlayer.rate = 1.0 / _speed;
    _startButton.selected = YES;
    _topRightCollection.hidden = YES;
    _speedSegment.hidden = YES;
    _closeButton.hidden = YES;
    _cancelDoneCollection.hidden = YES;
    _backgroundMusicCollection.hidden = YES;
    _importMediaCollection.hidden = YES;
    [_progressBar addProgressView];
    [_progressBar startShining];
}

/// 包含 UI 操作，必须在主线程调用
- (void)stopRecordingWithCompletion:(void(^)(void))completion {
    [self turnToRecordingStoppedUI];
    [_duetVideoPlayer pause];
    MovieousWeakSelf
    [_recorder finishRecordingWithCompletionHandler:^(MSVMainTrackClip *clip, NSError *error) {
        if (error) {
            SHOW_ERROR_ALERT;
            return;
        }
        if (wSelf.duetVideoURL) {
            clip.scalingMode = MovieousScalingModeAspectFill;
            clip.destDisplayFrame = CGRectMake(0, 0, 360, 640);
            clip.volume = 0;
        }
        if (completion) {
            completion();
        }
    }];
}

- (void)turnToRecordingStoppedUI {
    _startButton.selected = NO;
    _cancelDoneCollection.hidden = NO;
    _topRightCollection.hidden = NO;
    _closeButton.hidden = NO;
    [_progressBar stopShining];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([touch.view isDescendantOfView:_beautyFilterView] ||
        [touch.view isDescendantOfView:_stickerView] ||
        [touch.view isDescendantOfView:MDSharedCenter.sharedCenter.kwUIManager.beautifyFilterView] ||
        [touch.view isDescendantOfView:MDSharedCenter.sharedCenter.kwUIManager.stickerMenuView] ||
        [touch.view isDescendantOfView:MDSharedCenter.sharedCenter.kwUIManager.distortionMenuView] ||
        [touch.view isDescendantOfView:MDSharedCenter.sharedCenter.kwUIManager.beautifyNewView] ||
        [touch.view isDescendantOfView:MDSharedCenter.sharedCenter.kwUIManager.slideBeautifyMenuView] ||
        [touch.view isDescendantOfView:MDSharedCenter.sharedCenter.kwUIManager.filterGlobalView] ||
        [touch.view isDescendantOfView:MDSharedCenter.sharedCenter.kwUIManager.mainMenuView] ||
        [touch.view isDescendantOfView:MDSharedCenter.sharedCenter.kwUIManager.smiliesStateText]
        ) {
        return NO;
    }
    return YES;
}

- (IBAction)discardButtonPressed:(UIButton *)sender {
    if (_progressBar.lastProgressStyle == MDProgressBarProgressStyleDelete) {
        NSError *error;
        if (![_recorder discardLastClipWithError:&error]) {
            SHOW_ERROR_ALERT;
            return;
        }
        [_progressBar deleteLastProgress];
        [_duetVideoPlayer seekToTime:CMTimeMakeWithSeconds(_recorder.recordedClipsRealDuration, 1000) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
        if (_recorder.draft.mainTrackClips.count == 0) {
            if (!_duetVideoURL) {
                _backgroundMusicCollection.hidden = NO;
            }
            _importMediaCollection.hidden = NO;
            _cancelDoneCollection.hidden = YES;
        }
    } else {
        _progressBar.lastProgressStyle = MDProgressBarProgressStyleDelete;
    }
}

- (IBAction)switchCameraButtonPressed:(UIButton *)sender {
    [_recorder switchCamera];
//    [(MDFilter *)MDFilter.sharedInstance onCameraChanged];
}

- (IBAction)speedButtonPressed:(UIButton *)sender {
    _speedSegment.hidden = !_speedSegment.hidden;
    if (!_speedSegment.hidden) {
        _beautyFilterView.hidden = YES;
        _stickerView.hidden = YES;
        _bottomCollection.hidden = NO;
        if (_recorder.draft.mainTrackClips.count == 0) {
            _cancelDoneCollection.hidden = YES;
        } else {
            _importMediaCollection.hidden = YES;
        }
    }
}

- (IBAction)beautifyButtonPressed:(UIButton *)sender {
    if (MDGlobalSettings.sharedInstance.vendorType == VendorTypeTuSDK) {
        SHOW_ALERT(@"提示", @"此供应商暂不支持美化功能", @"好的");
        return;
    }
    if (MDGlobalSettings.sharedInstance.vendorType == VendorTypeKiwi) {
        [MDSharedCenter.sharedCenter.kwUIManager popAllView];
        [MDSharedCenter.sharedCenter.kwUIManager pushFilterGlobalView:YES];
        _bottomCollection.hidden = YES;
    } else {
        _bottomCollection.hidden = !_beautyFilterView.hidden;
        _beautyFilterView.hidden = !_beautyFilterView.hidden;
        if (!_beautyFilterView.hidden) {
            _stickerView.hidden = YES;
            _speedSegment.hidden = YES;
        } else {
            if (_recorder.draft.mainTrackClips.count == 0) {
                _cancelDoneCollection.hidden = YES;
            } else {
                _importMediaCollection.hidden = YES;
            }
        }
    }
}

- (IBAction)countdownButtonPressed:(UIButton *)sender {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:@"倒计时结束后将开始拍摄" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self->_topRightCollection.hidden = YES;
        self->_speedSegment.hidden = YES;
        self->_closeButton.hidden = YES;
        self->_importMediaCollection.hidden = YES;
        self->_backgroundMusicCollection.hidden = YES;
        self->_cancelDoneCollection.hidden = YES;
        self->_countDownLabel.hidden = NO;
        self.view.userInteractionEnabled = NO;
        [self animateCountDownWithRemaining:3];
    }]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)animateCountDownWithRemaining:(NSInteger)remaining {
    if (remaining == 0) {
        self.view.userInteractionEnabled = YES;
        [self startRecording];
    } else {
        _countDownLabel.text = [NSString stringWithFormat:@"%ld", (long)remaining];
        CGFloat fontSize = _countDownLabel.font.pointSize;
        _countDownLabel.transform = CGAffineTransformMakeScale(1.0 / fontSize, 1.0 / fontSize);
        [UIView animateWithDuration:0.2 animations:^{
            self->_countDownLabel.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:0.2 animations:^{
                    self->_countDownLabel.transform = CGAffineTransformMakeScale(1.0 / fontSize, 1.0 / fontSize);
                } completion:^(BOOL finished) {
                    [self animateCountDownWithRemaining:remaining - 1];
                }];
            });
        }];
    }
}


- (IBAction)viewTapped:(UITapGestureRecognizer *)sender {
    _beautyFilterView.hidden = YES;
    _bottomCollection.hidden = NO;
    if (_startButton.selected) {
        _cancelDoneCollection.hidden = YES;
        _importMediaCollection.hidden = YES;
    } else {
        if (_recorder.draft.mainTrackClips.count == 0) {
            _cancelDoneCollection.hidden = YES;
        } else {
            _importMediaCollection.hidden = YES;
        }
    }
    if (MDGlobalSettings.sharedInstance.vendorType == VendorTypeKiwi) {
        [MDSharedCenter.sharedCenter.kwUIManager popAllView];
    }
    _stickerView.hidden = YES;
}

- (void)recorder:(MSVRecorder *)recorder didErrorOccurred:(NSError *)error {
    SHOW_ERROR_ALERT;
}

- (void)recorder:(MSVRecorder *)recorder currentClipDurationDidUpdated:(NSTimeInterval)currentClipDuration {
    NSTimeInterval maxDuration = DefaultMaxRecordingDuration;
    if (_duetVideoPlayer) {
        maxDuration = CMTimeGetSeconds(_duetVideoPlayer.currentItem.duration);
    }
    [_progressBar setLastProgressToWidth:_progressBar.frame.size.width * currentClipDuration / _speed / maxDuration];
    if (!recorder.recording) {
        return;
    }
    if (recorder.recordedClipsRealDuration + currentClipDuration / _speed >= maxDuration) {
        MovieousWeakSelf
        [self stopRecordingWithCompletion:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [wSelf performSegueWithIdentifier:@"ShowMDEditorViewController" sender:wSelf];
            });
        }];
    }
}

- (void)recorder:(MSVRecorder *)recorder didFocusAtPoint:(CGPoint)point {
    return;
}

- (void)recorder:(MSVRecorder *)recorder didPlayBackgroundAudioError:(NSError *)error {
    return;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"ShowMDEditorViewController"]) {
        MSVDraft *draft;
        // 照片直接选择的
        if ([sender isKindOfClass:MSVDraft.class]) {
            draft = (MSVDraft *)sender;
        } else {
        // recorder 中的
            // 复制一份，保证编辑操作不会影响到 recorder 的 draft
            draft = [_recorder.draft copy];
        }
        for (MSVMixTrackClip *mixTrackClip in draft.mixTrackClips) {
            mixTrackClip.ID = @"music";
        }
        if (_duetVideoURL) {
            NSError *error;
            MSVMixTrackClip *mixTrackClip = [MSVMixTrackClip mixTrackClipWithType:MSVClipTypeAV URL:_duetVideoURL startTimeAtMainTrack:0 error:&error];
            if (error) {
                [draft cancelChangeTransaction];
                SHOW_ERROR_ALERT;
                return;
            }
            mixTrackClip.ID = @"duet";
            mixTrackClip.destDisplayFrame = CGRectMake(360, 0, 360, 640);
            mixTrackClip.scalingMode = MovieousScalingModeAspectFill;
            [draft updateMixTrackClips:@[mixTrackClip] error:&error];
            if (error) {
                [draft cancelChangeTransaction];
                SHOW_ERROR_ALERT;
                return;
            }
        }
        ((MDEditorViewController *)(segue.destinationViewController)).draft = draft;
    } else if ([segue.identifier isEqualToString:@"ShowMusicViewController"]) {
        MDRecorderMusicViewController *destController = (MDRecorderMusicViewController *)segue.destinationViewController;
        destController.delegate = self;
    }
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

// 获取相册中最新的一个视频的封面
- (void)getFirstMovieFromPhotoAlbum {
    CGSize size = _importMediaView.frame.size;
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if (status == PHAuthorizationStatusAuthorized) {
            PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
            fetchOptions.includeHiddenAssets = NO;
            fetchOptions.includeAllBurstAssets = NO;
            fetchOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"modificationDate" ascending:NO],
                                             [NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
            PHFetchResult *fetchResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeVideo options:fetchOptions];
            
            NSMutableArray *assets = [[NSMutableArray alloc] init];
            [fetchResult enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                [assets addObject:obj];
            }];
            
            if (assets.count > 0) {
                PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
                [[PHImageManager defaultManager] requestImageForAsset:assets[0] targetSize:size contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage *result, NSDictionary *info) {
                    // 设置的 options 可能会导致该回调调用两次，第一次返回你指定尺寸的图片，第二次将会返回原尺寸图片
                    if ([[info valueForKey:@"PHImageResultIsDegradedKey"] integerValue] == 0){
                        // Do something with the regraded image
                        dispatch_async(dispatch_get_main_queue(), ^{
                            self->_importMediaView.image = result;
                        });
                    } else {
                        // Do something with the FULL SIZED image
                    }
                }];
            }
        }
    }];
}

- (void)controller:(id)controller didSelectMusicPath:(NSString *)musicPath {
    NSError *error;
    if (musicPath) {
        MSVRecorderBackgroundAudioConfiguration *configuration = [MSVRecorderBackgroundAudioConfiguration backgroundAudioConfigurationWithURL:[NSURL fileURLWithPath:musicPath] error:&error];
        if (!configuration) {
            SHOW_ERROR_ALERT;
            return;
        }
        if (![_recorder setBackgroundAudioWithConfiguration:configuration error:&error]) {
            SHOW_ERROR_ALERT;
            return;
        }
        
        _backgroundMusicLabel.text = [musicPath componentsSeparatedByString:@"/"].lastObject;
    } else {
        [_recorder setBackgroundAudioWithConfiguration:nil error:&error];
        if (error) {
            SHOW_ERROR_ALERT;
            return;
        }
        _backgroundMusicLabel.text = @"背景音乐";
    }
}

- (void)dismissTipLabel {
    self.tipLabel.hidden = YES;
}

- (void)showHintWithMessage:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.tipLabel.hidden = NO;
        self.tipLabel.text = message;
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(dismissTipLabel) object:nil];
        [self performSelector:@selector(dismissTipLabel) withObject:nil afterDelay:3 ];
    });
}

- (IBAction)uploadButtonPressed:(UIButton *)sender {
    UIImagePickerController *controller = [[UIImagePickerController alloc] init];
    controller.mediaTypes = @[(NSString *)kUTTypeImage, (NSString *)kUTTypeMovie];
    controller.allowsEditing = YES;
    controller.delegate = self;
    controller.videoQuality = UIImagePickerControllerQualityTypeHigh;
    [self presentViewController:controller animated:YES completion:nil];
}

- (IBAction)stickerButtonPressed:(UIButton *)sender {
    if (MDGlobalSettings.sharedInstance.vendorType == VendorTypeNone) {
        SHOW_ALERT(@"提示", @"需要选择一个特效供应商才能使用贴纸特效", @"好的");
        return;
    }
    if (MDGlobalSettings.sharedInstance.vendorType == VendorTypeKiwi) {
        [MDSharedCenter.sharedCenter.kwUIManager pushmainMenuView:YES];
    } else {
        _stickerView.hidden = NO;
    }
    _bottomCollection.hidden = YES;
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey, id> *)info {
    //判断是照片 or 视频
    NSError *error;
    MSVDraft *draft = [_recorder.draft copy];
    MSVMainTrackClip *clip;
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    
    if ([mediaType isEqualToString:(NSString *)kUTTypeImage]) {
        
        //图片
        
        UIImage *theImage = nil;
        
        //判断照片是否允许修改
        
        if ([picker allowsEditing]) {
            
            //获取编辑后的照片
            
            theImage = [info objectForKey:UIImagePickerControllerEditedImage];
            
        }else{
            
            theImage = [info objectForKey:UIImagePickerControllerOriginalImage];
            
        }
        clip = [MSVMainTrackClip mainTrackClipWithImage:theImage duration:3 error:&error];
        if (error) {
            SHOW_ERROR_ALERT;
            return;
        }
    } else if ([mediaType isEqualToString:(NSString *)kUTTypeMovie]){
        
        //视频
        
        //获取视频url
        
        NSURL *mediaUrl = [info objectForKey:UIImagePickerControllerMediaURL];
        clip = [MSVMainTrackClip mainTrackClipWithType:MSVClipTypeAV URL:mediaUrl error:&error];
        if (error) {
            SHOW_ERROR_ALERT;
            return;
        }
    }
    if (_duetVideoURL) {
        clip.scalingMode = MovieousScalingModeAspectFill;
        clip.destDisplayFrame = CGRectMake(0, 0, 360, 640);
        if (clip.type == MSVClipTypeAV) {
            clip.volume = 0;
        }
    }
    [draft updateMainTrackClips:@[clip] error:&error];
    if (error) {
        SHOW_ERROR_ALERT;
        return;
    }
    [picker dismissViewControllerAnimated:YES completion:nil];
    [self performSegueWithIdentifier:@"ShowMDEditorViewController" sender:draft];
}

@end
