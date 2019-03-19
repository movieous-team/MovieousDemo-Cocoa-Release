//
//  MDSlider.m
//  MovieousDemo
//
//  Created by Chris Wang on 2019/1/9.
//  Copyright © 2019 Movieous Team. All rights reserved.
//

#import "MDSlider.h"

@implementation MDSlider

- (void)awakeFromNib {
    [super awakeFromNib];
    UIImage *image = [UIImage imageNamed:@"Oval"];
    [self setThumbImage:image forState:UIControlStateNormal];
    [self setThumbImage:image forState:UIControlStateHighlighted];
}

@end
