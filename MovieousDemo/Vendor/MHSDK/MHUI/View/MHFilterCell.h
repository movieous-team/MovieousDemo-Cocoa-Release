//
//  MHFilterCell.h

#import <UIKit/UIKit.h>
@class MHBeautiesModel,MHQuickBeautyModel;
NS_ASSUME_NONNULL_BEGIN

@interface MHFilterCell : UICollectionViewCell
@property (nonatomic, copy) NSString *filterName;
@property (nonatomic, strong) MHBeautiesModel *filtermodel;
@property (nonatomic, strong) MHQuickBeautyModel *beautyModel;
@end

NS_ASSUME_NONNULL_END
