//
//  MDSpecialEffectViewController.swift
//  MovieousDemo
//
//  Created by Chris Wang on 2019/6/27.
//  Copyright © 2019 Movieous Team. All rights reserved.
//

import UIKit
import SnapKit
import MovieousShortVideo
import SVProgressHUD

let FUSceneEffectCodes = ["douyin_01", "douyin_02", "music_filter_1", "music_filter_2", "music_filter_3", "music_filter_4", "music_filter_5", "music_filter_6", "music_filter_7"]
let FUSceneEffectColors: [UIColor] = [.red, .blue, .cyan, .yellow, .magenta, .orange, .purple, .brown, .lightGray]
let TuSDKSceneEffectCodes = ["LiveShake01", "LiveMegrim01", "EdgeMagic01", "LiveFancy01_1", "LiveSoulOut01", "LiveSignal01", "LiveLightning01", "LiveXRay01", "LiveHeartbeat01", "LiveMirrorImage01", "LiveSlosh01", "LiveOldTV01"]
let TuSDKSceneEffectColors: [UIColor] = [.red, .blue, .cyan, .yellow, .magenta, .orange, .purple, .brown, .lightGray, .magenta, .black, .darkGray]

class MDSpecialEffectViewController: UIViewController {
    var editor: MSVEditor!
    var thumbnailsCache: MDThumbnailsCache!
    var reverseVideoExporter: MSVExporter!
    var thumbnailBar: MDThumbnailBar!
    var originalMainTrackClip: MSVMainTrackClip!
    var reversed = false
    var speedEffect: MDSpeedEffect?
    var repeateEffect: MDRepeateEffect?
    let MDFrameOffset = 10
    lazy var seekerView: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = true
        let seekerPin = UIView()
        seekerPin.layer.cornerRadius = 2.5
        seekerPin.layer.masksToBounds = true
        seekerPin.backgroundColor = .white
        view.addSubview(seekerPin)
        seekerPin.snp.makeConstraints { (make) in
            make.width.equalTo(5)
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.centerX.equalToSuperview()
        }
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(seekerViewPan(sender:)))
        view.addGestureRecognizer(panGestureRecognizer)
        return view
    }()
    var seekerViewPosition: SnapKit.Constraint!
    var seeking = false
    let cover: MDSceneEffectCover = {
        let cover = MDSceneEffectCover(frame: .zero)
        cover.alpha = 0.5
        return cover
    }()
    let segmentControl: UISegmentedControl = {
        let segmentControl = UISegmentedControl(items: [NSLocalizedString("MDSpecialEffectViewController.filter", comment: ""), NSLocalizedString("MDSpecialEffectViewController.time", comment: "")])
        segmentControl.selectedSegmentIndex = 0
        return segmentControl
    }()
    let tipsLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.white.withAlphaComponent(0.59)
        label.font = .systemFont(ofSize: 11)
        return label
    }()
    var effectStartViewPosition: SnapKit.Constraint!
    lazy var effectStartView: UIImageView = {
        let view = UIImageView(image: UIImage(named: "drag_bar"))
        view.contentMode = .scaleAspectFit
        view.isUserInteractionEnabled = true
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(effectStartViewPan(sender:)))
        view.addGestureRecognizer(panGestureRecognizer)
        return view
    }()
    lazy var sceneEffectsCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.scrollDirection = .horizontal
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.register(MDSceneEffectCell.self, forCellWithReuseIdentifier: "cell")
        view.delegate = self
        view.dataSource = self
        return view
    }()
    var sceneEffectAppling = false
    lazy var noEffectButton: UIButton = {
        let button = UIButton(frame: .zero, imageName: "no_effect")!
        button.addTarget(self, action: #selector(noneTimeEffectPressed(sender:)), for: .touchUpInside)
        return button
    }()
    
    lazy var repeateEffectButton: UIButton = {
        let button = UIButton(frame: .zero, imageName: "reppeat")!
        button.addTarget(self, action: #selector(repeateEffectPressed(sender:)), for: .touchUpInside)
        return button
    }()
    
    lazy var slowMotionEffectButton: UIButton = {
        let button = UIButton(frame: .zero, imageName: "slow_motion")!
        button.addTarget(self, action: #selector(slowMotionEffectPressed(sender:)), for: .touchUpInside)
        return button
    }()
    
    lazy var reverseEffectButton: UIButton = {
        let button = UIButton(frame: .zero, imageName: "reverse")!
        button.addTarget(self, action: #selector(reverseEffectPressed(sender:)), for: .touchUpInside)
        return button
    }()
    
    lazy var timeEffectContainerView: UIView = {
        let view = UIView()
        
        view.addSubview(self.noEffectButton)
        let noEffectLabel = UILabel()
        noEffectLabel.textColor = .white
        noEffectLabel.text = NSLocalizedString("MDSpecialEffectViewController.none", comment: "")
        view.addSubview(noEffectLabel)
        
        view.addSubview(self.repeateEffectButton)
        let repeateEffectLabel = UILabel()
        repeateEffectLabel.textColor = .white
        repeateEffectLabel.text = NSLocalizedString("MDSpecialEffectViewController.repeate", comment: "")
        view.addSubview(repeateEffectLabel)
        
        view.addSubview(self.slowMotionEffectButton)
        let slowMotionLabel = UILabel()
        slowMotionLabel.textColor = .white
        slowMotionLabel.text = NSLocalizedString("MDSpecialEffectViewController.slowmotion", comment: "")
        view.addSubview(slowMotionLabel)
        
        view.addSubview(self.reverseEffectButton)
        let reverseEffectLabel = UILabel()
        reverseEffectLabel.textColor = .white
        reverseEffectLabel.text = NSLocalizedString("MDSpecialEffectViewController.reverse", comment: "")
        view.addSubview(reverseEffectLabel)
        
        self.noEffectButton.snp.makeConstraints({ (make) in
            make.top.equalToSuperview()
            make.right.equalTo(self.repeateEffectButton.snp.left).offset(-20)
            make.size.equalTo(48)
        })
        
        self.repeateEffectButton.snp.makeConstraints({ (make) in
            make.top.equalToSuperview()
            make.right.equalTo(view.snp.centerX).offset(-10)
            make.size.equalTo(48)
        })
        
        self.slowMotionEffectButton.snp.makeConstraints({ (make) in
            make.top.equalToSuperview()
            make.left.equalTo(view.snp.centerX).offset(10)
            make.size.equalTo(48)
        })
        
        self.reverseEffectButton.snp.makeConstraints({ (make) in
            make.top.equalToSuperview()
            make.left.equalTo(self.slowMotionEffectButton.snp.right).offset(20)
            make.size.equalTo(48)
        })
        
        noEffectLabel.snp.makeConstraints({ (make) in
            make.centerX.equalTo(self.noEffectButton)
            make.top.equalTo(self.noEffectButton.snp.bottom).offset(8)
        })
        repeateEffectLabel.snp.makeConstraints({ (make) in
            make.centerX.equalTo(self.repeateEffectButton)
            make.top.equalTo(self.repeateEffectButton.snp.bottom).offset(8)
        })
        slowMotionLabel.snp.makeConstraints({ (make) in
            make.centerX.equalTo(self.slowMotionEffectButton)
            make.top.equalTo(self.slowMotionEffectButton.snp.bottom).offset(8)
        })
        reverseEffectLabel.snp.makeConstraints({ (make) in
            make.centerX.equalTo(self.reverseEffectButton)
            make.top.equalTo(self.reverseEffectButton.snp.bottom).offset(8)
        })
        return view
    }()
    
    let frameView: UIImageView = {
        let frameView = UIImageView(image: UIImage(named: "selection")!)
        return frameView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.originalMainTrackClip = (self.editor.draft.getAttachmentForKey(MDOriginalMainTrackClipKey)! as! MSVMainTrackClip)
        self.speedEffect = self.editor.draft.getAttachmentForKey(MDSpeedEffectKey) as! MDSpeedEffect?
        self.repeateEffect = self.editor.draft.getAttachmentForKey(MDRepeateEffectKey) as! MDRepeateEffect?
        self.reversed = self.editor.draft.getAttachmentForKey(MDReverseEffectKey) as! Bool? ?? false
        
        self.view.backgroundColor = .black
        
        NotificationCenter.default.addObserver(self, selector: #selector(currentTimeUpdated(sender:)), name: .msvEditorCurrentTimeUpdated, object: self.editor)
        
        self.thumbnailBar = .init(thumbnailCache: self.thumbnailsCache, timeRange: self.originalMainTrackClip.timeRange)
        self.view.addSubview(self.thumbnailBar)
        
        self.effectStartView.isHidden = true
        self.view.addSubview(self.effectStartView)
        
        self.view.addSubview(self.seekerView)
        
        self.view.addSubview(self.tipsLabel)
        
        self.view.addSubview(self.timeEffectContainerView)
        
        self.view.addSubview(self.frameView)
        
        if vendorType == .faceunity || vendorType == .tusdk {
            self.segmentControl.addTarget(self, action: #selector(segmentControlValueChanged(sender:)), for: .valueChanged)
            self.navigationItem.titleView = self.segmentControl
            self.segmentControlValueChanged(sender: self.segmentControl)
            
            self.view.addSubview(self.sceneEffectsCollectionView)
            
            self.view.insertSubview(self.cover, aboveSubview: self.thumbnailBar)
            
            self.cover.snp.makeConstraints { (make) in
                make.size.equalTo(self.thumbnailBar)
                make.center.equalTo(self.thumbnailBar)
            }
            
            self.sceneEffectsCollectionView.snp.makeConstraints { (make) in
                make.top.equalTo(self.tipsLabel.snp.bottom).offset(10)
                make.bottom.equalTo(bottomLayoutGuide.snp.top)
                make.left.equalToSuperview()
                make.right.equalToSuperview()
            }
        }
        
        self.effectStartView.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.thumbnailBar)
            make.height.equalTo(self.thumbnailBar)
            self.effectStartViewPosition = make.centerX.equalTo(self.thumbnailBar.snp.left).constraint
            make.width.equalTo(MDThumbnailBarHeight)
        }
        
        self.timeEffectContainerView.snp.makeConstraints { (make) in
            make.top.equalTo(self.tipsLabel.snp.bottom).offset(10)
            make.bottom.equalTo(bottomLayoutGuide.snp.top)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }
        
        self.thumbnailBar.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.top.equalTo(topLayoutGuide.snp.bottom).offset(20)
            make.height.equalTo(MDThumbnailBarHeight)
        }
        
        self.seekerView.snp.makeConstraints { (make) in
            self.seekerViewPosition = make.centerX.equalTo(self.thumbnailBar.snp.left).constraint
            make.centerY.equalTo(self.thumbnailBar)
            make.height.equalTo(MDThumbnailBarHeight + 15)
            make.width.equalTo(25)
        }
        
        self.tipsLabel.snp.makeConstraints { (make) in
            make.left.equalTo(self.thumbnailBar)
            make.top.equalTo(self.thumbnailBar.snp.bottom).offset(20)
        }
        
        DispatchQueue.main.async {
            self.seekerViewPosition.update(offset: TimeInterval(self.thumbnailBar.frame.size.width) * self.getCurrentAssetTime() / self.originalMainTrackClip.timeRange.duration)
            for effect in MDFilter.shared.sceneEffects {
                var startTime = effect.timeRange.startTime
                var duration = effect.timeRange.duration
                // 在当前时间范围以外
                if effect.timeRange.startTime + effect.timeRange.duration <= self.originalMainTrackClip.timeRange.startTime || effect.timeRange.startTime > self.originalMainTrackClip.timeRange.startTime + self.originalMainTrackClip.timeRange.duration {
                    continue
                }
                if effect.timeRange.startTime <= self.originalMainTrackClip.timeRange.startTime {
                    startTime = self.originalMainTrackClip.timeRange.startTime
                }
                if effect.timeRange.startTime + effect.timeRange.duration > self.originalMainTrackClip.timeRange.startTime + self.originalMainTrackClip.timeRange.duration {
                    duration = self.originalMainTrackClip.timeRange.startTime + self.originalMainTrackClip.timeRange.duration - effect.timeRange.startTime
                }
                var color: UIColor!
                if let sceneCode = effect.sceneCode {
                    if vendorType == .faceunity {
                        let index = FUSceneEffectCodes.firstIndex(of: sceneCode)!
                        color = FUSceneEffectColors[index]
                    } else if vendorType == .tusdk {
                        let index = TuSDKSceneEffectCodes.firstIndex(of: sceneCode)!
                        color = TuSDKSceneEffectColors[index]
                    }
                } else {
                    color = .clear
                }
                let line = MDSceneEffectLine(start: CGFloat((startTime - self.originalMainTrackClip.timeRange.startTime) / self.originalMainTrackClip.timeRange.duration), length: CGFloat(duration / self.originalMainTrackClip.timeRange.duration), color: color)
                self.cover.lines.append(line)
            }
            if let speedEffect = self.speedEffect {
                self.effectStartViewPosition.update(offset: Double(self.thumbnailBar.frame.size.width) * speedEffect.timeRangeAtMainTrack.startTime / self.originalMainTrackClip.durationAtMainTrack)
                self.frameView.snp.makeConstraints { (make) in
                    make.size.equalTo(self.slowMotionEffectButton).offset(self.MDFrameOffset)
                    make.center.equalTo(self.slowMotionEffectButton)
                }
            } else if let repeateEffect = self.repeateEffect {
                self.effectStartViewPosition.update(offset: Double(self.thumbnailBar.frame.size.width) * repeateEffect.timeRangeAtMainTrack.startTime / self.originalMainTrackClip.durationAtMainTrack)
                self.frameView.snp.makeConstraints { (make) in
                    make.size.equalTo(self.repeateEffectButton).offset(self.MDFrameOffset)
                    make.center.equalTo(self.repeateEffectButton)
                }
            } else if self.reversed {
                self.frameView.snp.makeConstraints { (make) in
                    make.size.equalTo(self.reverseEffectButton).offset(self.MDFrameOffset)
                    make.center.equalTo(self.reverseEffectButton)
                }
            } else {
                self.frameView.snp.makeConstraints { (make) in
                    make.size.equalTo(self.noEffectButton).offset(self.MDFrameOffset)
                    make.center.equalTo(self.noEffectButton)
                }
            }
            self.cover.setNeedsDisplay()
        }
    }
    
    @objc func currentTimeUpdated(sender: Notification) {
        if self.seeking {
            return
        }
        var assetTime = self.getCurrentAssetTime()
        // 倒放时可能出现
        if assetTime < 0 {
            assetTime = 0
        }
        self.seekerViewPosition.update(offset: TimeInterval(self.thumbnailBar.frame.size.width) * assetTime / self.originalMainTrackClip.timeRange.duration)
        if !self.sceneEffectAppling {
            return
        }
        guard let line = self.cover.lines.last else { return }
        var startTime = TimeInterval(line.start) * self.originalMainTrackClip.timeRange.duration
        let endTime = startTime + TimeInterval(line.length) * self.originalMainTrackClip.timeRange.duration
        var effectDuration = assetTime - startTime
        // 倒放时
        if assetTime <= startTime {
            effectDuration = endTime - assetTime
            startTime = assetTime
            line.start = CGFloat(startTime / self.originalMainTrackClip.timeRange.duration)
        }
        line.length = CGFloat(effectDuration / self.originalMainTrackClip.timeRange.duration)
        self.cover.setNeedsDisplay()
    }
    
    @objc func segmentControlValueChanged(sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            self.effectStartView.isHidden = true
            self.timeEffectContainerView.isHidden = true
            self.frameView.isHidden = true
            self.cover.isHidden = false
            self.sceneEffectsCollectionView.isHidden = false
            self.tipsLabel.text = NSLocalizedString("MDSpecialEffectViewController.choose", comment: "")
        } else {
            if self.repeateEffect != nil || self.speedEffect != nil {
                self.effectStartView.isHidden = false
            } else {
                self.effectStartView.isHidden = true
            }
            self.timeEffectContainerView.isHidden = false
            self.frameView.isHidden = false
            self.cover.isHidden = true
            self.sceneEffectsCollectionView.isHidden = true
            self.tipsLabel.text = NSLocalizedString("MDSpecialEffectViewController.move", comment: "")
        }
    }
    
    @objc func seekerViewPan(sender: UIPanGestureRecognizer) {
        if sender.state == .began {
            self.seeking = true
            self.editor.pause()
        } else if sender.state == .changed {
            let destPosition = self.seekerViewPosition.layoutConstraints[0].constant + sender.translation(in: self.view).x
            if destPosition >= self.thumbnailBar.frame.size.width {
                self.seekerViewPosition.update(offset: self.thumbnailBar.frame.size.width)
            } else if destPosition <= 0 {
                self.seekerViewPosition.update(offset: 0)
            } else {
                self.seekerViewPosition.update(offset: destPosition)
            }
            sender.setTranslation(.zero, in: self.view)
            self.editor.seek(toTime: self.applyEffectOnTime(time: self.originalMainTrackClip.durationAtMainTrack * TimeInterval(self.seekerViewPosition.layoutConstraints[0].constant / self.thumbnailBar.frame.size.width)), accurate: true)
        } else {
            self.editor.seek(toTime: self.applyEffectOnTime(time: self.originalMainTrackClip.durationAtMainTrack * TimeInterval(self.seekerViewPosition.layoutConstraints[0].constant / self.thumbnailBar.frame.size.width)), accurate: true)
            self.seeking = false
        }
    }
    
    @objc func effectStartViewPan(sender: UIPanGestureRecognizer) {
        if sender.state == .began {
            self.seeking = true
            self.editor.pause()
        } else if sender.state == .changed {
            let destPosition = self.effectStartViewPosition.layoutConstraints[0].constant + sender.translation(in: self.view).x
            if destPosition >= self.thumbnailBar.frame.size.width {
                self.effectStartViewPosition.update(offset: self.thumbnailBar.frame.size.width)
            } else if destPosition <= 0 {
                self.effectStartViewPosition.update(offset: 0)
            } else {
                self.effectStartViewPosition.update(offset: destPosition)
            }
            sender.setTranslation(.zero, in: self.view)
            self.editor.seek(toTime: self.applyEffectOnTime(time: self.originalMainTrackClip.durationAtMainTrack * TimeInterval(self.effectStartViewPosition.layoutConstraints[0].constant / self.thumbnailBar.frame.size.width)), accurate: true)
        } else {
            do {
                if let repeateEffect = self.repeateEffect {
                    repeateEffect.timeRangeAtMainTrack.startTime = self.originalMainTrackClip.durationAtMainTrack * TimeInterval(self.effectStartViewPosition.layoutConstraints[0].constant / self.thumbnailBar.frame.size.width)
                    try self.editor.draft.update(mainTrackClips: repeateEffect.applyOnMainTrackClips(mainTrackClips: [self.originalMainTrackClip]))
                    self.effectStartViewPosition.update(offset: repeateEffect.timeRangeAtMainTrack.startTime / self.originalMainTrackClip.durationAtMainTrack * TimeInterval(self.thumbnailBar.frame.size.width))
                } else if let speedEffect = self.speedEffect {
                    speedEffect.timeRangeAtMainTrack.startTime = self.originalMainTrackClip.durationAtMainTrack * TimeInterval(self.effectStartViewPosition.layoutConstraints[0].constant / self.thumbnailBar.frame.size.width)
                    try self.editor.draft.update(mainTrackClips: speedEffect.applyOnMainTrackClips(mainTrackClips: [self.originalMainTrackClip]))
                    self.effectStartViewPosition.update(offset: speedEffect.timeRangeAtMainTrack.startTime / self.originalMainTrackClip.durationAtMainTrack * TimeInterval(self.thumbnailBar.frame.size.width))
                }
            } catch {
                ShowErrorAlert(error: error, controller: self)
            }
            self.seeking = false
        }
    }
    
    func removeEffectOnTime(time: TimeInterval) -> TimeInterval {
        if !self.sceneEffectAppling {
            if let speedEffect = self.speedEffect {
                return speedEffect.removeFromTime(time: time)
            } else if let repeateEffect = self.repeateEffect {
                return repeateEffect.removeFromTime(time: time, totalDurationAtMainTrack: self.originalMainTrackClip.durationAtMainTrack)
            }
        }
        if self.reversed {
            return self.editor.draft.duration - time
        }
        return time
    }
    
    func applyEffectOnTime(time: TimeInterval) -> TimeInterval {
        if !self.sceneEffectAppling {
            if let speedEffect = self.speedEffect {
                return speedEffect.applyOnTime(time: time)
            } else if let repeateEffect = self.repeateEffect {
                return repeateEffect.applyOnTime(time: time, numberOfRepeate: 1, totalDurationAtMainTrack: self.originalMainTrackClip.durationAtMainTrack)
            }
        }
        if self.reversed {
            return self.editor.draft.duration - time
        }
        return time
    }
    
    func getCurrentAssetTime() -> TimeInterval {
        return self.removeEffectOnTime(time: self.editor.currentTime) * Double(self.originalMainTrackClip.speed)
    }
    
    @objc func noneTimeEffectPressed(sender: UIButton) {
        self.effectStartView.isHidden = true
        self.frameView.snp.remakeConstraints { (make) in
            make.center.equalTo(self.noEffectButton)
        }
        self.editor.draft.removeAttachment(forKey: MDSpeedEffectKey)
        self.editor.draft.removeAttachment(forKey: MDRepeateEffectKey)
        do {
            self.editor.draft.beginChangeTransaction()
            self.reversed = false;
            try self.editor.draft.update(mainTrackClips: [self.originalMainTrackClip])
            try self.editor.draft.commitChange()
        } catch {
            ShowErrorAlert(error: error, controller: self)
        }
    }
    
    @objc func repeateEffectPressed(sender: UIButton) {
        do {
            self.effectStartView.isHidden = false
            self.frameView.snp.remakeConstraints { (make) in
                make.center.equalTo(self.repeateEffectButton)
            }
            self.editor.draft.removeAttachment(forKey: MDSpeedEffectKey)
            self.editor.draft.removeAttachment(forKey: MDReverseEffectKey)
            self.speedEffect = nil
            let effect = MDRepeateEffect()
            effect.repeateCount = 3
            effect.timeRangeAtMainTrack = .init(startTime: self.originalMainTrackClip.durationAtMainTrack / 2, duration: 1)
            self.editor.draft.setAttachment(effect, forKey: MDRepeateEffectKey)
            self.repeateEffect = effect
            self.effectStartViewPosition.update(offset: self.thumbnailBar.frame.size.width / 2)
            self.editor.draft.beginChangeTransaction()
            self.reversed = false
            try self.editor.draft.update(mainTrackClips: effect.applyOnMainTrackClips(mainTrackClips: [self.originalMainTrackClip]))
            try self.editor.draft.commitChange()
        } catch {
            ShowErrorAlert(error: error, controller: self)
        }
    }
    
    @objc func slowMotionEffectPressed(sender: UIButton) {
        do {
            self.effectStartView.isHidden = false
            self.frameView.snp.remakeConstraints { (make) in
                make.center.equalTo(self.slowMotionEffectButton)
            }
            self.editor.draft.removeAttachment(forKey: MDRepeateEffectKey)
            self.editor.draft.removeAttachment(forKey: MDReverseEffectKey)
            self.repeateEffect = nil
            let effect = MDSpeedEffect()
            effect.speed = 0.5
            effect.timeRangeAtMainTrack = .init(startTime: self.originalMainTrackClip.durationAtMainTrack / 2, duration: 1)
            self.editor.draft.setAttachment(effect, forKey: MDSpeedEffectKey)
            self.speedEffect = effect
            self.effectStartViewPosition.update(offset: self.thumbnailBar.frame.size.width / 2)
            self.editor.draft.beginChangeTransaction()
            self.reversed = false
            try self.editor.draft.update(mainTrackClips: effect.applyOnMainTrackClips(mainTrackClips: [self.originalMainTrackClip]))
            try self.editor.draft.commitChange()
        } catch {
            ShowErrorAlert(error: error, controller: self)
        }
    }
    
    @objc func reverseEffectPressed(sender: UIButton) {
        self.editor.pause()
        self.effectStartView.isHidden = true
        self.frameView.snp.remakeConstraints { (make) in
            make.center.equalTo(self.reverseEffectButton)
        }
        
        if let reversedVideoPath = self.editor.draft.getAttachmentForKey(MDReversedVideoPathKey) {
            self.applyReverseEffect(path: reversedVideoPath as! String)
        } else {
            weak var wSelf = self
            self.reverseVideoExporter.completionHandler = {(path) in
                SVProgressHUD.dismiss()
                wSelf?.editor.draft.setAttachment(path, forKey: MDReversedVideoPathKey)
                wSelf?.applyReverseEffect(path: path)
            }
            self.reverseVideoExporter.progressHandler = {(progress) in
                SVProgressHUD.showProgress(progress, status: "正在处理中")
            }
        }
    }
    
    func applyReverseEffect(path: String) {
        do {
            self.editor.draft.removeAttachment(forKey: MDRepeateEffectKey)
            self.editor.draft.removeAttachment(forKey: MDSpeedEffectKey)
            self.repeateEffect = nil
            self.speedEffect = nil
            self.editor.draft.beginChangeTransaction()
            let reversedClip = try MSVMainTrackClip(type: .AV, path: self.editor.draft.getAttachmentForKey(MDReversedVideoPathKey) as! String)
            try self.editor.draft.update(mainTrackClips: [reversedClip])
            try self.editor.draft.commitChange()
            self.reversed = true
            self.editor.draft.setAttachment(self.reversed, forKey: MDReverseEffectKey)
            self.editor.play()
        } catch {
            ShowErrorAlert(error: error, controller: self)
        }
    }
    
    func startEffect(effectCode: String?, color: UIColor) {
        self.sceneEffectAppling = true
        if let repeateEffect = self.repeateEffect {
            let time = repeateEffect.removeFromTime(time: self.editor.currentTime, totalDurationAtMainTrack: self.originalMainTrackClip.durationAtMainTrack)
            do {
                try self.editor.draft.update(mainTrackClips: [self.originalMainTrackClip])
                self.editor.seek(toTime: time, accurate: true)
            } catch {
                ShowErrorAlert(error: error, controller: self)
            }
        } else if let speedEffect = self.speedEffect {
            let time = speedEffect.removeFromTime(time: self.editor.currentTime)
            do {
                try self.editor.draft.update(mainTrackClips: [self.originalMainTrackClip])
                self.editor.seek(toTime: time, accurate: true)
            } catch {
                ShowErrorAlert(error: error, controller: self)
            }
        }
        
        let effect = MDSceneEffect(sceneCode: effectCode, timeRange: kMovieousTimeRangeDefault)
        MDFilter.shared.sceneEffects.append(effect)
        let line = MDSceneEffectLine(start: CGFloat(self.getCurrentAssetTime() / self.originalMainTrackClip.timeRange.duration), length: 0, color: color)
        self.cover.lines.append(line)
        self.editor.loop = false
        self.editor.play()
    }
    
    func endEffect() {
        if !self.sceneEffectAppling {
            return
        }
        var currentTime = self.editor.currentTime
        // 倒放时可能出现
        if currentTime < 0 {
            currentTime = 0
        }
        if let repeateEffect = self.repeateEffect {
            let time = repeateEffect.applyOnTime(time: currentTime, numberOfRepeate: 1, totalDurationAtMainTrack: self.originalMainTrackClip.durationAtMainTrack)
            do {
                try self.editor.draft.update(mainTrackClips: repeateEffect.applyOnMainTrackClips(mainTrackClips: [self.originalMainTrackClip]))
                self.editor.seek(toTime: time, accurate: true)
            } catch {
                ShowErrorAlert(error: error, controller: self)
            }
        } else if let speedEffect = self.speedEffect {
            let time = speedEffect.applyOnTime(time: currentTime)
            do {
                try self.editor.draft.update(mainTrackClips: speedEffect.applyOnMainTrackClips(mainTrackClips: [self.originalMainTrackClip]))
                self.editor.seek(toTime: time, accurate: true)
            } catch {
                ShowErrorAlert(error: error, controller: self)
            }
        }
        self.sceneEffectAppling = false
        guard let line = self.cover.lines.last else { return }
        guard let effect = MDFilter.shared.sceneEffects.last else { return }
        var assetTime = self.getCurrentAssetTime()
        // 倒放时可能出现
        if assetTime < 0 {
            assetTime = 0
        }
        var startTime = TimeInterval(line.start) * self.originalMainTrackClip.timeRange.duration
        let endTime = startTime + TimeInterval(line.length) * self.originalMainTrackClip.timeRange.duration
        var effectDuration = assetTime - startTime
        // 倒放时
        if assetTime <= startTime {
            effectDuration = endTime - assetTime
            startTime = assetTime
            line.start = CGFloat(startTime / self.originalMainTrackClip.timeRange.duration)
        }
        line.length = CGFloat(effectDuration / self.originalMainTrackClip.timeRange.duration)
        effect.timeRange = .init(startTime: self.originalMainTrackClip.timeRange.startTime + startTime, duration: effectDuration)
        self.editor.loop = true
        self.editor.pause()
        self.cover.setNeedsDisplay()
    }
}

extension MDSpecialEffectViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if vendorType == .faceunity {
            return FUSceneEffectCodes.count + 1
        } else if vendorType == .tusdk {
            return TuSDKSceneEffectCodes.count + 1
        } else {
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! MDSceneEffectCell
        var title: String!
        var image: UIImage!
        if indexPath.item == 0 {
            title = NSLocalizedString("MDSpecialEffectViewController.none", comment: "")
            image =  UIImage(named: "noitem")!
        } else {
            if vendorType == .faceunity {
                title = FUSceneEffectCodes[indexPath.item - 1]
                image = UIImage(named: title)!
            } else if vendorType == .tusdk {
                title = NSLocalizedString("lsq_filter_\(TuSDKSceneEffectCodes[indexPath.item - 1])", comment: "")
                image = UIImage(named: "lsq_filter_thumb_\(TuSDKSceneEffectCodes[indexPath.item - 1]).jpg")!
            }
        }
        cell.setImage(image: image)
        cell.setTitle(title: title)
        cell.delegate = self
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return .init(width: 60, height: collectionView.frame.size.height)
    }
}

