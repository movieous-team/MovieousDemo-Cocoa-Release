//
//  MDFilter.h
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

@interface MDFilter : NSObject
<
MovieousExternalFilter
>

@property (nonatomic, strong) NSMutableArray<MDSceneEffect *> *sceneEffects;

- (void)onCameraChanged;
- (void)setup;
- (void)dispose;

@end
