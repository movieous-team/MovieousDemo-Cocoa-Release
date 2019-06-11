//
//  MDDynamicStickerView.m
//  MovieousDemo
//
//  Created by Chris Wang on 2019/1/6.
//  Copyright © 2019 Movieous Team. All rights reserved.
//

#import "MDDynamicStickerView.h"
#import "STManager.h"
#import "FUManager.h"
#import "TuSDKManager.h"
#import "MDGlobalSettings.h"
#import "MDSharedCenter.h"

@interface MDDynamicStickerView ()
<
StickerPanelViewDelegate
>

@end

@implementation MDDynamicStickerView

- (void)awakeFromNib {
    [super awakeFromNib];
    if (MDGlobalSettings.sharedInstance.vendorType == VendorTypeFaceunity) {
        _FUView.hidden = NO;
    } else if (MDGlobalSettings.sharedInstance.vendorType == VendorTypeSenseTime) {
        _STView.hidden = NO;
    } else if (MDGlobalSettings.sharedInstance.vendorType == VendorTypeTuSDK) {
        _stickerPanelView.hidden = NO;
        _stickerPanelView.delegate = self;
    }
}

- (void)stickerPanel:(StickerPanelView *)stickerPanel didSelectSticker:(TuSDKPFStickerGroup *)sticker {
    [TuSDKManager.sharedManager handleStickerChange:sticker];
}

@end
