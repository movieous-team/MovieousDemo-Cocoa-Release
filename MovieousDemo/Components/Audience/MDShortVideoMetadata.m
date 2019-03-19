//
//  MDShortVideoMetadata.m
//  MovieousDemo
//
//  Created by Chris Wang on 2018/10/2.
//  Copyright © 2018 Movieous Team. All rights reserved.
//

#import "MDShortVideoMetadata.h"

@implementation MDShortVideoMetadata

- (instancetype)initWithDic:(NSDictionary *)dic {
    if (self = [super init]) {
        self.authorAvatar = [NSString stringWithFormat:@"https:%@", [dic objectForKey:@"avatar"]];
        self.coverURL = [NSString stringWithFormat:@"https:%@", [dic objectForKey:@"video_img"]];
        self.videoURL = [NSString stringWithFormat:@"https:%@", [dic objectForKey:@"video_url"]];
        self.authorNickName = [dic objectForKey:@"nickname"];
        self.title = [dic objectForKey:@"desc"];
    }
    return self;
}

@end
