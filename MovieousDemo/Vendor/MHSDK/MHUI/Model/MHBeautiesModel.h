//
//  MHBeautiesModel.h
//  TXLiteAVDemo_UGC
//
//  Created by apple on 2019/12/20.
//  Copyright © 2019 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSInteger, MHBeautyMenuType){
    MHBeautyMenuType_Menu = 0,//菜单
    MHBeautyMenuType_Beauty = 1,//美颜
    MHBeautyMenuType_Face = 2,//美型
    MHBeautyMenuType_Filter,//滤镜
    MHBeautyMenuType_Specify,//特效
    MHBeautyMenuType_Magnify,//哈哈镜
    MHBeautyMenuType_Watermark//水印
};
@interface MHBeautiesModel : NSObject
@property (nonatomic, copy) NSString *imgName;
@property (nonatomic, copy) NSString *beautyTitle;
@property (nonatomic, assign) MHBeautyMenuType menuType;
@property (nonatomic, assign) BOOL isSelected;
@property (nonatomic, copy) NSString *originalValue;//美颜美型默认值
@property (nonatomic, assign) NSInteger type;//类型
@property (nonatomic, assign) NSInteger aliment;//水印位置

@end

NS_ASSUME_NONNULL_END
