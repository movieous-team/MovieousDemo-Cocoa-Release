//
//  NSArray+MDExtension.m
//  MovieousDemo
//
//  Created by Chris Wang on 2019/1/9.
//  Copyright © 2019 Movieous Team. All rights reserved.
//

#import "NSArray+MDExtension.h"
#import <UIKit/UIKit.h>

@implementation NSArray(MDExtension)

- (void)setHidden:(BOOL)hidden {
    for (UIView *view in self) {
        view.hidden = hidden;
    }
}

- (BOOL)hidden {
    return ((UIView *)self[0]).hidden;
}

@end
