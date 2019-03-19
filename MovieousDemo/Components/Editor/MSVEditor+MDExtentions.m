//
//  MSVEditor+MDExtentions.m
//  MovieousDemo
//
//  Created by Chris Wang on 2018/10/27.
//  Copyright © 2018 Movieous Team. All rights reserved.
//

#import "MSVEditor+MDExtentions.h"

static MSVEditor *editor;

@implementation MSVEditor(MDExtentions)

+ (instancetype)createSharedInstanceWithDraft:(MSVDraft *)draft error:(NSError **)outError {
    editor = [[MSVEditor alloc] initWithDraft:draft error:outError];
    return editor;
}

+ (void)clearSharedInstance {
    editor = nil;
}

+ (instancetype)sharedInstance {
    return editor;
}

@end
