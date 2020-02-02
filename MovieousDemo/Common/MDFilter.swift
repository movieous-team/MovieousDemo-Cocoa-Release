//
//  MDFilter.swift
//  MovieousDemo
//
//  Created by Chris Wang on 2019/6/20.
//  Copyright © 2019 Movieous Team. All rights reserved.
//

import UIKit
import MovieousShortVideo

class MDFilter: NSObject, MovieousExternalFilter {
    static let shared = MDFilter()
    static func sharedInstance() -> MovieousExternalFilter {
        return shared
    }
    let lock = NSRecursiveLock()
    weak var draft: MSVDraft?
    var beautyManager = MHBeautyManager()
    
    func processImage(_ image: UIImage) -> UIImage {
        return image
    }
    
    func processPixelBuffer(_ pixelBuffer: CVPixelBuffer, sampleTimingInfo: CMSampleTimingInfo) -> Unmanaged<CVPixelBuffer> {
        self.lock.lock()
        let retPixelBuffer = beautyManager.processPixelBuffer(pixelBuffer, sampleTimingInfo: sampleTimingInfo)
        self.lock.unlock()
        return retPixelBuffer
    }
}
