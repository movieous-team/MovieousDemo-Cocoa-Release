//
//  FUStickerView.m
//  MovieousDemo
//
//  Created by Chris Wang on 2019/1/23.
//  Copyright © 2019 Movieous Team. All rights reserved.
//

#import "FUStickerView.h"
#import "FUManager.h"
#import "FULiveModel.h"

@interface FUStickerView ()
<
UICollectionViewDataSource,
UICollectionViewDelegate
>

@property (strong, nonatomic) IBOutlet UICollectionView *topCollectionView;
@property (strong, nonatomic) IBOutlet UICollectionView *middleCollectionView;

@end

@implementation FUStickerView {
    NSMutableArray<NSString *> *_stickerCategories;
    NSInteger _showingCategoryIndex, _selectedCategoryIndex, _selectedRowIndex;
    NSMutableArray<NSArray<NSString *> *> *_models;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    _showingCategoryIndex = 0;
    _selectedCategoryIndex = -1;
    _selectedRowIndex = -1;
    _models = [NSMutableArray array];
    _stickerCategories = [NSMutableArray array];
    for (FULiveModel *model in FUManager.shareManager.dataSource) {
        if (model.enble && model.items.count > 0) {
            [_stickerCategories addObject:model.title];
            [_models addObject:model.items];
        }
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView.tag == 0) {
        if (indexPath.row == 0) {
            UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"top_image" forIndexPath:indexPath];
            for (UIView *subview in cell.contentView.subviews) {
                if (subview.tag == 1) {
                    ((UIImageView *)subview).image = [UIImage imageNamed:@"noitem"];
                    break;
                }
            }
            return cell;
        } else {
            UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"top_label" forIndexPath:indexPath];
            for (UIView *subview in cell.contentView.subviews) {
                if (subview.tag == 1) {
                    UILabel *label = (UILabel *)subview;
                    label.text = _stickerCategories[indexPath.row - 1];
                    if (indexPath.row - 1 == _showingCategoryIndex) {
                        label.textColor = UIColor.whiteColor;
                    } else {
                        label.textColor = UIColor.lightGrayColor;
                    }
                } else if (subview.tag == 2) {
                    if (indexPath.row - 1 == _showingCategoryIndex) {
                        subview.hidden = NO;
                    } else {
                        subview.hidden = YES;
                    }
                }
            }
            return cell;
        }
    } else {
        UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"middle" forIndexPath:indexPath];
        UIImage *image;
        image = [UIImage imageNamed:_models[_showingCategoryIndex][indexPath.row]];
        
        for (UIView *subview in cell.contentView.subviews) {
            if (subview.tag == 1) {
                UIImageView *imageView = (UIImageView *)subview;
                imageView.image = image;
            } else if (subview.tag == 2) {
                if (_showingCategoryIndex == _selectedCategoryIndex &&
                    indexPath.row == _selectedRowIndex) {
                    subview.hidden = NO;
                } else {
                    subview.hidden = YES;
                }
            }
        }
        return cell;
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (collectionView.tag == 0) {
        return _stickerCategories.count + 1;
    } else {
        return _models[_showingCategoryIndex].count;
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView.tag == 0) {
        if (indexPath.row == 0) {
            _selectedCategoryIndex = -1;
            _selectedRowIndex = -1;
            [[FUManager shareManager] loadItem:@"noitem"];
            [_middleCollectionView reloadData];
            return;
        } else if (indexPath.row - 1 == _showingCategoryIndex) {
            return;
        } else {
            _showingCategoryIndex = indexPath.row - 1;
            [collectionView reloadData];
            [_middleCollectionView reloadData];
        }
    } else if (collectionView.tag == 1) {
        _selectedCategoryIndex = _showingCategoryIndex;
        _selectedRowIndex = indexPath.row;
        [[FUManager shareManager] loadItem:_models[_selectedCategoryIndex][indexPath.row]];
        NSString *hint = [[FUManager shareManager] hintForItem:_models[_selectedCategoryIndex][indexPath.row]];
        if (hint.length > 0) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kShowHintNotification object:self userInfo:@{@"hint": hint}];
        }
        [collectionView reloadData];
    }
}

@end
