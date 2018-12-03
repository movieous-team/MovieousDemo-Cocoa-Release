//
//  RecorderViewController.m
//  MovieousDemo
//
//  Created by Chris Wang on 2018/10/4.
//  Copyright © 2018 Movieous Team. All rights reserved.
//

#import "RecorderViewController.h"
#import <MovieousShortVideo/MovieousShortVideo.h>
#import "MSVProgressBar.h"
#import "EditorViewController.h"
#import <Photos/Photos.h>
#import "RecorderMusicViewController.h"
#import "FUManager.h"
#import <FUAPIDemoBar/FUAPIDemoBar.h>
#import <CoreServices/CoreServices.h>
#import "STManager.h"

@interface RecorderViewController ()
<
MSVRecorderDelegate,
RecorderMusicViewControllerDelegate,
FUAPIDemoBarDelegate,
UIImagePickerControllerDelegate,
UINavigationControllerDelegate
>

@property (strong, nonatomic) IBOutlet MSVProgressBar *progressBar;
@property (strong, nonatomic) IBOutlet UIButton *discardButton;
@property (strong, nonatomic) IBOutlet UIButton *completeButton;
@property (strong, nonatomic) IBOutlet UIButton *uploadButton;
@property (strong, nonatomic) IBOutlet UILabel *uploadLabel;
@property (strong, nonatomic) IBOutlet UILabel *backgroundAudioLabel;
@property (strong, nonatomic) IBOutlet UIImageView *backgroundAudioIcon;
@property (strong, nonatomic) IBOutlet UISegmentedControl *speedSegment;
@property (strong, nonatomic) IBOutlet UIView *bottomContainerView;
@property (strong, nonatomic) IBOutlet UIView *topRightContainerView;
@property (strong, nonatomic) IBOutlet FUAPIDemoBar *demoBar;
@property (strong, nonatomic) IBOutlet UILabel *tipLabel;
@property (strong, nonatomic) IBOutlet UIButton *recordButton;
@property (strong, nonatomic) IBOutlet UIView *effectView;

@end

@implementation RecorderViewController {
    MSVRecorder *_recorder;
    float _speed;
    int _FUParamsSaveIndex;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _FUParamsSaveIndex = -1;
    // 避免下个页面的返回键出现 <Back 字样
    self.navigationItem.title = @"";
    _speed = 1;
    // Do any additional setup after loading the view.
    MSVRecorderAudioConfiguration *audioConfiguration = [MSVRecorderAudioConfiguration defaultConfiguration];
    MSVRecorderVideoConfiguration *videoConfiguration = [MSVRecorderVideoConfiguration defaultConfiguration];
    videoConfiguration.cameraResolution = AVCaptureSessionPreset1280x720;
    videoConfiguration.cameraPosition = AVCaptureDevicePositionFront;
    NSError *error;
    _recorder = [[MSVRecorder alloc] initWithAudioConfiguration:audioConfiguration videoConfiguration:videoConfiguration error:&error];
    if (error) {
        SHOW_ERROR_ALERT;
        return;
    }
    // 设置最大录制长度
    _recorder.maxDuration = 10;
    // 设置录制事件回调
    _recorder.delegate = self;
    // 将预览视图插入视图栈中
    _recorder.preview.frame = self.view.frame;
    [self.view insertSubview:_recorder.preview atIndex:0];
    [[FUManager shareManager] loadFilter] ;
    [[FUManager shareManager] setAsyncTrackFaceEnable:YES];
    [self demoBarSetBeautyDefultParams];
    [self getFirstMovieFromPhotoAlbum];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showHint:) name:kShowHintNotification object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[FUManager shareManager] destoryItems];
    [[STManager sharedManager] cancelStickerAndObjectTrack];
}

- (void)showHint:(NSNotification *)notification {
    [self showHintWithMessage:notification.userInfo[@"hint"]];
}

