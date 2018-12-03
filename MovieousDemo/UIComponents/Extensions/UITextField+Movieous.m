//
//  UITextField+Movieous.m
//  MovieousDemo
//
//  Created by Chris Wang on 2018/10/9.
//  Copyright © 2018 Movieous Team. All rights reserved.
//

#import "UITextField+Movieous.h"
#import <objc/runtime.h>

@implementation UITextField(Movieous)

- (CGFloat)leftViewWidth {
    return [objc_getAssociatedObject(self, @selector(leftViewWidth)) floatValue];
}

- (void)setLeftViewWidth:(CGFloat)leftViewWidth {
    self.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, leftViewWidth * kViewWidthRate, self.frame.size.height)];
    self.leftViewMode = UITextFieldViewModeAlways;
    objc_setAssociatedObject(self, @selector(leftViewWidth), @(leftViewWidth), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGFloat)rightViewWidth {
    return [objc_getAssociatedObject(self, @selector(rightViewWidth)) floatValue];
}

- (void)setRightViewWidth:(CGFloat)rightViewWidth {
    self.rightView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, rightViewWidth * kViewWidthRate, self.frame.size.height)];
    self.rightViewMode = UITextFieldViewModeAlways;
    objc_setAssociatedObject(self, @selector(rightViewWidth), @(rightViewWidth), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
