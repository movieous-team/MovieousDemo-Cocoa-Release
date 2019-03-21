//
//  MDSharedCenter.h
//  MovieousDemo
//
//  Created by Chris Wang on 2019/3/20.
//  Copyright © 2019 Movieous Team. All rights reserved.
//

#import <MovieousShortVideo/MovieousShortVideo.h>

@interface MDSharedCenter : NSObject

@property (nonatomic, strong, readonly) MSVEditor *editor;
@property (nonatomic, strong, readonly) MSVGraffitiView *graffitiView;

+ (instancetype)sharedCenter;

- (void)instantiateProperties;

- (void)clearProperties;

@end
