//
//  MDUploaderViewController.m
//  MovieousDemo
//
//  Created by Chris Wang on 2018/12/6.
//  Copyright © 2018 Movieous Team. All rights reserved.
//

#import "MDUploaderViewController.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import <UFileSDK/UFileSDK.h>

@interface MDUploaderViewController ()

@end

@implementation MDUploaderViewController {
    UFFileClient *_fileClient;
    MSVVideoExporter *_exporter;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _fileClient = [UFFileClient instanceFileClientWithConfig:[UFConfig instanceConfigWithPrivateToken:@"b253bb25-3596-4372-9c19-c97d10bce448" publicToken:@"TOKEN_218481a2-1fb0-45d4-9905-fcbd999096de" bucket:@"twsy" fileOperateEncryptServer:nil fileAddressEncryptServer:nil proxySuffix:@"cn-bj.ufileos.com"]];
    _exporter = [[MSVVideoExporter alloc] initWithDraft:_draft];
    _exporter.saveToPhotosAlbum = YES;
    MovieousWeakSelf
    _exporter.progressHandler = ^(float progress) {
        [SVProgressHUD showProgress:progress status:@"正在导出"];
    };
    _exporter.completionHandler = ^(NSURL * _Nonnull URL) {
        [SVProgressHUD showWithStatus:@"开始上传"];
        MovieousStrongSelf
        [strongSelf->_fileClient uploadWithKeyName:URL.lastPathComponent filePath:URL.path mimeType:@"video/mpeg4" progress:^(NSProgress * _Nonnull progress) {
            [SVProgressHUD showProgress:(float)progress.completedUnitCount / (float)progress.totalUnitCount status:@"正在上传"];
        } uploadHandler:^(UFError * _Nullable ufError, UFUploadResponse * _Nullable ufUploadResponse) {
            if (ufError) {
                [SVProgressHUD dismiss];
                NSError *error = ufError.error;
                SHOW_ERROR_ALERT_FOR(strongSelf)
                wSelf.view.userInteractionEnabled = YES;
            } else {
                [SVProgressHUD dismiss];
                SHOW_ALERT_FOR(@"上传完成", URL.lastPathComponent, @"好的", strongSelf)
                wSelf.view.userInteractionEnabled = YES;
            }
        }];
    };
    _exporter.failureHandler = ^(NSError * _Nonnull error) {
        [SVProgressHUD dismiss];
        SHOW_ERROR_ALERT_FOR(wSelf)
        wSelf.view.userInteractionEnabled = YES;
    };
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (IBAction)uploadButtonPressed:(id)sender {
    [_exporter startExport];
    [SVProgressHUD showWithStatus:@"开始导出"];
    self.view.userInteractionEnabled = NO;
}

@end
