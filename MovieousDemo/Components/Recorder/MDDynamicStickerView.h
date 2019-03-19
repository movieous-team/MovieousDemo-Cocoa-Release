//
//  MDDynamicStickerView.h
//  MovieousDemo
//
//  Created by Chris Wang on 2019/1/6.
//  Copyright © 2019 Movieous Team. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STStickerView.h"
#import "StickerPanelView.h"

NS_ASSUME_NONNULL_BEGIN

@interface MDDynamicStickerView : UIView

@property (strong, nonatomic) IBOutlet StickerPanelView *stickerPanelView;
@property (strong, nonatomic) IBOutlet UIView *FUView;
@property (strong, nonatomic) IBOutlet STStickerView *STView;

@end

NS_ASSUME_NONNULL_END
