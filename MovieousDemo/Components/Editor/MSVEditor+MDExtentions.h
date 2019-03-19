//
//  MSVEditor+MDExtentions.h
//  MovieousDemo
//
//  Created by Chris Wang on 2018/10/27.
//  Copyright © 2018 Movieous Team. All rights reserved.
//

#import <MovieousShortVideo/MovieousShortVideo.h>

@interface MSVEditor(MDExtentions)

+ (instancetype)createSharedInstanceWithDraft:(MSVDraft *)draft error:(NSError **)outError;
+ (void)clearSharedInstance;
+ (instancetype)sharedInstance;

@end
