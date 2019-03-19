//
//  MDShortVideoFilter.h
//  MovieousDemo
//
//  Created by Chris Wang on 2018/10/23.
//  Copyright © 2018 Movieous Team. All rights reserved.
//

#import <MovieousShortVideo/MovieousShortVideo.h>

@interface MDSceneEffect : NSObject

@property (nonatomic, strong) NSString *sceneCode;
@property (nonatomic, assign) MovieousTimeRange timeRange;

@end

@interface MDShortVideoFilter : NSObject
<
MSVExternalFilter
>

@property (nonatomic, strong) NSMutableArray<MDSceneEffect *> *sceneEffects;

@end
