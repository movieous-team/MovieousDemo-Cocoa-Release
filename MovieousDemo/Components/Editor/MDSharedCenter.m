//
//  MDSharedCenter.m
//  MovieousDemo
//
//  Created by Chris Wang on 2019/3/20.
//  Copyright © 2019 Movieous Team. All rights reserved.
//

#import "MDSharedCenter.h"

@implementation MDSharedCenter

+ (instancetype)sharedCenter {
    static dispatch_once_t onceToken;
    static MDSharedCenter *instance;
    dispatch_once(&onceToken, ^{
        instance = [MDSharedCenter new];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        KWRenderManager *renderManager = [[KWRenderManager alloc] initWithModelPath:nil isCameraPositionBack:NO];
        [renderManager loadRender];
        renderManager.maxFaceNumber = 5;
        _kwUIManager = [[KWUIManager alloc] initWithRenderManager:renderManager delegate:nil superView:nil];
        [_kwUIManager enableBigEyeSlimChin:YES];
        [_kwUIManager enableBeautyFilter:YES];
    }
    return self;
}

@end
