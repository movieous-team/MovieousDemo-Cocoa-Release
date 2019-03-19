//
//  UIView+Adapter.h
//  MovieousDemo
//
//  Created by Chris Wang on 2018/10/9.
//  Copyright © 2018 Movieous Team. All rights reserved.
//

#import <UIKit/UIKit.h>

IB_DESIGNABLE
@interface UIView(MDExtension)

@property (nonatomic, assign) IBInspectable BOOL adaptive;
@property (nonatomic, assign) IBInspectable CGFloat cornerRadius;

- (UIImage *)convertToImage;

@end
