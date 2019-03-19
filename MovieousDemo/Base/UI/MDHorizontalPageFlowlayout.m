//
//  MDHorizontalPageFlowlayout.m
//  HorizontanPageView
//
//  Created by CJW on 16/10/20.
//  Copyright © 2016年 Datong. All rights reserved.
//

#import "MDHorizontalPageFlowlayout.h"

#define DefaultRowCount 2
#define DefaultItemCountPerRow 3
#define DefaultColumnSpacing 5
#define DefaultRowSpacing 5
#define DefaultEdgeInsets UIEdgeInsetsMake(0, 10, 0, 10)

@interface MDHorizontalPageFlowlayout ()

/** 所有item的属性数组 */
@property (nonatomic, strong) NSMutableArray *attributesArrayM;

@end

@implementation MDHorizontalPageFlowlayout

#pragma mark - 构造方法
+ (instancetype)MDHorizontalPageFlowlayoutWithRowCount:(NSInteger)rowCount itemCountPerRow:(NSInteger)itemCountPerRow
{
    return [[self alloc] initWithRowCount:rowCount itemCountPerRow:itemCountPerRow];
}

+ (instancetype)MDHorizontalPageFlowlayoutWithRowCount:(NSInteger)rowCount itemCountPerRow:(NSInteger)itemCountPerRow columnSpacing:(CGFloat)columnSpacing rowSpacing:(CGFloat)rowSpacing edgeInsets:(UIEdgeInsets)edgeInsets {
    return [[self alloc] initWithRowCount:rowCount itemCountPerRow:itemCountPerRow columnSpacing:columnSpacing rowSpacing:rowSpacing edgeInsets:edgeInsets];
}

- (instancetype)initWithRowCount:(NSInteger)rowCount itemCountPerRow:(NSInteger)itemCountPerRow {
    return [self initWithRowCount:rowCount itemCountPerRow:itemCountPerRow columnSpacing:0 rowSpacing:0 edgeInsets:UIEdgeInsetsZero];
}

- (instancetype)initWithRowCount:(NSInteger)rowCount itemCountPerRow:(NSInteger)itemCountPerRow columnSpacing:(CGFloat)columnSpacing rowSpacing:(CGFloat)rowSpacing edgeInsets:(UIEdgeInsets)edgeInsets {
    self = [super init];
    if (self) {
        self.rowCount = rowCount;
        self.itemCountPerRow = itemCountPerRow;
        self.columnSpacing = columnSpacing;
        self.rowSpacing = rowSpacing;
        self.edgeInsets = edgeInsets;
    }
    return self;
}

#pragma mark - 重写父类方法

- (instancetype)init {
    if (self = [super init]) {
        self.rowCount = DefaultRowCount;
        self.itemCountPerRow = DefaultItemCountPerRow;
        self.columnSpacing = DefaultColumnSpacing;
        self.rowSpacing = DefaultRowSpacing;
        self.edgeInsets = DefaultEdgeInsets;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        self.rowCount = DefaultRowCount;
        self.itemCountPerRow = DefaultItemCountPerRow;
        self.columnSpacing = DefaultColumnSpacing;
        self.rowSpacing = DefaultRowSpacing;
        self.edgeInsets = DefaultEdgeInsets;
    }
    return self;
}

/** 布局前做一些准备工作 */
- (void)prepareLayout
{
    [super prepareLayout];
    
    // 从collectionView中获取到有多少个item
    NSInteger itemTotalCount = [self.collectionView numberOfItemsInSection:0];
    
    // 遍历出item的attributes,把它添加到管理它的属性数组中去
    for (int i = 0; i < itemTotalCount; i++) {
        NSIndexPath *indexpath = [NSIndexPath indexPathForItem:i inSection:0];
        UICollectionViewLayoutAttributes *attributes = [self layoutAttributesForItemAtIndexPath:indexpath];
        [self.attributesArrayM addObject:attributes];
    }
}

/** 计算collectionView的滚动范围 */
- (CGSize)collectionViewContentSize
{
    // 从collectionView中获取到有多少个item
    NSInteger itemTotalCount = [self.collectionView numberOfItemsInSection:0];
    // 理论上每页展示的item数目
    NSInteger itemCount = self.rowCount * self.itemCountPerRow;
    // 余数（用于确定最后一页展示的item个数）
    NSInteger remainder = itemTotalCount % itemCount;
    // 除数（用于判断页数）
    NSInteger pageNumber = itemTotalCount / itemCount;
    if (remainder == 0) {
        pageNumber = pageNumber;
    }else {
        // 余数不为0,除数加1
        pageNumber = pageNumber + 1;
    }
    
    // 计算出item的宽度
    CGFloat itemWidth = (self.collectionView.frame.size.width - self.edgeInsets.left - (self.itemCountPerRow - 1) * self.columnSpacing - self.edgeInsets.right) / self.itemCountPerRow;
    
    CGFloat width = pageNumber * (self.edgeInsets.left + self.itemCountPerRow * (itemWidth + self.columnSpacing) - self.columnSpacing + self.edgeInsets.right);
    // 只支持水平方向上的滚动
    return CGSizeMake(width, 0);
}

/** 设置每个item的属性(主要是frame) */
- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    // item的宽高由行列间距和collectionView的内边距决定
    CGFloat itemWidth = (self.collectionView.frame.size.width - self.edgeInsets.left - (self.itemCountPerRow - 1) * self.columnSpacing - self.edgeInsets.right) / self.itemCountPerRow;
    CGFloat itemHeight = (self.collectionView.frame.size.height - self.edgeInsets.top - (self.rowCount - 1) * self.rowSpacing - self.edgeInsets.bottom) / self.rowCount;
    
    NSInteger item = indexPath.item;
    // 当前item所在的页
    NSInteger pageNumber = item / (self.rowCount * self.itemCountPerRow);
    NSInteger x = item % self.itemCountPerRow;
    NSInteger y = item / self.itemCountPerRow - pageNumber * self.rowCount;
    
    // 计算出item的坐标
    CGFloat itemX = pageNumber * self.collectionView.frame.size.width + self.edgeInsets.left + (itemWidth + self.columnSpacing) * x;
    CGFloat itemY = self.edgeInsets.top + (itemHeight + self.rowSpacing) * y;
    
    UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    // 每个item的frame
    attributes.frame = CGRectMake(itemX, itemY, itemWidth, itemHeight);
    
    return attributes;
}

/** 返回collectionView视图中所有视图的属性数组 */
- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect
{
    return self.attributesArrayM;
}


#pragma mark - Lazy
- (NSMutableArray *)attributesArrayM
{
    if (!_attributesArrayM) {
        _attributesArrayM = [NSMutableArray array];
    }
    return _attributesArrayM;
}

@end
