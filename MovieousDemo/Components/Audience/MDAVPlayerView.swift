//
//  MDAVPlayerView.swift
//  MovieousDemo
//
//  Created by Chris Wang on 2019/4/10.
//  Copyright © 2019 Movieous Team. All rights reserved.
//

import UIKit
import AVFoundation

class MDAVPlayerView: UIView {
    override class var layerClass: AnyClass {
        get {
            return AVPlayerLayer.self
        }
    }
    
    var videoGravity: AVLayerVideoGravity {
        set {
            (self.layer as! AVPlayerLayer).videoGravity = newValue
        }
        get {
            return (self.layer as! AVPlayerLayer).videoGravity
        }
    }
    
    var player: AVPlayer! {
        didSet {
            (self.layer as! AVPlayerLayer).player = self.player
        }
    }
}