extension MDSpecialEffectViewController: MDSceneEffectCellDelegate {
    func cell(buttonTouchDown cell: MDSceneEffectCell) {
        if let indexPath = self.sceneEffectsCollectionView.indexPath(for: cell) {
            if indexPath.item == 0 {
                self.startEffect(effectCode: nil, color: .clear)
            } else {
                if vendorType == .faceunity {
                    self.startEffect(effectCode: FUSceneEffectCodes[indexPath.item - 1], color: FUSceneEffectColors[indexPath.item - 1])
                } else if vendorType == .tusdk {
                    self.startEffect(effectCode: TuSDKSceneEffectCodes[indexPath.item - 1], color: TuSDKSceneEffectColors[indexPath.item - 1])
                }
            }
        }
    }
    
    func cell(buttonTouchUp cell: MDSceneEffectCell) {
        self.endEffect()
    }
}

class MDSceneEffectLine {
    var start: CGFloat!
    var length: CGFloat!
    var color: UIColor!
    
    init(start: CGFloat, length: CGFloat, color: UIColor) {
        self.start = start
        self.length = length
        self.color = color
    }
}

class MDSceneEffectCover: UIView {
    var lines: [MDSceneEffectLine] = []
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
    }
    
    override func draw(_ rect: CGRect) {
        let ctx = UIGraphicsGetCurrentContext()!
        let size = rect.size
        for line in self.lines {
            var lineStart = line.start!
            if lineStart < 0 {
                lineStart = 0
            }
            let lineEnd = line.start! + line.length!
            if lineEnd <= lineStart {
                continue
            }
            line.color.setStroke()
            ctx.setLineWidth(size.height)
            let path = UIBezierPath()
            path.move(to: .init(x: size.width * lineStart, y: size.height / 2))
            path.addLine(to: .init(x: size.width * lineEnd, y: size.height / 2))
            ctx.addPath(path.cgPath)
            ctx.setBlendMode(.copy)
            ctx.strokePath()
        }
    }
}

