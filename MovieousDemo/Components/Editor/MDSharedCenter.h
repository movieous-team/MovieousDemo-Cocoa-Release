//
//  MDSharedCenter.h
//  MovieousDemo
//
//  Created by Chris Wang on 2019/3/20.
//  Copyright © 2019 Movieous Team. All rights reserved.
//

#import <MovieousShortVideo/MovieousShortVideo.h>

@interface MDSharedCenter : NSObject

@property (nonatomic, strong) MSVEditor *editor;
@property (nonatomic, strong) MSVGraffitiView *graffitiView;
@property (nonatomic, strong) MSVRecorder *recorder;
@property (nonatomic, strong) MovieousFaceBeautyCaptureEffect *faceBeautyCaptureEffect;
@property (nonatomic, strong) MovieousLUTFilterCaptureEffect *LUTFilterCaptureEffect;

+ (instancetype)sharedCenter;

@end
