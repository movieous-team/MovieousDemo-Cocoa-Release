//
//  UINavigationController+Movieous.m
//  MovieousDemo
//
//  Created by Chris Wang on 2018/10/27.
//  Copyright © 2018 Movieous Team. All rights reserved.
//

#import "UINavigationController+Movieous.h"
#import <objc/runtime.h>

@implementation UINavigationController(Movieous)

- (BOOL)transparentNavigationBar {
    return [objc_getAssociatedObject(self, @selector(transparentNavigationBar)) boolValue];
}

- (void)setTransparentNavigationBar:(BOOL)transparentNavigationBar {
    if (transparentNavigationBar) {
        [self.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
        self.navigationBar.shadowImage = [UIImage new];
        self.navigationBar.translucent = YES;
        self.view.backgroundColor = [UIColor clearColor];
    }
    objc_setAssociatedObject(self, @selector(transparentNavigationBar), @(transparentNavigationBar), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