protocol MDSceneEffectCellDelegate: NSObjectProtocol {
    func cell(buttonTouchDown cell: MDSceneEffectCell)
    func cell(buttonTouchUp cell: MDSceneEffectCell)
}

class MDSceneEffectCell: UICollectionViewCell {
    let button = UIButton()
    let label: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 11)
        label.textAlignment = .center
        return label
    }()
    weak var delegate: MDSceneEffectCellDelegate?
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.button.addTarget(self, action: #selector(buttonTouchDown(sender:)), for: .touchDown)
        self.button.addTarget(self, action: #selector(buttonTouchUp(sender:)), for: .touchUpInside)
        self.button.addTarget(self, action: #selector(buttonTouchUp(sender:)), for: .touchUpOutside)
        self.button.addTarget(self, action: #selector(buttonTouchUp(sender:)), for: .touchCancel)
        
        self.contentView.addSubview(self.button)
        self.contentView.addSubview(self.label)
        
        self.button.snp.makeConstraints { (make) in
            make.size.equalTo(48)
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
        }
        
        self.label.snp.makeConstraints { (make) in
            make.top.equalTo(self.button.snp.bottom)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }
    
    func setImage(image: UIImage) {
        self.button.setImage(image, for: .normal)
    }
    
    func setTitle(title: String) {
        self.label.text = title
    }
    
    @objc func buttonTouchDown(sender: UIButton) {
        if let delegate = self.delegate {
            delegate.cell(buttonTouchDown: self)
        }
    }
    
    @objc func buttonTouchUp(sender: UIButton) {
        if let delegate = self.delegate {
            delegate.cell(buttonTouchUp: self)
        }
    }
}