- (void)viewWillAppear:(BOOL)animated {
    if (_FUParamsSaveIndex >= 0) {
        [[FUManager shareManager] restoreParamsSet:_FUParamsSaveIndex];
    }
    self.navigationController.navigationBarHidden = YES;
    [_recorder startCapturingWithCompletionHandler:^(BOOL audioGranted, NSError *audioError, BOOL videoGranted, NSError *videoError) {
        if (videoError) {
            SHOW_ALERT(@"error", videoError.localizedDescription, @"ok");
            return;
        }
        if (!videoGranted) {
            SHOW_ALERT(@"warning", @"video not authorized", @"ok");
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self syncBeautyParams];
        });
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

- (void)viewDidDisappear:(BOOL)animated {
    [_recorder stopCapturing];
    if (_FUParamsSaveIndex >= 0) {
        [[FUManager shareManager] updateSavedParamsSet:_FUParamsSaveIndex];
    } else {
        _FUParamsSaveIndex = (int)[FUManager.shareManager saveParamsSet];
    }
}

- (IBAction)dismissControllerPressed:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)speedValueChanged:(UISegmentedControl *)sender {
    _speed = 0.5 + sender.selectedSegmentIndex * 0.25;
}

- (void)demoBarSetBeautyDefultParams {
    _demoBar.delegate = nil ;
    _demoBar.skinDetect = [FUManager shareManager].skinDetectEnable;
    _demoBar.heavyBlur = [FUManager shareManager].blurShape ;
    _demoBar.blurLevel = [FUManager shareManager].blurLevel ;
    _demoBar.colorLevel = [FUManager shareManager].whiteLevel ;
    _demoBar.redLevel = [FUManager shareManager].redLevel;
    _demoBar.eyeBrightLevel = [FUManager shareManager].eyelightingLevel ;
    _demoBar.toothWhitenLevel = [FUManager shareManager].beautyToothLevel ;
    _demoBar.faceShape = [FUManager shareManager].faceShape ;
    _demoBar.enlargingLevel = [FUManager shareManager].enlargingLevel ;
    _demoBar.thinningLevel = [FUManager shareManager].thinningLevel ;
    _demoBar.enlargingLevel_new = [FUManager shareManager].enlargingLevel_new ;
    _demoBar.thinningLevel_new = [FUManager shareManager].thinningLevel_new ;
    _demoBar.chinLevel = [FUManager shareManager].jewLevel ;
    _demoBar.foreheadLevel = [FUManager shareManager].foreheadLevel ;
    _demoBar.noseLevel = [FUManager shareManager].noseLevel ;
    _demoBar.mouthLevel = [FUManager shareManager].mouthLevel ;
    
    _demoBar.filtersDataSource = [FUManager shareManager].filtersDataSource ;
    _demoBar.beautyFiltersDataSource = [FUManager shareManager].beautyFiltersDataSource ;
    _demoBar.filtersCHName = [FUManager shareManager].filtersCHName ;
    _demoBar.selectedFilter = [FUManager shareManager].selectedFilter ;
    _demoBar.selectedFilterLevel = [FUManager shareManager].selectedFilterLevel;
    
    _demoBar.delegate = self;
}

- (CVPixelBufferRef)recorder:(MSVRecorder *)recorder didGetPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    [FUManager.shareManager renderItemsToPixelBuffer:pixelBuffer];
    pixelBuffer = [STManager.sharedManager processPixelBuffer:pixelBuffer];
    return pixelBuffer;
}

- (IBAction)startRecordingTouchDown:(UIButton *)sender {
    _recordButton.selected = YES;
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
    _backgroundAudioLabel.hidden = YES;
    _backgroundAudioIcon.hidden = YES;
    _uploadButton.hidden = YES;
    _uploadLabel.hidden = YES;
    _discardButton.hidden = NO;
    _completeButton.hidden = NO;
    [_progressBar addProgressView];
    [_progressBar startShining];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([touch.view isDescendantOfView:_demoBar] ||
        [touch.view isDescendantOfView:_effectView]) {
        return NO;
    }
    return YES;
}

- (IBAction)finishRecordingTouchUpInside:(UIButton *)sender {
    [self finishRecording];
}

- (IBAction)finishRecordingTouchUpOutside:(UIButton *)sender {
    [self finishRecording];
}

