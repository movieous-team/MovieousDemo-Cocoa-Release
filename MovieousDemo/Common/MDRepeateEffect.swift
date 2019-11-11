//
//  MDRepeateEffect.swift
//  MovieousDemo
//
//  Created by Chris Wang on 2019/8/6.
//  Copyright © 2019 Movieous Team. All rights reserved.
//

import UIKit
import MovieousShortVideo

class MDRepeateEffect {
    var timeRangeAtMainTrack: MovieousTimeRange!
    var repeateCount: UInt!
    
    func applyOnTime(time: TimeInterval, numberOfRepeate: UInt, totalDurationAtMainTrack: TimeInterval) -> TimeInterval {
        var startTime = self.timeRangeAtMainTrack.startTime
        if startTime < 0 {
            startTime = 0
        }
        var endTime = self.timeRangeAtMainTrack.startTime + self.timeRangeAtMainTrack.duration
        if endTime > totalDurationAtMainTrack {
            endTime = totalDurationAtMainTrack
        }
        let effectiveDuration = endTime - startTime
        if effectiveDuration <= 0 {
            return time
        }
        if (time > startTime && time < startTime + effectiveDuration) {
            return time + Double(numberOfRepeate - 1) * effectiveDuration
        } else if (time >= startTime + effectiveDuration - .ulpOfOne) {
            return time + Double(self.repeateCount - 1) * effectiveDuration
        } else {
            return time
        }
    }
    
    func removeFromTime(time: TimeInterval, totalDurationAtMainTrack: TimeInterval) -> TimeInterval {
        var startTime = self.timeRangeAtMainTrack.startTime
        if startTime < 0 {
            startTime = 0
        }
        var endTime = self.timeRangeAtMainTrack.startTime + self.timeRangeAtMainTrack.duration
        if endTime > totalDurationAtMainTrack {
            endTime = totalDurationAtMainTrack
        }
        let effectiveDuration = endTime - startTime
        if effectiveDuration <= 0 {
            return time
        }
        var loop = UInt(0)
        if (time >= startTime + effectiveDuration - .ulpOfOne) {
            loop = UInt((time - startTime) / effectiveDuration)
            if (loop >= self.repeateCount) {
                loop = self.repeateCount - 1
            }
        }
        return time - effectiveDuration * Double(loop)
    }
    
