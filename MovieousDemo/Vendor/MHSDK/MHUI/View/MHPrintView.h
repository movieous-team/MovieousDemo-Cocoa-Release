//
//  MHPrintView.h

#import <UIKit/UIKit.h>
@class MHMagnifyModel;
NS_ASSUME_NONNULL_BEGIN
@protocol MHPrintViewDelegate <NSObject>

- (void)handlePrint:(MHMagnifyModel *)model;

@end
@interface MHPrintView : UIView
@property (nonatomic, weak) id<MHPrintViewDelegate> delegate;
@end

NS_ASSUME_NONNULL_END
