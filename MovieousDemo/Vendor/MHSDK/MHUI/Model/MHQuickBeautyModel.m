//
//  MHQuickBeautyModel.m

#import "MHQuickBeautyModel.h"

@implementation MHQuickBeautyModel
+ (instancetype)mh_modelWithDictionary:(NSDictionary *)dic {
    MHQuickBeautyModel *model = [MHQuickBeautyModel new];
    model.title = [dic objectForKey:@"title"];
    model.whiteValue = [dic objectForKey:@"whiteValue"];
    model.buffingValue = [dic objectForKey:@"buffingValue"];
    model.ruddinessValue = [dic objectForKey:@"ruddinessValue"];
    model.bigEye_defaultValue = [dic objectForKey:@"bigEye_defaultValue"];
    model.bigEye_minValue = [dic objectForKey:@"bigEye_minValue"];
    model.bigEye_maxValue = [dic objectForKey:@"bigEye_maxValue"];
    model.eyeBrown_defaultValue = [dic objectForKey:@"eyeBrown_defaultValue"];
    model.eyeBrown_minValue = [dic objectForKey:@"eyeBrown_minValue"];
    model.eyeBrown_maxValue = [dic objectForKey:@"eyeBrown_maxValue"];
    model.eyeDistance_defaultValue = [dic objectForKey:@"eyeDistance_defaultValue"];
    model.eyeDistance_minValue = [dic objectForKey:@"eyeDistance_minValue"];
    model.eyeDistance_maxValue = [dic objectForKey:@"eyeDistance_maxValue"];
    model.eyeAngle_defaultValue = [dic objectForKey:@"eyeAngle_defaultValue"];
    model.eyeAngle_minValue = [dic objectForKey:@"eyeAngle_minValue"];
    model.eyeAngle_maxValue = [dic objectForKey:@"eyeAngle_maxValue"];
    model.face_defaultValue = [dic objectForKey:@"face_defaultValue"];
    model.face_minValue = [dic objectForKey:@"face_minValue"];
    model.face_maxValue = [dic objectForKey:@"face_maxValue"];
    model.mouth_defaultValue = [dic objectForKey:@"mouth_defaultValue"];
    model.mouth_minValue = [dic objectForKey:@"mouth_minValue"];
    model.mouth_maxValue = [dic objectForKey:@"mouth_maxValue"];
    model.nose_defaultValue = [dic objectForKey:@"nose_defaultValue"];
    model.nose_minValue = [dic objectForKey:@"nose_minValue"];
    model.nose_maxValue = [dic objectForKey:@"nose_maxValue"];
    model.chin_defaultValue = [dic objectForKey:@"chin_defaultValue"];
    model.chin_minValue = [dic objectForKey:@"chin_minValue"];
    model.chin_maxValue = [dic objectForKey:@"chin_maxValue"];
    model.forehead_defaultValue = [dic objectForKey:@"forehead_defaultValue"];
    model.forehead_minValue = [dic objectForKey:@"forehead_minValue"];
    model.forehead_maxValue = [dic objectForKey:@"forehead_maxValue"];
    model.longnose_defaultValue = [dic objectForKey:@"longnose_defaultValue"];
    model.longnose_minValue = [dic objectForKey:@"longnose_minValue"];
    model.longnose_maxValue = [dic objectForKey:@"longnose_maxValue"];
    model.shaveFace_defaultValue = [dic objectForKey:@"shaveFace_defaultValue"];
    model.shaveFace_minValue = [dic objectForKey:@"shaveFace_minValue"];
    model.shaveFace_maxValue = [dic objectForKey:@"shaveFace_maxValue"];
    model.eyeAlae_defaultValue = [dic objectForKey:@"eyeAlae_defaultValue"];
    model.eyeAlae_minValue = [dic objectForKey:@"eyeAlae_minValue"];
    model.eyeAlae_maxValue = [dic objectForKey:@"eyeAlae_maxValue"];
    
    return model;
}


@end
