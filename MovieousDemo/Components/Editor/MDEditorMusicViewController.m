//
//  MDEditorMusicViewController.m
//  MovieousDemo
//
//  Created by Chris Wang on 2019/1/17.
//  Copyright © 2019 Movieous Team. All rights reserved.
//

#import "MDEditorMusicViewController.h"
#import "MDSharedCenter.h"

@interface MDEditorMusicViewControllerCell : UICollectionViewCell

@property (strong, nonatomic) IBOutlet UILabel *name;
@property (strong, nonatomic) IBOutlet UILabel *author;
@property (strong, nonatomic) IBOutlet UIView *selectCover;

@end

@implementation MDEditorMusicViewControllerCell

@end

@interface MDEditorMusicViewController ()
<
UICollectionViewDelegate,
UICollectionViewDataSource
>

@property (strong, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) IBOutlet UIPageControl *pageControl;

@end

@implementation MDEditorMusicViewController {
    NSString *_bundlePath;
    NSArray<NSString *> *_fileNames;
    MSVEditor *_editor;
    NSInteger _selectedRow;
}

- (void)viewDidLoad {
    _bundlePath = [[NSBundle mainBundle] pathForResource:@"BackgroundMusics" ofType:@"bundle"];
    NSError *error;
    _fileNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:_bundlePath error:&error];
    if (error) {
        NSLog(@"error: %@", error.localizedDescription);
        return;
    }
    _editor = MDSharedCenter.sharedCenter.editor;
    _pageControl.numberOfPages = [_collectionView numberOfItemsInSection:0] / 6 + 1;
    _selectedRow = 0;
    MSVMixTrackClip *musicClip;
    for (MSVMixTrackClip *mixTrackClip in _editor.draft.mixTrackClips) {
        if ([mixTrackClip.ID isEqualToString:@"music"]) {
            musicClip = mixTrackClip;
            break;
        }
    }
    if (musicClip) {
        for (int i = 0; i < _fileNames.count; i++) {
            NSString *fileName = _fileNames[i];
            NSString *lastPathComponent = musicClip.URL.lastPathComponent;
            if ([lastPathComponent isEqualToString:fileName]) {
                _selectedRow = i + 1;
                break;
            }
        }
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _fileNames.count + 1;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MDEditorMusicViewControllerCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MusicCell" forIndexPath:indexPath];
    if (indexPath.row == 0) {
        cell.name.text = @"无";
    } else {
        cell.name.text = _fileNames[indexPath.row - 1];
    }
    if (_selectedRow == indexPath.row) {
        cell.selectCover.hidden = NO;
    } else {
        cell.selectCover.hidden = YES;
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSError *error;
    NSMutableArray<MSVMixTrackClip *> *mixTrackClips = [NSMutableArray array];
    [_editor.draft beginChangeTransaction];
    for (MSVMixTrackClip *clip in _editor.draft.mixTrackClips) {
        if (![clip.ID isEqualToString:@"music"]) {
            [mixTrackClips addObject:clip];
            clip.volume = 0;
        }
    }
    for (MSVMainTrackClip *clip in _editor.draft.mainTrackClips) {
        clip.volume = 0;
    }
    if (indexPath.row > 0) {
        MSVMixTrackClip *mixTrackClip = [MSVMixTrackClip mixTrackClipWithType:MSVClipTypeAV URL:[NSURL fileURLWithPath:[_bundlePath stringByAppendingPathComponent:_fileNames[indexPath.row - 1]]] startTimeAtMainTrack:0 error:&error];
        if (error) {
            [_editor.draft cancelChangeTransaction];
            SHOW_ERROR_ALERT;
            return;
        }
        mixTrackClip.ID = @"music";
        [mixTrackClips addObject:mixTrackClip];
    }
    [_editor.draft updateMixTrackClips:mixTrackClips error:&error];
    if (error) {
        [_editor.draft cancelChangeTransaction];
        SHOW_ERROR_ALERT;
        return;
    }
    [_editor.draft commitChangeWithError:&error];
    if (error) {
        [_editor.draft cancelChangeTransaction];
        SHOW_ERROR_ALERT;
        return;
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    NSUInteger pageNumber = targetContentOffset->x / _collectionView.frame.size.width;
    _pageControl.currentPage = pageNumber;
}

- (IBAction)pageControlValueChanged:(UIPageControl *)sender {
    [_collectionView setContentOffset:CGPointMake(_collectionView.frame.size.width * sender.currentPage, 0) animated:YES];
}


@end
