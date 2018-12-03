//
//  RecorderMusicViewController.h
//  MovieousDemo
//
//  Created by Chris Wang on 2018/10/13.
//  Copyright © 2018 Movieous Team. All rights reserved.
//

// 录制界面选择背景音乐页面

#import <UIKit/UIKit.h>

@class RecorderMusicViewController;
@protocol RecorderMusicViewControllerDelegate <NSObject>

- (void)controller:(RecorderMusicViewController *)controller didSelectMusicPath:(NSString *)musicPath;

@end

@interface RecorderMusicViewController : UITableViewController

@property (nonatomic, weak) id<RecorderMusicViewControllerDelegate> delegate;

@end
