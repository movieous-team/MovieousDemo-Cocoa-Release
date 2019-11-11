//
//  MDFilter.swift
//  MovieousDemo
//
//  Created by Chris Wang on 2019/6/20.
//  Copyright © 2019 Movieous Team. All rights reserved.
//

import UIKit
import MovieousShortVideo

class MDSceneEffect: NSObject {
    var sceneCode: String?
    var timeRange: MovieousTimeRange
    
    init(sceneCode: String?, timeRange: MovieousTimeRange) {
        self.sceneCode = sceneCode
        self.timeRange = timeRange
        super.init()
    }
}

class MDFilter: NSObject, MovieousExternalFilter {
    static let shared = MDFilter()
    static func sharedInstance() -> MovieousExternalFilter {
        return shared
    }
    let lock = NSRecursiveLock()
    var sceneEffects: [MDSceneEffect] = []
    var isSetup = false
    weak var draft: MSVDraft?
    
    func setup() {
        self.lock.lock()
        if self.isSetup {
            self.lock.unlock()
            return
        }
        self.isSetup = true
        switch vendorType {
        case .faceunity:
            FUManager.share().loadFilter()
            FUManager.share().setAsyncTrackFaceEnable(false)
        case .sensetime:
            STManager.shared().createResources()
        case .tusdk:
            TuSDKManager.shared().setupResources()
        default:
            break
        }
        self.lock.unlock()
    }
    
    func dispose() {
        self.lock.lock()
        if !self.isSetup {
            self.lock.unlock()
            return
        }
        self.isSetup = false
        switch vendorType {
        case .faceunity:
            FUManager.share().destoryItems()
        case .sensetime:
            STManager.shared().releaseResources()
        case .tusdk:
            TuSDKManager.shared().releaseResources()
        default:
            break
        }
        self.lock.unlock()
    }
    
    func onCameraChanged() {
        self.lock.lock()
        if vendorType == .faceunity {
            FUManager.share().onCameraChange()
        }
        self.lock.unlock()
    }
    
    func processImage(_ image: UIImage) -> UIImage {
        self.lock.lock()
        if !self.isSetup {
            self.lock.unlock()
            return image
        }
        
        switch vendorType {
        case .faceunity:
            let ret = FUManager.share()!.renderItems(to: image)!
            self.lock.unlock()
            return ret
        default:
            self.lock.unlock()
            return image
        }
    }
    
    func processPixelBuffer(_ pixelBuffer: CVPixelBuffer, sampleTimingInfo: CMSampleTimingInfo) -> Unmanaged<CVPixelBuffer> {
        var retPixelBuffer = Unmanaged.passUnretained(pixelBuffer)
        self.lock.lock()
        if !self.isSetup {
            self.lock.unlock()
            return retPixelBuffer
        }
        var time = CMTimeGetSeconds(sampleTimingInfo.presentationTimeStamp)
        // 将 time 换算到 originalMainTrackClip 的时间轴上
        if let draft = self.draft {
            let originalMainTrackClip = (draft.getAttachmentForKey(MDOriginalMainTrackClipKey)! as! MSVMainTrackClip)
            if let speedEffect = draft.getAttachmentForKey(MDSpeedEffectKey) as! MDSpeedEffect? {
                time = speedEffect.removeFromTime(time: time)
            } else if let repeateEffect = draft.getAttachmentForKey(MDRepeateEffectKey) as! MDRepeateEffect? {
                time = repeateEffect.removeFromTime(time: time, totalDurationAtMainTrack: originalMainTrackClip.durationAtMainTrack)
            }
            time = originalMainTrackClip.timeRange.startTime + time * Double(originalMainTrackClip.speed)
        }
        
        switch vendorType {
        case .faceunity:
            var sceneCode: String?
            for i in (0..<self.sceneEffects.count).reversed() {
                let effect = self.sceneEffects[i]
                if MovieousTimeRangeIsEqual(effect.timeRange, kMovieousTimeRangeDefault) ||
                (time >= effect.timeRange.startTime && time <= effect.timeRange.startTime + effect.timeRange.duration) {
                    sceneCode = effect.sceneCode
                    break
                }
            }
            if let sceneCode = sceneCode {
                if FUManager.share().selectedMusicFilter != sceneCode {
                    FUManager.share().loadMusicItem(sceneCode)
                }
                FUManager.share().setMusicTime(time)
            } else {
                if FUManager.share().selectedMusicFilter != "noitem" {
                    FUManager.share().loadMusicItem("noitem")
                }
            }
            retPixelBuffer = FUManager.share().renderItems(to: pixelBuffer)
        case .sensetime:
            retPixelBuffer = STManager.shared().processPixelBuffer(pixelBuffer)
        case .tusdk:
            var sceneCode: String?
            for effect in self.sceneEffects {
                if (MovieousTimeRangeIsEqual(effect.timeRange, kMovieousTimeRangeDefault) ||
                    (time >= effect.timeRange.startTime && time <= effect.timeRange.startTime + effect.timeRange.duration)) {
                    sceneCode = effect.sceneCode
                }
            }
            TuSDKManager.shared().removeMediaEffects(with: .scene)
            if let sceneCode = sceneCode {
                let effectData = TuSDKMediaSceneEffectData(effectsCode: sceneCode)!
                effectData.atTimeRange = TuSDKTimeRange.make(withStart: .zero, end: CMTime(value: LLONG_MAX, timescale: 1))
                TuSDKManager.shared().addMediaEffect(effectData)
            }
            retPixelBuffer = TuSDKManager.shared().syncProcessPixelBuffer(pixelBuffer, frameTime: sampleTimingInfo.presentationTimeStamp)
            TuSDKManager.shared().destroyFrameData()
//        case .kiwi:
//            KWRenderManager.processPixelBuffer(pixelBuffer)
        default:
            break
        }
        self.lock.unlock()
        return retPixelBuffer
    }
}