    func applyOnMainTrackClips(mainTrackClips: [MSVMainTrackClip]) -> [MSVMainTrackClip] {
        var totalDurationAtMainTrack: TimeInterval = 0
        for mainTrackClip in mainTrackClips {
            totalDurationAtMainTrack += mainTrackClip.durationAtMainTrack
        }
        var effectStartTime = self.timeRangeAtMainTrack.startTime
        if effectStartTime < 0 {
            effectStartTime = 0
        }
        var effectEndTime = self.timeRangeAtMainTrack.startTime + self.timeRangeAtMainTrack.duration
        if effectEndTime > totalDurationAtMainTrack {
            effectEndTime = totalDurationAtMainTrack
        }
        if effectEndTime <= effectStartTime {
            return mainTrackClips
        }
        var mainTrackTimePointer: TimeInterval = 0
        var resultMainTrackClips: [MSVMainTrackClip] = []
        var repeatMainTrackClips: [MSVMainTrackClip] = []
        for clip in mainTrackClips {
            let clipEndTime = mainTrackTimePointer + clip.durationAtMainTrack
            // 处于效果区间以下
            if clipEndTime <= effectStartTime {
                resultMainTrackClips.append(clip.copy() as! MSVMainTrackClip)
                // 处于效果区间以上
            } else if mainTrackTimePointer >= effectEndTime {
                // 如果效果的结束点与片段连接处相同，那么可能出现没有触发添加重复片段的流程
                if repeatMainTrackClips.count > 0 {
                    for _ in 0 ..< self.repeateCount {
                        resultMainTrackClips.append(contentsOf: repeatMainTrackClips)
                    }
                    repeatMainTrackClips.removeAll()
                }
                resultMainTrackClips.append(clip.copy() as! MSVMainTrackClip)
                // 完全处于效果区间内的片段不用被切割
            } else if mainTrackTimePointer >= effectStartTime && clipEndTime <= effectEndTime {
                repeatMainTrackClips.append(clip.copy() as! MSVMainTrackClip)
            } else {
                // 仅被效果开始时间点切割的片段
                if mainTrackTimePointer < effectStartTime && clipEndTime <= effectEndTime {
                    if clip.type == .AV {
                        // 不在效果区间内的那部分
                        let newClipA = clip.copy() as! MSVMainTrackClip
                        newClipA.timeRange = .init(startTime: clip.timeRange.startTime, duration: (effectStartTime - mainTrackTimePointer) * Double(clip.speed))
                        resultMainTrackClips.append(newClipA)
                        // 在效果区间内的那部分
                        let newClipB = clip.copy() as! MSVMainTrackClip
                        newClipB.timeRange = .init(startTime: clip.timeRange.startTime + (effectStartTime - mainTrackTimePointer) * Double(clip.speed), duration: (clipEndTime - effectStartTime) * Double(clip.speed))
                        repeatMainTrackClips.append(newClipB)
                    } else {
                        // 不在效果区间内的那部分
                        let newClipA = clip.copy() as! MSVMainTrackClip
                        newClipA.durationAtMainTrack = effectStartTime - mainTrackTimePointer
                        resultMainTrackClips.append(newClipA)
                        // 在效果区间内的那部分
                        let newClipB = clip.copy() as! MSVMainTrackClip
                        newClipB.durationAtMainTrack = clipEndTime - effectStartTime
                        repeatMainTrackClips.append(newClipB)
                    }
                    // 仅被效果结束时间点切割的片段
                } else if mainTrackTimePointer >= effectStartTime && clipEndTime > effectEndTime {
                    if clip.type == .AV {
                        // 在效果区间内的那部分
                        let newClipA = clip.copy() as! MSVMainTrackClip
                        newClipA.timeRange = .init(startTime: clip.timeRange.startTime, duration: (effectEndTime - mainTrackTimePointer) * Double(clip.speed))
                        repeatMainTrackClips.append(newClipA)
                        for _ in 0 ..< self.repeateCount {
                            resultMainTrackClips.append(contentsOf: repeatMainTrackClips)
                        }
                        repeatMainTrackClips.removeAll()
                        // 不在效果区间内的那部分
                        let newClipB = clip.copy() as! MSVMainTrackClip
                        newClipB.timeRange = .init(startTime: clip.timeRange.startTime + (effectEndTime - mainTrackTimePointer) * Double(clip.speed), duration: (clipEndTime - effectEndTime) * Double(clip.speed))
                        resultMainTrackClips.append(newClipB)
                    } else {
                        // 在效果区间内的那部分
                        let newClipA = clip.copy() as! MSVMainTrackClip
                        newClipA.durationAtMainTrack = clipEndTime - effectEndTime
                        repeatMainTrackClips.append(newClipA)
                        for _ in 0 ..< self.repeateCount {
                            resultMainTrackClips.append(contentsOf: repeatMainTrackClips)
                        }
                        repeatMainTrackClips.removeAll()
                        // 不在效果区间内的那部分
                        let newClipB = clip.copy() as! MSVMainTrackClip
                        newClipB.durationAtMainTrack = effectEndTime - mainTrackTimePointer
                        resultMainTrackClips.append(newClipB)
                    }
                    // 同时被开始和结束切割
                } else {
                    if clip.type == .AV {
                        // 不在效果区间内的前部分
                        let newClipA = clip.copy() as! MSVMainTrackClip
                        newClipA.timeRange = .init(startTime: clip.timeRange.startTime, duration: (effectStartTime - mainTrackTimePointer) * Double(clip.speed))
                        resultMainTrackClips.append(newClipA)
                        // 在效果区间内的那部分
                        let newClipB = clip.copy() as! MSVMainTrackClip
                        newClipB.timeRange = .init(startTime: clip.timeRange.startTime + (effectStartTime - mainTrackTimePointer) * Double(clip.speed), duration: self.timeRangeAtMainTrack.duration * Double(clip.speed))
                        repeatMainTrackClips.append(newClipB)
                        for _ in 0 ..< self.repeateCount {
                            resultMainTrackClips.append(contentsOf: repeatMainTrackClips)
                        }
                        repeatMainTrackClips.removeAll()
                        // 不在效果区间内的后部分
                        let newClipC = clip.copy() as! MSVMainTrackClip
                        newClipC.timeRange = .init(startTime: clip.timeRange.startTime + (effectEndTime - mainTrackTimePointer) * Double(clip.speed), duration: (clipEndTime - effectEndTime) * Double(clip.speed))
                        resultMainTrackClips.append(newClipC)
                    } else {
                        // 不在效果区间内的前部分
                        let newClipA = clip.copy() as! MSVMainTrackClip
                        newClipA.durationAtMainTrack = effectStartTime - mainTrackTimePointer;
                        resultMainTrackClips.append(newClipA)
                        // 在效果区间内的那部分
                        let newClipB = clip.copy() as! MSVMainTrackClip
                        newClipB.durationAtMainTrack = self.timeRangeAtMainTrack.duration
                        repeatMainTrackClips.append(newClipB)
                        for _ in 0 ..< self.repeateCount {
                            resultMainTrackClips.append(contentsOf: repeatMainTrackClips)
                        }
                        repeatMainTrackClips.removeAll()
                        // 不在效果区间内的后部分
                        let newClipC = clip.copy() as! MSVMainTrackClip
                        newClipC.durationAtMainTrack = clipEndTime - effectEndTime;
                        resultMainTrackClips.append(newClipC)
                    }
                }
            }
            mainTrackTimePointer = clipEndTime;
        }
        // 所有片段都结束了，如果还有没有加入的重复片段，添加进去
        if (repeatMainTrackClips.count > 0) {
            for _ in 0 ..< self.repeateCount {
                resultMainTrackClips.append(contentsOf: repeatMainTrackClips)
            }
            repeatMainTrackClips.removeAll()
        }
        return resultMainTrackClips
    }
}
