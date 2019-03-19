//
//  MDFrameView.m
//  MovieousDemo
//
//  Created by Chris Wang on 2019/2/27.
//  Copyright © 2019 Movieous Team. All rights reserved.
//

#import "MDFrameView.h"

@implementation MDFrameView

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        _frameWidth = 1;
    }
    return self;
}

- (void)layoutSubviews {
    self.backgroundColor = [UIColor clearColor];
    [super layoutSubviews];
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    // Drawing code
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [UIColor.whiteColor setStroke];
    CGContextSetLineWidth(ctx, _frameWidth);
    NSInteger halfFrameWidth = _frameWidth / 2;
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(_margin, _margin + halfFrameWidth)];
    [path addLineToPoint:CGPointMake(rect.size.width - _margin, _margin + halfFrameWidth)];
    [path moveToPoint:CGPointMake(rect.size.width - _margin - halfFrameWidth, _margin + halfFrameWidth)];
    [path addLineToPoint:CGPointMake(rect.size.width - _margin - halfFrameWidth, rect.size.height - _margin)];
    [path moveToPoint:CGPointMake(rect.size.width - _margin - halfFrameWidth, rect.size.height - _margin - halfFrameWidth)];
    [path addLineToPoint:CGPointMake(_margin, rect.size.height - _margin - halfFrameWidth)];
    [path moveToPoint:CGPointMake(_margin + halfFrameWidth, rect.size.height - _margin - halfFrameWidth)];
    [path addLineToPoint:CGPointMake(_margin + halfFrameWidth, _margin)];
    CGContextAddPath(ctx, path.CGPath);
    CGContextSetBlendMode(ctx, kCGBlendModeCopy);
    CGContextStrokePath(ctx);
}

- (void)setFrameWidth:(CGFloat)frameWidth {
    _frameWidth = frameWidth;
    [self setNeedsDisplay];
}

- (void)setMargin:(CGFloat)margin {
    _margin = margin;
    [self setNeedsDisplay];
}

@end
