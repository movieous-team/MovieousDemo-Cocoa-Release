//
//  MDEditPanelViewController.m
//  MovieousDemo
//
//  Created by Chris Wang on 2018/10/27.
//  Copyright © 2018 Movieous Team. All rights reserved.
//

#import "MDEditPanelViewController.h"
#import "MDGlobalSettings.h"

@interface MDEditPanelViewController ()
<
UICollectionViewDelegate,
UICollectionViewDataSource
>
@property (strong, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) IBOutlet UIPageControl *pageControl;

@end

@implementation MDEditPanelViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _pageControl.numberOfPages = ([_collectionView numberOfItemsInSection:0] - 1) / 6 + 1;
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 7;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[NSString stringWithFormat:@"%ld", indexPath.row] forIndexPath:indexPath];
    return cell;
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    NSUInteger pageNumber = targetContentOffset->x / _collectionView.frame.size.width;
    _pageControl.currentPage = pageNumber;
}

- (IBAction)pageControlValueChanged:(UIPageControl *)sender {
    [_collectionView setContentOffset:CGPointMake(_collectionView.frame.size.width * sender.currentPage, 0) animated:YES];
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    if ([identifier isEqualToString:@"ShowBeautyFilter"]) {
        if (MDGlobalSettings.sharedInstance.vendorType == VendorTypeTuSDK) {
            SHOW_ALERT(@"提示", @"当前供应商未提供使用美化功能", @"好的呢");
            return NO;
        } else if (MDGlobalSettings.sharedInstance.vendorType == VendorTypeNone) {
            SHOW_ALERT(@"提示", @"请选择一个供应商以使用美化功能", @"好的呢");
            return NO;
        }
    }
    return YES;
}

@end
