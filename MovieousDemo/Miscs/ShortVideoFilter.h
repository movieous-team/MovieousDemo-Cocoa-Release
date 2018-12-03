//
//  ShortVideoFilter.h
//  MovieousDemo
//
//  Created by Chris Wang on 2018/10/23.
//  Copyright © 2018 Movieous Team. All rights reserved.
//

#import <MovieousShortVideo/MovieousShortVideo.h>
#import "TuSDKFramework.h"

@interface SceneEffect : NSObject

@property (nonatomic, strong) NSString *sceneCode;
@property (nonatomic, assign) MovieousTimeRange timeRange;

@end

@interface ShortVideoFilter : NSObject
<
MSVExternalFilter
>

@property (nonatomic, strong) NSMutableArray<SceneEffect *> *sceneEffects;
@property (nonatomic, strong) TuSDKFilterProcessor *filterProcessor;

@end
