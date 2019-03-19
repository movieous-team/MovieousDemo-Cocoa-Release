//
//  MDShortVideoMetadata.h
//  MovieousDemo
//
//  Created by Chris Wang on 2018/10/2.
//  Copyright © 2018 Movieous Team. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MDShortVideoMetadata : NSObject

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *videoURL;
@property (nonatomic, strong) NSString *coverURL;
@property (nonatomic, strong) NSString *authorUID;
@property (nonatomic, strong) NSString *authorNickName;
@property (nonatomic, strong) NSString *authorAvatar;

- (instancetype)initWithDic:(NSDictionary *)dic;

@end
