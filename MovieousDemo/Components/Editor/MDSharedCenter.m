//
//  MDSharedCenter.m
//  MovieousDemo
//
//  Created by Chris Wang on 2019/3/20.
//  Copyright © 2019 Movieous Team. All rights reserved.
//

#import "MDSharedCenter.h"

@implementation MDSharedCenter

+ (instancetype)sharedCenter {
    static dispatch_once_t onceToken;
    static MDSharedCenter *instance;
    dispatch_once(&onceToken, ^{
        instance = [MDSharedCenter new];
    });
    return instance;
}

@end
