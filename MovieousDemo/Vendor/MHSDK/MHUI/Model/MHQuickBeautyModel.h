//
//  MHQuickBeautyModel.h


#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN

@interface MHQuickBeautyModel : NSObject
@property (nonatomic, assign) NSInteger  quickBeautyType;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *whiteValue;
@property (nonatomic, copy) NSString *buffingValue;
@property (nonatomic, copy) NSString *ruddinessValue;
@property (nonatomic, copy) NSString *bigEye_defaultValue;
@property (nonatomic, copy) NSString *bigEye_minValue;
@property (nonatomic, copy) NSString *bigEye_maxValue;
@property (nonatomic, copy) NSString *eyeBrown_defaultValue;
@property (nonatomic, copy) NSString *eyeBrown_minValue;
@property (nonatomic, copy) NSString *eyeBrown_maxValue;
@property (nonatomic, copy) NSString *eyeDistance_defaultValue;
@property (nonatomic, copy) NSString *eyeDistance_minValue;
@property (nonatomic, copy) NSString *eyeDistance_maxValue;
@property (nonatomic, copy) NSString *eyeAngle_defaultValue;
@property (nonatomic, copy) NSString *eyeAngle_minValue;
@property (nonatomic, copy) NSString *eyeAngle_maxValue;
@property (nonatomic, copy) NSString *face_defaultValue;
@property (nonatomic, copy) NSString *face_minValue;
@property (nonatomic, copy) NSString *face_maxValue;
@property (nonatomic, copy) NSString *mouth_defaultValue;
@property (nonatomic, copy) NSString *mouth_minValue;
@property (nonatomic, copy) NSString *mouth_maxValue;
@property (nonatomic, copy) NSString *nose_defaultValue;
@property (nonatomic, copy) NSString *nose_minValue;
@property (nonatomic, copy) NSString *nose_maxValue;
@property (nonatomic, copy) NSString *chin_defaultValue;
@property (nonatomic, copy) NSString *chin_minValue;
@property (nonatomic, copy) NSString *chin_maxValue;
@property (nonatomic, copy) NSString *forehead_defaultValue;
@property (nonatomic, copy) NSString *forehead_minValue;
@property (nonatomic, copy) NSString *forehead_maxValue;
@property (nonatomic, copy) NSString *longnose_defaultValue;
@property (nonatomic, copy) NSString *longnose_minValue;
@property (nonatomic, copy) NSString *longnose_maxValue;
@property (nonatomic, copy) NSString *shaveFace_defaultValue;
@property (nonatomic, copy) NSString *shaveFace_minValue;
@property (nonatomic, copy) NSString *shaveFace_maxValue;
@property (nonatomic, copy) NSString *eyeAlae_defaultValue;
@property (nonatomic, copy) NSString *eyeAlae_minValue;
@property (nonatomic, copy) NSString *eyeAlae_maxValue;
@property (nonatomic, copy) NSString *imgName;
@property (nonatomic, assign) BOOL isSelected;
+ (instancetype)mh_modelWithDictionary:(NSDictionary *)dic;

@end

NS_ASSUME_NONNULL_END
