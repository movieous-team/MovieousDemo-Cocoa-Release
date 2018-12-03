//
//  NSLayoutConstraint+Extension.h
//  MovieousDemo
//
//  Created by Chris Wang on 2018/10/8.
//  Copyright © 2018 Movieous Team. All rights reserved.
//

#import <UIKit/UIKit.h>

IB_DESIGNABLE
@interface NSLayoutConstraint(Movieous)

@property (nonatomic, assign) IBInspectable BOOL widthAdaptive;

@property (nonatomic, assign) IBInspectable BOOL heightAdaptive;

@end
