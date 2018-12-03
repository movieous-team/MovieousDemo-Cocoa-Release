//
//  EditorMusicViewController.m
//  MovieousDemo
//
//  Created by Chris Wang on 2018/10/28.
//  Copyright © 2018 Movieous Team. All rights reserved.
//

#import "EditorMusicViewController.h"
#import "MSVEditor+Extentions.h"

@interface EditorMusicViewControllerCell ()

@property (strong, nonatomic) IBOutlet UILabel *name;
@property (strong, nonatomic) IBOutlet UILabel *author;

@end

@implementation EditorMusicViewControllerCell

@end

@interface EditorMusicViewController ()
<
UICollectionViewDelegate,
UICollectionViewDataSource
>

@end

@implementation EditorMusicViewController {
    NSString *_bundlePath;
    NSArray<NSString *> *_fileNames;
    MSVEditor *_editor;
}

- (void)viewDidLoad {
    _bundlePath = [[NSBundle mainBundle] pathForResource:@"BackgroundMusics" ofType:@"bundle"];
    NSError *error;
    _fileNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:_bundlePath error:&error];
    if (error) {
        NSLog(@"error: %@", error.localizedDescription);
        return;
    }
    _editor = [MSVEditor sharedInstance];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _fileNames.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    EditorMusicViewControllerCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MusicCell" forIndexPath:indexPath];
    if (indexPath.row == 0) {
        cell.name.text = @"无";
    } else {
        cell.name.text = _fileNames[indexPath.row - 1];
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSError *error;
    NSArray *audioClips;
    if (indexPath.row > 0) {
        MSVAudioClip *audioClip = [MSVAudioClip audioClipWithURL:[NSURL fileURLWithPath:[_bundlePath stringByAppendingPathComponent:_fileNames[indexPath.row - 1]]] error:&error];
        if (error) {
            SHOW_ERROR_ALERT;
            return;
        }
        audioClips = @[audioClip];
    }
    [_editor.draft updateAudioClips:audioClips error:&error];
    if (error) {
        SHOW_ERROR_ALERT;
        return;
    }
    [self.navigationController popViewControllerAnimated:YES];
}

@end
