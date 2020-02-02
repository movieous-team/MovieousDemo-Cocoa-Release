//
//  MHCompleteBeautyView.m


//一键美颜

#import "MHCompleteBeautyView.h"
#import "MHFilterCell.h"
#import "MHBeautyParams.h"
#import "MHQuickBeautyModel.h"
@interface MHCompleteBeautyView()<UICollectionViewDelegate,UICollectionViewDataSource>
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray *array;
@property (nonatomic, assign) NSInteger lastIndex;
@end

@implementation MHCompleteBeautyView
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self addSubview:self.collectionView];
        self.lastIndex = 0;
    }
    return self;
}

- (void)cancelQuickBeautyEffect:(MHQuickBeautyModel *)selectedModel {
    for (int i = 0; i<self.array.count; i++) {
        MHQuickBeautyModel *model = self.array[i];
        if (i == 0) {
            model.isSelected = YES;
        }
        if ([model.title isEqualToString:selectedModel.title]) {
            model.isSelected = NO;
        }
    }
    [self.collectionView reloadData];
    self.lastIndex = 0;
}

#pragma mark - dataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.array.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MHFilterCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MHQuickBeautyCell" forIndexPath:indexPath];
    MHQuickBeautyModel *model = self.array[indexPath.row];
  /*
#ifdef SAVEEFFECTMODE
    NSData *data = [[NSUserDefaults standardUserDefaults] valueForKey:kFilterName];
    MHFilterModel *saveModel = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    if ([saveModel.filterName isEqualToString:model.filterName]) {
        model.isSelected = YES;
        self.lastIndex = indexPath.row;
        if ([self.delegate respondsToSelector:@selector(handleFiltersEffect:)]) {
            [self.delegate handleFiltersEffect:model.filterType];
        }
    }
#endif
   */
    cell.beautyModel = model;
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    return CGSizeMake((window_width-20) /MHFilterItemColumn, MHFilterCellHeight);
}

#pragma mark - delegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.lastIndex == indexPath.row) {
        return;
    }
    MHQuickBeautyModel *model = self.array[indexPath.row];
    model.isSelected = !model.isSelected;
    
#ifdef SAVEEFFECTMODE
//    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:model];
//    [[NSUserDefaults standardUserDefaults] setObject:data forKey:kFilterName];
#endif
    
    if ([self.delegate respondsToSelector:@selector(handleCompleteEffect:)]) {
        [self.delegate handleCompleteEffect:model];
    }
    if (self.lastIndex >= 0) {
        MHQuickBeautyModel *lastModel = self.array[self.lastIndex];
        lastModel.isSelected = !lastModel.isSelected;
    }
    
    
    [self.collectionView reloadData];
    self.lastIndex = indexPath.row;
}

#pragma mark - lazy
-(NSMutableArray *)array {
    if (!_array) {
        NSArray *arr = @[@"yuantu",@"biaozhun",@"youya",@"jingzhi",@"keai", @"ziran",@"gaoya",@"tuosu",@"wanghong"];
        NSString *path = [[NSBundle mainBundle] pathForResource:@"MHQuickBeautyParams" ofType:@"plist"];
        NSArray *contentArr = [NSArray arrayWithContentsOfFile:path];
        NSArray *dataArr = contentArr.firstObject;
        _array = [NSMutableArray array];
        for (int i = 0; i<dataArr.count; i++) {
            NSDictionary *dic = dataArr[i];
            MHQuickBeautyModel *model = [MHQuickBeautyModel mh_modelWithDictionary:dic];
            model.imgName = arr[i];
            model.isSelected = i == 0 ? YES : NO;
            model.quickBeautyType = i;
            [_array addObject:model];
        }
    }
#ifdef SAVEEFFECTMODE
//    NSData *data = [[NSUserDefaults standardUserDefaults] valueForKey:kFilterName];
//    if (data) {
//        MHQuickBeautyModel *firstModel = _array.firstObject;
//        model.isSelected = NO;
//        [_array replaceObjectAtIndex:0 withObject:firstModel];
//    }
#endif
    return _array;
}

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.minimumLineSpacing = 0;
        layout.minimumInteritemSpacing = 15;
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        layout.sectionInset = UIEdgeInsetsMake(10, 10, 10, 10);
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, window_width,self.height) collectionViewLayout:layout];
        _collectionView.backgroundColor = [UIColor whiteColor];
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        [_collectionView registerClass:[MHFilterCell class] forCellWithReuseIdentifier:@"MHQuickBeautyCell"];
    }
    return _collectionView;
}


@end
