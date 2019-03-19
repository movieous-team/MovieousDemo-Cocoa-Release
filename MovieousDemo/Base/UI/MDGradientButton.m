//
//  MDGradientButton.m
//  MovieousDemo
//
//  Created by Chris Wang on 2018/10/9.
//  Copyright © 2018 Movieous Team. All rights reserved.
//

#import "MDGradientButton.h"

@implementation MDGradientButton

+ (Class)layerClass {
    return CAGradientLayer.class;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    CAGradientLayer *layer = (CAGradientLayer *)self.layer;
    [layer setColors:@[(id)[UIColor colorWithRed:0 green:158.0/255 blue:231.0/255 alpha:1].CGColor, (id)[UIColor colorWithRed:0 green:229.0/255 blue:204.0/255 alpha:1].CGColor]];
    layer.startPoint = CGPointMake(0, 0.5);
    layer.endPoint = CGPointMake(1, 0.5);
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
