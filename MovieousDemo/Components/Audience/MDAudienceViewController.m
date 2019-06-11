//
//  MDAudienceViewController.m
//  MovieousDemo
//
//  Created by Chris Wang on 2018/10/2.
//  Copyright © 2018 Movieous Team. All rights reserved.
//

#import "MDAudienceViewController.h"
#import <MovieousPlayer/MovieousPlayer.h>
#import "MDShortVideoMetadata.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import "MDRecorderViewController.h"

@interface MDAudienceViewController ()
<
UIScrollViewDelegate,
MovieousPlayerControllerDelegate,
NSURLSessionDownloadDelegate
>

@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet UIView *creationPanel;
@property (strong, nonatomic) IBOutlet UIView *sharePanel;
@property (strong, nonatomic) IBOutlet UILabel *authorNameLabel;
@property (strong, nonatomic) IBOutlet UILabel *descLabel;
@property (strong, nonatomic) IBOutlet UIImageView *playImage;

@end

@implementation MDAudienceViewController {
    NSMutableArray<MDShortVideoMetadata *> *_metadatas;
    NSUInteger _currentIndex;
    UIImageView *_currentCover;
    UIImageView *_upperCover;
    UIImageView *_middleCover;
    UIImageView *_lowerCover;
    MovieousPlayerController *_currentPlayer;
    MovieousPlayerController *_upperPlayer;
    MovieousPlayerController *_middlePlayer;
    MovieousPlayerController *_lowerPlayer;
    NSRecursiveLock *_operationLock;
    BOOL _viewAppear;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    if (@available(iOS 11.0, *)) {
        _scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    _operationLock = [NSRecursiveLock new];
    _metadatas = [NSMutableArray array];
    [self refreshMetadatas];
}

- (void)viewDidAppear:(BOOL)animated {
    _viewAppear = YES;
    [_currentPlayer play];
    _playImage.hidden = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    self.navigationController.navigationBarHidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    _viewAppear = NO;
    [_currentPlayer pause];
    _creationPanel.hidden = YES;
    _sharePanel.hidden = YES;
}

- (IBAction)shareButtonPressed:(UIButton *)sender {
    _creationPanel.hidden = YES;
    _sharePanel.hidden = NO;
}

- (IBAction)createButtonPressed:(UIButton *)sender {
    _creationPanel.hidden = NO;
    _sharePanel.hidden = YES;
}

- (IBAction)closeCreationPanelButtonPressed:(id)sender {
    _creationPanel.hidden = YES;
}

- (IBAction)duetButtonPressed:(UIButton *)sender {
    _creationPanel.hidden = YES;
    [SVProgressHUD showWithStatus:@"准备开始合拍"];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:NSURLSessionConfiguration.defaultSessionConfiguration delegate:self delegateQueue:NSOperationQueue.mainQueue];
    [[session downloadTaskWithURL:_currentPlayer.URL] resume];
    [session finishTasksAndInvalidate];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error {
    [SVProgressHUD dismiss];
    if (error) {
        SHOW_ERROR_ALERT;
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    NSError *error;
    NSString *dirPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"MovieousShortVideoDuet"];
    [NSFileManager.defaultManager createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:&error];
    if (error) {
        SHOW_ERROR_ALERT;
        return;
    }
    NSURL *fileURL = [NSURL fileURLWithPath:[dirPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%f.mp4", NSDate.date.timeIntervalSince1970]]];
    [NSFileManager.defaultManager moveItemAtURL:location toURL:fileURL error:&error];
    if (error) {
        SHOW_ERROR_ALERT;
        return;
    }
    [self performSegueWithIdentifier:@"MDRecorderViewController" sender:fileURL];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    [SVProgressHUD showProgress:(float)totalBytesWritten / (float)totalBytesExpectedToWrite status:@"准备开始合拍"];
}

- (IBAction)viewTapped:(UITapGestureRecognizer *)sender {
    if (_creationPanel.hidden == NO || _sharePanel.hidden == NO) {
        _creationPanel.hidden = YES;
        _sharePanel.hidden = YES;
    } else {
        if (_currentPlayer.playState >= MPPlayerStatePaused) {
            [_currentPlayer play];
            _playImage.hidden = YES;
        } else {
            [_currentPlayer pause];
            _playImage.hidden = NO;
        }
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([touch.view isDescendantOfView:_creationPanel] || [touch.view isDescendantOfView:_sharePanel]) {
        return NO;
    }
    return YES;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [_operationLock lock];
    CGFloat offset = scrollView.contentOffset.y;
    if (_currentIndex == 0 && offset < 0) {
        [self refreshMetadatas];
    }
    [_operationLock unlock];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    [_operationLock lock];
    CGFloat offset = scrollView.contentOffset.y;
    CGRect frame = self.view.frame;
    if (_currentPlayer == _middlePlayer && offset <= 0) {
        [_currentPlayer pause];
        _currentPlayer.currentTime = 0;
        _currentCover.hidden = NO;
        _currentPlayer = _upperPlayer;
        _currentCover = _upperCover;
        _currentIndex--;
        if (_currentIndex > 0) {
            [_lowerPlayer.playerView removeFromSuperview];
            _lowerPlayer = _middlePlayer;
            _lowerPlayer.playerView.frame = CGRectMake(0, 2 * frame.size.height, frame.size.width, frame.size.height);
            _middlePlayer = _upperPlayer;
            _middlePlayer.playerView.frame = CGRectMake(0, frame.size.height, frame.size.width, frame.size.height);
            _upperPlayer = [self generatePlayer:[NSURL URLWithString:_metadatas[_currentIndex - 1].videoURL]];
            [_upperPlayer prepareToPlay];
            _upperPlayer.playerView.frame = frame;
            [self.scrollView addSubview:_upperPlayer.playerView];
            
            [_lowerCover removeFromSuperview];
            _lowerCover = _middleCover;
            _lowerCover.frame = CGRectMake(0, 2 * frame.size.height, frame.size.width, frame.size.height);
            _middleCover = _upperCover;
            _middleCover.frame = CGRectMake(0, frame.size.height, frame.size.width, frame.size.height);
            _upperCover = [UIImageView new];
            _upperCover.contentMode = UIViewContentModeScaleAspectFit;
            [_upperCover sd_setImageWithURL:[NSURL URLWithString:_metadatas[_currentIndex - 1].coverURL]];
            _upperCover.frame = frame;
            [self.scrollView addSubview:_upperCover];
            // 需要将其他状态都配置好之后再设置 contentOffset，因为设置 contentOffset 会同步重入 scrollViewDidScroll 方法，导致状态有问题
            _scrollView.contentOffset = CGPointMake(0, offset + frame.size.height);
        }
        _authorNameLabel.text = [NSString stringWithFormat:@"@%@", self->_metadatas[_currentIndex].authorNickName];
        _descLabel.text = self->_metadatas[_currentIndex].title;
        [_currentPlayer play];
        _playImage.hidden = YES;
    }
    
    if (_currentPlayer == _upperPlayer && offset >= frame.size.height) {
        [_currentPlayer pause];
        _currentPlayer.currentTime = 0;
        _currentCover.hidden = NO;
        _currentCover = _middleCover;
        _currentPlayer = _middlePlayer;
        _currentIndex++;
        _authorNameLabel.text = [NSString stringWithFormat:@"@%@", self->_metadatas[_currentIndex].authorNickName];
        _descLabel.text = self->_metadatas[_currentIndex].title;
        [_currentPlayer play];
        _playImage.hidden = YES;
    }
    
    if (_currentPlayer == _lowerPlayer && offset <= frame.size.height) {
        [_currentPlayer pause];
        _currentPlayer.currentTime = 0;
        _currentCover.hidden = NO;
        _currentCover = _middleCover;
        _currentPlayer = _middlePlayer;
        _currentIndex--;
        _authorNameLabel.text = [NSString stringWithFormat:@"@%@", self->_metadatas[_currentIndex].authorNickName];
        _descLabel.text = self->_metadatas[_currentIndex].title;
        [_currentPlayer play];
        _playImage.hidden = YES;
    }
    
    if (_currentPlayer == _middlePlayer && offset >= 2 * frame.size.height) {
        [_currentPlayer pause];
        _currentPlayer.currentTime = 0;
        _currentCover.hidden = NO;
        _currentPlayer = _lowerPlayer;
        _currentCover = _lowerCover;
        _currentIndex++;
        if (_currentIndex < _metadatas.count - 1) {
            [_upperPlayer.playerView removeFromSuperview];
            _upperPlayer = _middlePlayer;
            _upperPlayer.playerView.frame = frame;
            _middlePlayer = _lowerPlayer;
            _middlePlayer.playerView.frame = CGRectMake(0, frame.size.height, frame.size.width, frame.size.height);
            _lowerPlayer = [self generatePlayer:[NSURL URLWithString:_metadatas[_currentIndex + 1].videoURL]];
            [_lowerPlayer prepareToPlay];
            _lowerPlayer.playerView.frame = CGRectMake(0, 2 * frame.size.height, frame.size.width, frame.size.height);
            [self.scrollView addSubview:_lowerPlayer.playerView];
            
            [_upperCover removeFromSuperview];
            _upperCover = _middleCover;
            _upperCover.frame = frame;
            _middleCover = _lowerCover;
            _middleCover.frame = CGRectMake(0, frame.size.height, frame.size.width, frame.size.height);
            _lowerCover = [UIImageView new];
            _lowerCover.contentMode = UIViewContentModeScaleAspectFit;
            [_lowerCover sd_setImageWithURL:[NSURL URLWithString:_metadatas[_currentIndex + 1].coverURL]];
            _lowerCover.frame = CGRectMake(0, 2 * frame.size.height, frame.size.width, frame.size.height);
            [self.scrollView addSubview:_lowerCover];
            // 需要将其他状态都配置好之后再设置 contentOffset，因为设置 contentOffset 会同步重入 scrollViewDidScroll 方法，导致状态有问题
            _scrollView.contentOffset = CGPointMake(0, offset - frame.size.height);
        }
        if (_currentIndex == _metadatas.count - 6) {
            [self getMoreMetadatas:0];
        }
        _authorNameLabel.text = [NSString stringWithFormat:@"@%@", self->_metadatas[_currentIndex].authorNickName];
        _descLabel.text = self->_metadatas[_currentIndex].title;
        [_currentPlayer play];
        _playImage.hidden = YES;
    }
    [_operationLock unlock];
}

- (MovieousPlayerController *)generatePlayer:(NSURL *)URL {
    MovieousPlayerOptions *options = [MovieousPlayerOptions defaultOptions];
    options.allowMixAudioWithOthers = NO;
    MovieousPlayerController *player = [MovieousPlayerController playerControllerWithURL:URL options:options];
    player.scalingMode = MPScalingModeAspectFit;
    player.delegate = self;
    player.loop = YES;
    player.interruptInBackground = YES;
    player.interruptionOperation = MPInterruptionOperationPause;
    return player;
}

- (void)refreshMetadatas {
    [self getRandomListWithCompletionHanler:^(NSMutableArray *metas, NSError *error) {
        if (!error) {
            self->_metadatas = metas;
            dispatch_async(dispatch_get_main_queue(), ^{
                self->_currentIndex = 0;
                self->_currentPlayer = nil;
                self->_currentCover = nil;
                [self->_upperPlayer.playerView removeFromSuperview];
                self->_upperPlayer = nil;
                [self->_upperCover removeFromSuperview];
                self->_upperCover = nil;
                [self->_middlePlayer.playerView removeFromSuperview];
                self->_middlePlayer = nil;
                [self->_middleCover removeFromSuperview];
                self->_middleCover = nil;
                [self->_lowerPlayer.playerView removeFromSuperview];
                self->_lowerPlayer = nil;
                [self->_lowerCover removeFromSuperview];
                self->_lowerCover = nil;
                
                CGRect frame = self.view.frame;
                
                self->_scrollView.contentSize = CGSizeMake(0, frame.size.height * (self->_metadatas.count < 3 ? self->_metadatas.count : 3));
                
                if (self->_metadatas.count <= 0) {
                    return;
                }
                self->_upperPlayer = [self generatePlayer:[NSURL URLWithString:self->_metadatas[0].videoURL]];
                [self->_upperPlayer prepareToPlay];
                self->_upperPlayer.playerView.frame = frame;
                [self.scrollView addSubview:self->_upperPlayer.playerView];
                self->_upperCover = [UIImageView new];
                self->_upperCover.contentMode = UIViewContentModeScaleAspectFit;
                [self->_upperCover sd_setImageWithURL:[NSURL URLWithString:self->_metadatas[0].coverURL]];
                self->_upperCover.frame = frame;
                [self.scrollView addSubview:self->_upperCover];
                self->_currentCover = self->_upperCover;
                self->_currentPlayer = self->_upperPlayer;
                self->_authorNameLabel.text = [NSString stringWithFormat:@"@%@", self->_metadatas[self->_currentIndex].authorNickName];
                self->_descLabel.text = self->_metadatas[self->_currentIndex].title;
                if (self->_viewAppear) {
                    [self->_currentPlayer play];
                } else {
                    [self->_currentPlayer prepareToPlay];
                }
                self->_playImage.hidden = YES;
                if (self->_metadatas.count <= 1) {
                    return;
                }
                self->_middlePlayer = [self generatePlayer:[NSURL URLWithString:self->_metadatas[1].videoURL]];
                [self->_middlePlayer prepareToPlay];
                self->_middlePlayer.playerView.frame = CGRectMake(0, frame.size.height, frame.size.width, frame.size.height);
                [self.scrollView addSubview:self->_middlePlayer.playerView];
                self->_middleCover = [UIImageView new];
                self->_middleCover.contentMode = UIViewContentModeScaleAspectFit;
                [self->_middleCover sd_setImageWithURL:[NSURL URLWithString:self->_metadatas[1].coverURL]];
                self->_middleCover.frame = CGRectMake(0, frame.size.height, frame.size.width, frame.size.height);
                [self.scrollView addSubview:self->_middleCover];
                
                if (self->_metadatas.count <= 2) {
                    return;
                }
                self->_lowerPlayer = [self generatePlayer:[NSURL URLWithString:self->_metadatas[2].videoURL]];
                [self->_lowerPlayer prepareToPlay];
                self->_lowerPlayer.playerView.frame = CGRectMake(0, 2 * frame.size.height, frame.size.width, frame.size.height);
                [self.scrollView addSubview:self->_lowerPlayer.playerView];
                self->_lowerCover = [UIImageView new];
                self->_lowerCover.contentMode = UIViewContentModeScaleAspectFit;
                [self->_lowerCover sd_setImageWithURL:[NSURL URLWithString:self->_metadatas[2].coverURL]];
                self->_lowerCover.frame = CGRectMake(0, 2 * frame.size.height, frame.size.width, frame.size.height);
                [self.scrollView addSubview:self->_lowerCover];
            });
        } else {
            SHOW_ERROR_ALERT;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self refreshMetadatas];
            });
        }
    }];
}

- (void)getMoreMetadatas:(NSUInteger)triedCount {
    if (triedCount >= 3) {
        return;
    }
    [self getRandomListWithCompletionHanler:^(NSMutableArray *metas, NSError *error) {
        if (!error) {
            [self->_metadatas addObjectsFromArray:metas];
        } else {
            SHOW_ERROR_ALERT;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self getMoreMetadatas:triedCount + 1];
            });
        }
    }];
}

