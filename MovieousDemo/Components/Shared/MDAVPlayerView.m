//
//  MDAVPlayerView.m
//  MovieousDemo
//
//  Created by Chris Wang on 2019/3/10.
//  Copyright © 2019 Movieous Team. All rights reserved.
//

#import "MDAVPlayerView.h"

@implementation MDAVPlayerView

+ (Class)layerClass {
    return AVPlayerLayer.class;
}

+ (instancetype)playerViewWithPlayer:(AVPlayer *)player {
    return [[self alloc] initWithPlayer:player];
}

- (instancetype)initWithPlayer:(AVPlayer *)player {
    if (self = [super init]) {
        ((AVPlayerLayer *)self.layer).player = player;
    }
    return self;
}

- (AVLayerVideoGravity)videoGravity {
    return ((AVPlayerLayer *)self.layer).videoGravity;
}

- (void)setVideoGravity:(AVLayerVideoGravity)videoGravity {
    ((AVPlayerLayer *)self.layer).videoGravity = videoGravity;
}

@end
