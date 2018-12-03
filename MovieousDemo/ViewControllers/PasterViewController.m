//
//  PasterViewController.m
//  MovieousDemo
//
//  Created by Chris Wang on 2018/11/3.
//  Copyright © 2018 Movieous Team. All rights reserved.
//

#import "PasterViewController.h"
#import "FULiveModel.h"
#import "FUManager.h"
#import "STManager.h"
#import "STCollectionView.h"

@interface PasterCell : UICollectionViewCell

@property (strong, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation PasterCell

@end

@interface PasterViewController ()
<
UICollectionViewDelegate,
UICollectionViewDataSource
>

@end

@implementation PasterViewController {
    NSMutableArray<NSString *> *_FUItems;
    NSMutableArray<STCollectionViewDisplayModel *> *_STItems;
    STCollectionViewDisplayModel *_selectedModel;
}

static NSString * const reuseIdentifier = @"Cell";

- (void)viewDidLoad {
    [super viewDidLoad];
    _FUItems = [NSMutableArray array];
    for (FULiveModel *model in [FUManager shareManager].dataSource) {
        if (model.type == FULiveModelTypeMusicFilter || !model.enble) {
            continue;
        }
        if (model.items.count > 0) {
            [_FUItems addObjectsFromArray:model.items];
        }
    }
    _STItems = [NSMutableArray array];
    [_STItems addObjectsFromArray:[STManager sharedManager].arrNewStickers];
    [_STItems addObjectsFromArray:[STManager sharedManager].arr3DStickers];
    [_STItems addObjectsFromArray:[STManager sharedManager].arrParticleStickers];
    [_STItems addObjectsFromArray:[STManager sharedManager].arr2DStickers];
//    [_STItems addObjectsFromArray:[STManager sharedManager].arrAvatarStickers];
    [_STItems addObjectsFromArray:[STManager sharedManager].arrGestureStickers];
    [_STItems addObjectsFromArray:[STManager sharedManager].arrSegmentStickers];
    [_STItems addObjectsFromArray:[STManager sharedManager].arrFacedeformationStickers];
    [_STItems addObjectsFromArray:[STManager sharedManager].arrFaceChangeStickers];
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _FUItems.count + _STItems.count + 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PasterCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    if (indexPath.row == 0) {
        cell.imageView.image = [UIImage imageNamed:@"noitem"];
    } else if (indexPath.row <= _FUItems.count) {
        cell.imageView.image = [UIImage imageNamed:_FUItems[indexPath.row - 1]];
    } else {
        cell.imageView.image = _STItems[indexPath.row - _FUItems.count - 1].image;
    }
    // Configure the cell
    return cell;
}

#pragma mark <UICollectionViewDelegate>

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        [[FUManager shareManager] loadItem:@"noitem"];
        [[STManager sharedManager] cancelStickerAndObjectTrack];
    } else if (indexPath.row <= _FUItems.count) {
        [[FUManager shareManager] loadItem:_FUItems[indexPath.row - 1]];
        NSString *hint = [[FUManager shareManager] hintForItem:_FUItems[indexPath.row - 1]];
        if (hint.length > 0) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kShowHintNotification object:self userInfo:@{@"hint": hint}];
        }
        [[STManager sharedManager] cancelStickerAndObjectTrack];
    } else {
        _selectedModel.isSelected = NO;
        _selectedModel = _STItems[indexPath.row - _FUItems.count - 1];
        _selectedModel.isSelected = YES;
        [[STManager sharedManager] handleStickerChanged:_selectedModel];
        [[FUManager shareManager] loadItem:@"noitem"];
    }
}

@end
