//
//  UIButton+Adapter.m
//  MovieousDemo
//
//  Created by Chris Wang on 2018/10/9.
//  Copyright © 2018 Movieous Team. All rights reserved.
//

#import "UIButton+Movieous.h"
#import <objc/runtime.h>
#import "UIView+Movieous.h"

@implementation UIButton(Movieous)

- (BOOL)adaptive {
    NSNumber *value = objc_getAssociatedObject(self, @selector(adaptive));
    return [value boolValue];
}

- (void)setAdaptive:(BOOL)adaptive {
    super.adaptive = adaptive;
    if(adaptive) {
        self.titleLabel.font = [UIFont systemFontOfSize:self.titleLabel.font.pointSize * kViewHeightRate];
    }
    objc_setAssociatedObject(self, @selector(adaptive), @(adaptive), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