- (IBAction)beautifyButtonPressed:(UITapGestureRecognizer *)sender {
    _demoBar.hidden = !_demoBar.hidden;
    [_demoBar hiddeTopView];
    _bottomContainerView.hidden = !_demoBar.hidden;
    if (!_demoBar.hidden) {
        _effectView.hidden = YES;
        _speedSegment.hidden = YES;
    }
}

- (IBAction)discardButtonPressed:(UIButton *)sender {
    if (_progressBar.lastProgressStyle == MSVProgressBarProgressStyleDelete) {
        [_recorder discardLastClip];
        [_progressBar deleteLastProgress];
    } else {
        _progressBar.lastProgressStyle = MSVProgressBarProgressStyleDelete;
    }
    if (_recorder.draft.mainTrackClips.count == 0) {
        _backgroundAudioLabel.hidden = NO;
        _backgroundAudioIcon.hidden = NO;
        _uploadButton.hidden = NO;
        _uploadLabel.hidden = NO;
        _discardButton.hidden = YES;
        _completeButton.hidden = YES;
    }
}

- (IBAction)countdownButtonPressed:(UITapGestureRecognizer *)sender {
}

- (IBAction)speedButtonPressed:(UITapGestureRecognizer *)sender {
    _speedSegment.hidden = !_speedSegment.hidden;
    if (!_speedSegment.hidden) {
        _demoBar.hidden = YES;
        _effectView.hidden = YES;
        _bottomContainerView.hidden = NO;
    }
}

- (IBAction)switchCameraButtonPressed:(UITapGestureRecognizer *)sender {
    NSError *error;
    if (![_recorder switchCameraWithError:&error]) {
        SHOW_ERROR_ALERT;
        return;
    }
    /**切换摄像头要调用此函数*/
    [[FUManager shareManager] onCameraChange];
}

- (IBAction)viewTapped:(UITapGestureRecognizer *)sender {
    [_demoBar hiddeTopView];
    _demoBar.hidden = YES;
    _bottomContainerView.hidden = NO;
    _effectView.hidden = YES;
}

- (void)finishRecording {
    _recordButton.selected = NO;
    [_progressBar stopShining];
    [_recorder finishRecordingWithCompletionHandler:^(MSVMainTrackClip *clip, NSError *error) {
        if (error) {
            SHOW_ERROR_ALERT;
        }
    }];
}

- (void)recorder:(MSVRecorder *)recorder currentClipDurationDidUpdated:(NSTimeInterval)currentClipDuration {
    [_progressBar setLastProgressToWidth:_progressBar.frame.size.width * currentClipDuration / _recorder.maxDuration];
}

- (void)recorder:(MSVRecorder *)recorder didFocusAtPoint:(CGPoint)point {
    return;
}

- (void)recorder:(MSVRecorder *)recorder didPlayBackgroundAudioError:(NSError *)error {
    return;
}

- (void)recorderDidReachMaxDuration:(MSVRecorder *)recorder {
    [self performSegueWithIdentifier:@"ShowEditorViewController" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"ShowEditorViewController"]) {
        if ([sender isKindOfClass:MSVDraft.class]) {
            EditorViewController *destController = (EditorViewController *)segue.destinationViewController;
            destController.draft = (MSVDraft *)sender;
        } else {
            EditorViewController *destController = (EditorViewController *)segue.destinationViewController;
            destController.draft = _recorder.draft;
        }
    } else if ([segue.identifier isEqualToString:@"ShowMusicViewController"]) {
        RecorderMusicViewController *destController = (RecorderMusicViewController *)segue.destinationViewController;
        destController.delegate = self;
    }
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

