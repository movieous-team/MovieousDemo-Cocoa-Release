//
//  MDGradientView.m
//  MovieousDemo
//
//  Created by Chris Wang on 2018/10/9.
//  Copyright © 2018 Movieous Team. All rights reserved.
//

#import "MDGradientView.h"

@implementation MDGradientView

+ (Class)layerClass {
    return CAGradientLayer.class;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    CAGradientLayer *layer = (CAGradientLayer *)self.layer;
    [layer setColors:@[(id)RGBA_COLOR(0, 231, 207, 100).CGColor, (id)RGBA_COLOR(0, 115, 254, 100).CGColor]];
    layer.startPoint = CGPointMake(0.5, 0);
    layer.endPoint = CGPointMake(0.5, 1);
    return self;
}

@end
