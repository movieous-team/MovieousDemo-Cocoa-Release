//
//  MDSpeedEffect.swift
//  MovieousDemo
//
//  Created by Chris Wang on 2019/8/6.
//  Copyright © 2019 Movieous Team. All rights reserved.
//

import UIKit
import MovieousShortVideo

class MDSpeedEffect {
    var timeRangeAtMainTrack: MovieousTimeRange!
    var speed: Float!
    
    func applyOnTime(time: TimeInterval) -> TimeInterval {
        var startTime = self.timeRangeAtMainTrack.startTime
        if startTime < 0 {
            startTime = 0
        }
        var endTime = self.timeRangeAtMainTrack.startTime + self.timeRangeAtMainTrack.duration
        if endTime > time {
            endTime = time
        }
        let effectiveDuration = endTime - startTime
        if effectiveDuration <= 0 {
            return time
        }
        if (time > startTime && time < endTime) {
            return startTime + (time - startTime) / Double(self.speed)
        } else if (time >= endTime) {
            return time + effectiveDuration * (1 / Double(self.speed) - 1);
        } else {
            return time
        }
    }
    
    func removeFromTime(time: TimeInterval) -> TimeInterval {
        var startTime = self.timeRangeAtMainTrack.startTime
        if startTime < 0 {
            startTime = 0
        }
        var endTime = self.timeRangeAtMainTrack.startTime + self.timeRangeAtMainTrack.duration / Double(self.speed)
        if endTime > time {
            endTime = time
        }
        let effectiveDuration = endTime - startTime
        if effectiveDuration <= 0 {
            return time
        }
        if time > startTime && time < endTime {
            return startTime + (time - startTime) * Double(self.speed)
        } else if time >= endTime {
            return time + effectiveDuration * (Double(self.speed) - 1);
        } else {
            return time
        }
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
        for clip in mainTrackClips {
            let clipEndTime = mainTrackTimePointer + clip.durationAtMainTrack
            // 处于效果区间外
            if clipEndTime <= effectStartTime || mainTrackTimePointer >= effectEndTime {
                resultMainTrackClips.append(clip.copy() as! MSVMainTrackClip)
                // 完全处于效果区间内的片段不用被切割
            } else if mainTrackTimePointer >= effectStartTime && clipEndTime <= effectEndTime {
                // 同时兼容图片和视频类型
                let newClip = clip.copy() as! MSVMainTrackClip
                newClip.durationAtMainTrack = clip.durationAtMainTrack / Double(self.speed);
                resultMainTrackClips.append(newClip)
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
                        newClipB.speed = clip.speed * self.speed;
                        resultMainTrackClips.append(newClipB)
                    } else {
                        let newClip = clip.copy() as! MSVMainTrackClip
                        newClip.durationAtMainTrack = (effectStartTime - mainTrackTimePointer) + (clipEndTime - effectStartTime) / Double(clip.speed);
                        resultMainTrackClips.append(newClip)
                    }
                    // 仅被效果结束时间点切割的片段
                } else if mainTrackTimePointer >= effectStartTime && clipEndTime > effectEndTime {
                    if clip.type == .AV {
                        // 在效果区间内的那部分
                        let newClipA = clip.copy() as! MSVMainTrackClip
                        newClipA.timeRange = .init(startTime: clip.timeRange.startTime, duration: (effectEndTime - mainTrackTimePointer) * Double(clip.speed))
                        newClipA.speed = clip.speed * self.speed;
                        resultMainTrackClips.append(newClipA)
                        // 不在效果区间内的那部分
                        let newClipB = clip.copy() as! MSVMainTrackClip
                        newClipB.timeRange = .init(startTime: clip.timeRange.startTime + (effectEndTime - mainTrackTimePointer) * Double(clip.speed), duration: (clipEndTime - effectEndTime) * Double(clip.speed))
                        resultMainTrackClips.append(newClipB)
                    } else {
                        let newClip = clip.copy() as! MSVMainTrackClip
                        newClip.durationAtMainTrack = (effectEndTime - mainTrackTimePointer) / Double(clip.speed) + (clipEndTime - effectEndTime);
                        resultMainTrackClips.append(newClip)
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
                        newClipB.speed = clip.speed * self.speed;
                        resultMainTrackClips.append(newClipB)
                        // 不在效果区间内的后部分
                        let newClipC = clip.copy() as! MSVMainTrackClip
                        newClipC.timeRange = .init(startTime: clip.timeRange.startTime + (effectStartTime - mainTrackTimePointer) * Double(clip.speed) + newClipB.timeRange.duration, duration: (clipEndTime - effectEndTime) * Double(clip.speed))
                        resultMainTrackClips.append(newClipC)
                    } else {
                        let newClip = clip.copy() as! MSVMainTrackClip
                        newClip.durationAtMainTrack = (effectStartTime - mainTrackTimePointer) + self.timeRangeAtMainTrack.duration / Double(clip.speed) + (clipEndTime - effectEndTime);
                        resultMainTrackClips.append(newClip)
                    }
                }
            }
            mainTrackTimePointer = clipEndTime;
        }
        return resultMainTrackClips
    }
}
