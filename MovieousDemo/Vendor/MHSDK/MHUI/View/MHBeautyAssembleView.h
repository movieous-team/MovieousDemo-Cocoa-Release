//
//  MHBeautyAssembleView.h


#import <UIKit/UIKit.h>

@class MHQuickBeautyModel;
NS_ASSUME_NONNULL_BEGIN
@protocol MHBeautyAssembleViewDelegate <NSObject>
@required
/**
 
 美颜-腾讯直播SDK专用
 @param beauty 磨皮 0-9，数值越大，效果越明显
 @param white 美白 0-9，数值越大，效果越明显
 @param ruddiness 红润 0-9，数值越大，效果越明显
 */
- (void)beautyLevel:(NSInteger)beauty whitenessLevel:(NSInteger)white ruddinessLevel:(NSInteger)ruddiness brightnessLevel:(NSInteger)brightness;

/// 美颜
/// @param type 美颜类型：美白，磨皮，红润
/// @param beautyLevel 美颜参数，0-1，数值越大，效果越明显
- (void)handleBeautyWithType:(NSInteger)type level:(NSInteger)beautyLevel;

/**
 一键美颜

 @param model 一键美颜模型
 */
- (void)handleQuickBeautyValue:(MHQuickBeautyModel *)model;

- (void)handleQuickBeautyWithSliderValue:(NSInteger)value quickBeautyModel:(MHQuickBeautyModel *)model;

/**
 美型

 @param type 美型类型
 @param value 数值
 */
- (void)handleFaceBeautyWithType:(NSInteger)type sliderValue:(NSInteger)value;

/**
 滤镜

 @param filter 滤镜
 */
- (void)handleFiltersEffectWithType:(NSInteger)filter;
@end

@interface MHBeautyAssembleView : UIView

@property (nonatomic, weak) id<MHBeautyAssembleViewDelegate> delegate;
@property (nonatomic, assign)BOOL isTXSDK;//是否是腾讯SDK

- (void)configureUI;

@end

NS_ASSUME_NONNULL_END
