//
//  NSLayoutConstraint+Extension.m
//  MovieousDemo
//
//  Created by Chris Wang on 2018/10/8.
//  Copyright © 2018 Movieous Team. All rights reserved.
//

/// 源自 https://www.jianshu.com/p/e0775043af3e

#import "NSLayoutConstraint+Movieous.h"
#import <objc/runtime.h>

@implementation NSLayoutConstraint(Movieous)

- (BOOL)widthAdaptive {
    NSNumber *value = objc_getAssociatedObject(self, @selector(widthAdaptive));
    return [value boolValue];
}

- (void)setWidthAdaptive:(BOOL)widthAdaptive {
    if(widthAdaptive) {
        self.constant *= kViewWidthRate;
    }
    objc_setAssociatedObject(self, @selector(widthAdaptive), @(widthAdaptive), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)heightAdaptive {
    NSNumber *value = objc_getAssociatedObject(self, @selector(heightAdaptive));
    return [value boolValue];
}

- (void)setHeightAdaptive:(BOOL)heightAdaptive {
    if(heightAdaptive){
        self.constant *= kViewHeightRate;
    }
    objc_setAssociatedObject(self, @selector(heightAdaptive), @(heightAdaptive), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
