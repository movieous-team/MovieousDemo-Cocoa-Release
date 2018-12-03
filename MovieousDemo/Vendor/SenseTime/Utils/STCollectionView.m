//
//  STStickersCollectionView.m
//
//  Created by HaifengMay on 16/11/8.
//  Copyright © 2016年 SenseTime. All rights reserved.
//

#import "STCollectionView.h"
#import "STCollectionViewCell.h"

@implementation STCollectionViewDisplayModel

@end

@interface STCollectionView()<UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, copy) STCollectionViewDelegateBlock delegateBlock;

@end

@implementation STCollectionView

- (instancetype)initWithFrame:(CGRect)frame withModels:(NSArray <STCollectionViewDisplayModel *> *) arrModels andDelegateBlock:(STCollectionViewDelegateBlock) delegateBlock
{
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    flowLayout.itemSize = CGSizeMake(60, 60);
    flowLayout.minimumLineSpacing = 5;
    flowLayout.minimumInteritemSpacing = 5;
    flowLayout.sectionInset = UIEdgeInsetsMake(5, 5, 5, 5);
    flowLayout.footerReferenceSize = CGSizeMake([UIScreen mainScreen].bounds.size.width, 30);
    
    self = [super initWithFrame:frame collectionViewLayout:flowLayout];
    if (self) {
        
        [self setBackgroundColor:[UIColor clearColor]];
        self.alwaysBounceVertical = NO;
        self.showsHorizontalScrollIndicator = NO;
        self.showsVerticalScrollIndicator = NO;
        self.arrModels = [arrModels copy];
        self.delegateBlock = delegateBlock;
        self.delegate = self;
        self.dataSource = self;
        [self registerClass:[STCollectionViewCell class] forCellWithReuseIdentifier:@"STCollectionViewCell"];
        [self registerClass:[STCollectionLabelCell class] forCellWithReuseIdentifier:@"STCollectionLabelCell"];
    }
    return self;
}

#pragma mark - dataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    return self.arrModels.count;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    STCollectionViewCell *cell = [self dequeueReusableCellWithReuseIdentifier:@"STCollectionViewCell" forIndexPath:indexPath];
    
    STCollectionViewDisplayModel *model = self.arrModels[indexPath.row];
    cell.imageView.image = model.image;
    cell.maskView.layer.borderColor = model.isSelected ? UIColorFromRGB(0x47c9ff).CGColor : [UIColor clearColor].CGColor;
    cell.maskView.hidden = !(model.isSelected);
    return cell;
}

#pragma mark - delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if (self.selectedModel) {
        self.selectedModel.isSelected = NO;
    }
    
    if (self.arrModels[indexPath.row].modelType == self.selectedModel.modelType
        && self.arrModels[indexPath.row].index == self.selectedModel.index) {
        self.selectedModel = nil;
    } else {
        self.arrModels[indexPath.row].isSelected = YES;
        self.selectedModel = self.arrModels[indexPath.row];
    }
    
    [collectionView reloadData];
    
    if (self.delegateBlock) {
        
        self.delegateBlock(self.arrModels[indexPath.row]);
    }
}

- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated scrollPosition:(UICollectionViewScrollPosition)scrollPosition
{
    [super selectItemAtIndexPath:indexPath animated:animated scrollPosition:scrollPosition];
    
    [self collectionView:self didSelectItemAtIndexPath:indexPath];
}

@end

@interface STFilterCollectionView()<UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@end

@implementation STFilterCollectionView

- (instancetype)initWithFrame:(CGRect)frame withModels:(NSArray<STCollectionViewDisplayModel *> *)arrModels andDelegateBlock:(STCollectionViewDelegateBlock)delegateBlock {
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    flowLayout.itemSize = CGSizeMake(65, 90);
    flowLayout.minimumInteritemSpacing = 180;
    flowLayout.minimumLineSpacing = 5;
    flowLayout.sectionInset = UIEdgeInsetsMake(-10, 5, 5, 5);
    
    self = [super initWithFrame:frame collectionViewLayout:flowLayout];
    if (self) {
        
        self.preSelectedType = STEffectsTypeNone;
        self.backgroundColor = [UIColor clearColor];
        self.showsHorizontalScrollIndicator = NO;
        self.showsVerticalScrollIndicator = NO;
        self.arrModels = [arrModels copy];
        self.delegateBlock = delegateBlock;
        self.delegate = self;
        self.dataSource = self;
        
        [self registerClass:[STCollectionLabelCell class] forCellWithReuseIdentifier:@"STCollectionLabelCell"];
    }
    return self;
}

#pragma mark - dataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.arrModels.count;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    STCollectionLabelCell *cell = [self dequeueReusableCellWithReuseIdentifier:@"STCollectionLabelCell" forIndexPath:indexPath];
    cell.backgroundColor = [UIColor whiteColor];
    
    STCollectionViewDisplayModel *model = self.arrModels[indexPath.row];
    cell.imageView.image = model.image;
    cell.lblName.text = model.strName;
    cell.maskContainerView.hidden = !(model.isSelected);
    cell.imageMaskView.hidden = !(model.isSelected);
    cell.lblMaskView.hidden = !(model.isSelected);
    cell.lblName.highlighted = model.isSelected;
    
    return cell;
}

#pragma mark - delegate


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if (self.selectedModel) {
        self.selectedModel.isSelected = NO;
    }
    self.arrModels[indexPath.row].isSelected = YES;
    
    self.selectedModel = self.arrModels[indexPath.row];
    [collectionView reloadData];
    
    if (self.delegateBlock) {
        self.delegateBlock(self.arrModels[indexPath.row]);
    }
}

- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated scrollPosition:(UICollectionViewScrollPosition)scrollPosition {
    
    [super selectItemAtIndexPath:indexPath animated:animated scrollPosition:scrollPosition];
    
    [self collectionView:self didSelectItemAtIndexPath:indexPath];
}

@end
