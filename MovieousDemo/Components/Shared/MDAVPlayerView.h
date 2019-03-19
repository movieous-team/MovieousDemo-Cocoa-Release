//
//  MDAVPlayerView.h
//  MovieousDemo
//
//  Created by Chris Wang on 2019/3/10.
//  Copyright © 2019 Movieous Team. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MDAVPlayerView : UIView

@property(copy) AVLayerVideoGravity videoGravity;

+ (instancetype)playerViewWithPlayer:(AVPlayer *)player;

- (instancetype)initWithPlayer:(AVPlayer *)player;

@end

NS_ASSUME_NONNULL_END