- (void)getRandomListWithCompletionHanler:(void(^)(NSMutableArray *metas, NSError *error))handler {
    NSArray *sources = @[@"dou-yin", @"mei-pai", @"huo-shan", @"kuai-shou"];
    NSArray *timeRanges = @[@"week", @"month"];
    uint32_t maxPage = 5;
    NSString *URLString = [NSString stringWithFormat:@"https://kuaiyinshi.com/api/hot/videos/?source=%@&page=%u&st=%@&callback=showData&_=%d", sources[arc4random() % 4], arc4random() % maxPage, timeRanges[arc4random() % 2], (int)(1000 * [[NSDate date] timeIntervalSince1970])];
    [[NSURLSession.sharedSession dataTaskWithURL:[NSURL URLWithString:URLString] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSMutableArray *metas = [NSMutableArray array];
        if (((NSHTTPURLResponse *)response).statusCode == 200 && error == nil) {
            // 得到的数据格式：ShowData(...); 需要去掉外部的包裹
            if (data.length > 11) {
                void *validData = malloc(data.length - 11);
                [data getBytes:validData range:NSMakeRange(9, data.length - 11)];
                data = [NSData dataWithBytes:validData length:data.length - 11];
                free(validData);
                NSDictionary *responseObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
                NSArray* getFromResponse = [responseObject objectForKey:@"data"];
                for (NSDictionary* attributes in getFromResponse) {
                    if ([attributes respondsToSelector:@selector(objectForKey:)]) {
                        MDShortVideoMetadata* metadata = [[MDShortVideoMetadata alloc] initWithDic:attributes];
                        [metas addObject:metadata];
                    }
                }
            }
        }
        if (metas.count == 0 && !error) {
            metas = nil;
            error = [NSError errorWithDomain:@"request" code:-1 userInfo:nil];
        }
        if (handler) {
            handler(metas, error);
        }
    }] resume];
}

- (void)movieousPlayerControllerFirstVideoFrameRendered:(MovieousPlayerController *)playerController {
    if (playerController == _currentPlayer) {
        _currentCover.hidden = YES;
    }
}

- (void)movieousPlayerController:(MovieousPlayerController *)playerController playStateDidChangeWithPreviousState:(MPPlayerState)previousState newState:(MPPlayerState)newState {
    if (previousState == MPPlayerStatePaused && newState == MPPlayerStatePlaying) {
        _currentCover.hidden = YES;
    }
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"MDRecorderViewController"]) {
        if ([sender isKindOfClass:NSURL.class]) {
            ((MDRecorderViewController *)((UINavigationController *)segue.destinationViewController).topViewController).duetVideoURL = (NSURL *)sender;
        } else {
            _creationPanel.hidden = YES;
        }
    }
}

@end