// 获取相册中最新的一个视频的封面
- (void)getFirstMovieFromPhotoAlbum {
    CGSize size = self->_uploadButton.frame.size;
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
                            [self->_uploadButton setBackgroundImage:result forState:UIControlStateNormal];
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
        MSVBackgroundAudioConfiguration *configuration = [MSVBackgroundAudioConfiguration backgroundAudioConfigurationWithURL:[NSURL fileURLWithPath:musicPath] error:&error];
        if (!configuration) {
            SHOW_ERROR_ALERT;
            return;
        }
        if (![_recorder setBackgroundAudioWithConfiguration:configuration error:&error]) {
            SHOW_ERROR_ALERT;
            return;
        }
        
        _backgroundAudioLabel.text = [musicPath componentsSeparatedByString:@"/"].lastObject;
    } else {
        [_recorder setBackgroundAudioWithConfiguration:nil error:&error];
        if (error) {
            SHOW_ERROR_ALERT;
            return;
        }
        _backgroundAudioLabel.text = @"背景音乐";
    }
}

// 美颜参数改变
- (void)demoBarBeautyParamChanged {
    [self syncBeautyParams];
}

- (void)dismissTipLabel {
    self.tipLabel.hidden = YES;
}

- (void)syncBeautyParams {
    [FUManager shareManager].skinDetectEnable = _demoBar.skinDetect;
    [FUManager shareManager].blurShape = _demoBar.heavyBlur;
    [FUManager shareManager].blurLevel = _demoBar.blurLevel ;
    [FUManager shareManager].whiteLevel = _demoBar.colorLevel;
    [FUManager shareManager].redLevel = _demoBar.redLevel;
    [FUManager shareManager].eyelightingLevel = _demoBar.eyeBrightLevel;
    [FUManager shareManager].beautyToothLevel = _demoBar.toothWhitenLevel;
    [FUManager shareManager].faceShape = _demoBar.faceShape;
    [FUManager shareManager].enlargingLevel = _demoBar.enlargingLevel;
    [FUManager shareManager].thinningLevel = _demoBar.thinningLevel;
    [FUManager shareManager].enlargingLevel_new = _demoBar.enlargingLevel_new;
    [FUManager shareManager].thinningLevel_new = _demoBar.thinningLevel_new;
    [FUManager shareManager].jewLevel = _demoBar.chinLevel;
    [FUManager shareManager].foreheadLevel = _demoBar.foreheadLevel;
    [FUManager shareManager].noseLevel = _demoBar.noseLevel;
    [FUManager shareManager].mouthLevel = _demoBar.mouthLevel;
    
    [FUManager shareManager].selectedFilter = _demoBar.selectedFilter ;
    [FUManager shareManager].selectedFilterLevel = _demoBar.selectedFilterLevel;
}

// 显示提示语
-(void)demoBarShouldShowMessage:(NSString *)message {
    [self showHintWithMessage:message];
}

- (void)showHintWithMessage:(NSString *)message {
    self.tipLabel.hidden = NO;
    self.tipLabel.text = message;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(dismissTipLabel) object:nil];
    [self performSelector:@selector(dismissTipLabel) withObject:nil afterDelay:3 ];
}

- (IBAction)uploadButtonPressed:(UIButton *)sender {
    UIImagePickerController *controller = [[UIImagePickerController alloc] init];
    controller.mediaTypes = @[(NSString *)kUTTypeImage, (NSString *)kUTTypeMovie];
    controller.allowsEditing = YES;
    controller.delegate = self;
    controller.videoQuality = UIImagePickerControllerQualityTypeHigh;
    [self presentViewController:controller animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey, id> *)info {
    //判断是照片 or 视频
    NSError *error;
    MSVDraft *draft = [MSVDraft new];
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
        clip = [MSVMainTrackClip mainTrackClipWithType:MSVMainTrackClipTypeAV URL:mediaUrl error:&error];
        if (error) {
            SHOW_ERROR_ALERT;
            return;
        }
    }
    [draft updateMainTrackClips:[draft.mainTrackClips arrayByAddingObject:clip] error:&error];
    if (error) {
        SHOW_ERROR_ALERT;
        return;
    }
    [picker dismissViewControllerAnimated:YES completion:nil];
    [self performSegueWithIdentifier:@"ShowEditorViewController" sender:draft];
}

- (IBAction)propertiesButtonPressed:(UIButton *)sender {
    _effectView.hidden = NO;
}

@end
