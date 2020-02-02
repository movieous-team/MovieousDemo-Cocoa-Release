//
//  MHFilterCell.m

#import "MHFilterCell.h"
#import "MHBeautiesModel.h"
#import "MHBeautyParams.h"
#import "MHQuickBeautyModel.h"
static NSString *FilterSelected = @"filter_selected2";

@interface MHFilterCell()
@property (nonatomic, strong) UIImageView *imgView;
@property (nonatomic, strong) UIImageView *selectedImgView;
@property (nonatomic, strong) UILabel *filterLabel;
@end
@implementation MHFilterCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self addSubview:self.imgView];
        [self.imgView addSubview:self.selectedImgView];
        [self addSubview:self.filterLabel];
    }
    return self;
}
//滤镜，特效使用 
- (void)setFiltermodel:(MHBeautiesModel *)filtermodel{
    if (!filtermodel) {
        return;
    }
    if (filtermodel.menuType == MHBeautyMenuType_Specify) {
        self.imgView.frame = CGRectMake((self.width - 50)/2,2, 50, 60);
    } else {
        self.imgView.frame = CGRectMake((self.width - 55)/2,2, 55, 55);
    }
    UIImage *img = BundleImg(filtermodel.imgName);
    [self.imgView setImage:img];
    self.selectedImgView.hidden = !filtermodel.isSelected;
    self.selectedImgView.frame = self.imgView.bounds;
    self.filterLabel.text = filtermodel.beautyTitle;
    self.filterLabel.textColor = filtermodel.isSelected ? FontColorSelected : FontColorNormal;
    self.filterLabel.frame = CGRectMake(3, _imgView.bottom+8, self.width - 6, 15);
}

//一键美颜使用
- (void)setBeautyModel:(MHQuickBeautyModel *)beautyModel {
    if (!beautyModel) {
        return;
    }
    _beautyModel = beautyModel;
    self.imgView.frame = CGRectMake((self.width - 55)/2,2, 55, 55);
    UIImage *img = BundleImg(beautyModel.imgName);
    [self.imgView setImage:img];
    self.selectedImgView.hidden = !beautyModel.isSelected;
    self.selectedImgView.frame = self.imgView.bounds;
    self.filterLabel.text = beautyModel.title;
    self.filterLabel.textColor = beautyModel.isSelected ? FontColorSelected : FontColorNormal;
    self.filterLabel.frame = CGRectMake(3, _imgView.bottom+15, self.width - 6, 15);
}

#pragma mark - lazy
- (UIImageView *)selectedImgView {
    if (!_selectedImgView) {
        UIImage *img = BundleImg(FilterSelected);
        _selectedImgView = [[UIImageView alloc] initWithImage:img];
        _selectedImgView.hidden = YES;
    }
    return _selectedImgView;
}

- (UIImageView *)imgView {
    if (!_imgView) {
        _imgView = [[UIImageView alloc] init];
    }
    return _imgView;
}

- (UILabel *)filterLabel {
    if (!_filterLabel) {
        _filterLabel = [[UILabel alloc] init];
        _filterLabel.font = Font_10;
        _filterLabel.textAlignment = NSTextAlignmentCenter;
        _filterLabel.textColor = FontColorNormal;
    }
    return _filterLabel;
}

@end
