//
//  MDProgressBar.h
//  MSVShortVideoKitDemo
//
//  Created by Chris Wang on 17/2/28.
//  Copyright © 2017年 Movieous Team. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

typedef enum {
    MDProgressBarProgressStyleNormal,
    MDProgressBarProgressStyleDelete,
} MDProgressBarProgressStyle;

@interface MDProgressBar : UIView

@property (nonatomic, assign) MDProgressBarProgressStyle lastProgressStyle;

- (void)setLastProgressToWidth:(CGFloat)width;

- (void)deleteLastProgress;
- (void)deleteAllProgress;
- (void)addProgressView;

- (void)stopShining;
- (void)startShining;

@end

