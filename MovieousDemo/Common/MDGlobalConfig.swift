//
//  MDGlobalConfig.swift
//  MovieousDemo
//
//  Created by Chris Wang on 2019/6/21.
//  Copyright © 2019 Movieous Team. All rights reserved.
//

import Foundation

enum MDVendorType: Int {
    case none
}

let MDServerHost = "https://demo.movieous.cn"
let MDColorA = UIColor(r: 0x0e, g: 0xe3, b: 0xcf, a: 1)

extension NSNotification.Name {
    public static let MDShowHint: NSNotification.Name = .init("ShowHint")
}

let MDHintNotificationKey = "hint"

let MDOriginalMainTrackClipKey = "MDOriginalMainTrackClipKey"
let MDReversedVideoPathKey = "MDReversedVideoURLKey"
let MDSpeedEffectKey = "MDSpeedEffectKey"
let MDRepeateEffectKey = "MDRepeateEffectKey"
let MDReverseEffectKey = "MDReverseEffectKey"

let MDVideoFrameRate = 30.0
let MDDefaultDurationPerThumbnail = TimeInterval(2)
let MDMaxDurationPerThumbnail = TimeInterval(10)
let MDThumbnailBarHeight = TimeInterval(50)

var vendorType: MDVendorType = .none

func getVendorName(vendorType: MDVendorType) -> String {
    switch vendorType {
    case .none:
        return NSLocalizedString("MDGlobalConfig.vendor.none", comment: "")
    }
}
