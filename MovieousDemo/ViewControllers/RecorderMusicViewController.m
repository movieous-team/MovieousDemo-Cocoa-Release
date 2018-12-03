//
//  RecorderMusicViewController.m
//  MovieousDemo
//
//  Created by Chris Wang on 2018/10/13.
//  Copyright © 2018 Movieous Team. All rights reserved.
//

#import "RecorderMusicViewController.h"

@interface RecorderMusicViewController ()

@end

@implementation RecorderMusicViewController {
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
