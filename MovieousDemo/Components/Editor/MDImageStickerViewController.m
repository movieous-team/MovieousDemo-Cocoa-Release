//
//  MDImageStickerViewController.m
//  MovieousDemo
//
//  Created by Chris Wang on 2019/2/19.
//  Copyright © 2019 Movieous Team. All rights reserved.
//

#import "MDImageStickerViewController.h"
#import "MDSharedCenter.h"

@interface MDStickerCell : UICollectionViewCell

@property (strong, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation MDStickerCell

@end

@interface MDImageStickerViewController ()
<
UICollectionViewDelegate,
UICollectionViewDataSource
>

@end

@implementation MDImageStickerViewController {
    NSString *_bundlePath;
    NSArray<NSString *> *_stickerNames;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _bundlePath = [[NSBundle mainBundle] pathForResource:@"Stickers" ofType:@"bundle"];
    NSError *error;
    _stickerNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:_bundlePath error:&error];
    if (error) {
        SHOW_ERROR_ALERT;
        return;
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _stickerNames.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MDStickerCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    cell.imageView.image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", _bundlePath, _stickerNames[indexPath.row]]];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableArray *effects = [NSMutableArray arrayWithArray:MDSharedCenter.sharedCenter.editor.draft.basicEffects];
    UIImage *image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", _bundlePath, _stickerNames[indexPath.row]]];
    CGSize videoSize = MDSharedCenter.sharedCenter.editor.draft.videoSize;
    MSVImageStickerEffect *imageStickerEffect = [MSVImageStickerEffect imageStickerEffectWithImage:image];
    imageStickerEffect.ID = kImageStickerEffectID;
    imageStickerEffect.destRect = CGRectMake((videoSize.width - image.size.width) / 2, (videoSize.height - image.size.height) / 2, image.size.width, image.size.height);
    [effects addObject:imageStickerEffect];
    NSError *error;
    [MDSharedCenter.sharedCenter.editor.draft updateBasicEffects:effects error:&error];
    if (error) {
        SHOW_ERROR_ALERT;
        return;
    }
    [collectionView reloadData];
}

@end
