//
//  SplitCollectionViewController.m
//  MovieousDemo
//
//  Created by Chris Wang on 2018/10/27.
//  Copyright © 2018 Movieous Team. All rights reserved.
//

#import "SplitCollectionViewController.h"

@interface SplitCollectionViewController ()

@end

@implementation SplitCollectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 4;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[NSString stringWithFormat:@"%ld", (long)indexPath.row] forIndexPath:indexPath];
    return cell;
}

@end
