//
//  UIView+Adapter.m
//  MovieousDemo
//
//  Created by Chris Wang on 2018/10/9.
//  Copyright © 2018 Movieous Team. All rights reserved.
//

#import "UIView+MDExtension.h"
#import <objc/runtime.h>

@implementation UIView(MDExtension)

- (CGFloat)cornerRadius {
    return [objc_getAssociatedObject(self, @selector(cornerRadius)) floatValue];
}

- (void)setCornerRadius:(CGFloat)cornerRadius {
    self.layer.cornerRadius = cornerRadius;
    self.layer.masksToBounds = YES;
    objc_setAssociatedObject(self, @selector(cornerRadius), @(cornerRadius), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)adaptive {
    NSNumber *value = objc_getAssociatedObject(self, @selector(adaptive));
    return [value boolValue];
}

- (void)setAdaptive:(BOOL)adaptive {
    if(adaptive) {
        self.layer.cornerRadius = kViewHeightRate * self.layer.cornerRadius;
    }
    objc_setAssociatedObject(self, @selector(adaptive), @(adaptive), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(UIImage*)convertToImage {
    CGSize s = self.bounds.size;
    // 下面方法，第一个参数表示区域大小。第二个参数表示是否是非透明的。如果需要显示半透明效果，需要传NO，否则传YES。第三个参数就是屏幕密度了
    UIGraphicsBeginImageContextWithOptions(s, NO, [UIScreen mainScreen].scale);
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
