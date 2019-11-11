//
//  MDTrimViewController.swift
//  MovieousDemo
//
//  Created by Chris Wang on 2019/6/27.
//  Copyright © 2019 Movieous Team. All rights reserved.
//

import UIKit
import MovieousShortVideo
import SnapKit

let MinDuration: CGFloat = 3

class MDTrimViewController: UIViewController {
    var seeking = false
    var editor: MSVEditor!
    var thumbnailsCache: MDThumbnailsCache!
    let tipsLabel = UILabel()
    var thumbnailBar: MDThumbnailBar!
    let leftShadowView = UIView()
    var leftShadowViewWidthConstraint: SnapKit.Constraint!
    let rightShadowView = UIView()
    var rightShadowViewWidthConstraint: SnapKit.Constraint!
    let leftDragView = UIImageView(image: UIImage(named: "drag_bar"))
    let rightDragView = UIImageView(image: UIImage(named: "drag_bar"))
    let seekerView = UIView()
    var seekerViewPosition: SnapKit.Constraint!
    var originalMainTrackClip: MSVMainTrackClip!
    var speedEffect: MDSpeedEffect?
    var repeateEffect: MDRepeateEffect?
    var timeRangeBeforeStartTrim: MovieousTimeRange!
    let segmentControl: UISegmentedControl = {
        let segmentControl = UISegmentedControl(items: [NSLocalizedString("global.slower", comment: ""), NSLocalizedString("global.slow", comment: ""), NSLocalizedString("global.standard", comment: ""), NSLocalizedString("global.fast", comment: ""), NSLocalizedString("global.faster", comment: "")])
        segmentControl.tintColor = .white
        return segmentControl
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.originalMainTrackClip = (self.editor.draft.getAttachmentForKey(MDOriginalMainTrackClipKey)! as! MSVMainTrackClip)
        self.speedEffect = self.editor.draft.getAttachmentForKey(MDSpeedEffectKey) as! MDSpeedEffect?
        self.repeateEffect = self.editor.draft.getAttachmentForKey(MDRepeateEffectKey) as! MDRepeateEffect?
        
        self.title = NSLocalizedString("MDTrimViewController.title", comment: "")
        self.view.backgroundColor = .black
        
        NotificationCenter.default.addObserver(self, selector: #selector(currentTimeUpdated(sender:)), name: .msvEditorCurrentTimeUpdated, object: self.editor)
        
        let resetButton = MDButton()
        resetButton.titleLabel?.font = .systemFont(ofSize: 12)
        resetButton.addTarget(self, action: #selector(resetButtonPressed(sender:)), for: .touchUpInside)
        resetButton.frame = CGRect(x: 0, y: 0, width: 63, height: 26)
        resetButton.setTitle(NSLocalizedString("MDTrimViewController.reset", comment: ""), for: .normal)
        self.navigationItem.rightBarButtonItem = .init(customView: resetButton)
        
        self.tipsLabel.textColor = UIColor.white.withAlphaComponent(0.59)
        self.tipsLabel.font = .systemFont(ofSize: 11)
        self.view.addSubview(self.tipsLabel)
        
        self.thumbnailBar = .init(thumbnailCache: self.thumbnailsCache)
        self.view.addSubview(self.thumbnailBar)
        
        self.leftShadowView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        self.view.addSubview(self.leftShadowView)
        
        self.leftDragView.contentMode = .scaleAspectFit
        self.leftDragView.isUserInteractionEnabled = true
        self.view.addSubview(self.leftDragView)
        
        let leftPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(leftDragViewPan(sender:)))
        self.leftDragView.addGestureRecognizer(leftPanGestureRecognizer)
        leftPanGestureRecognizer.setTranslation(.zero, in: self.view)
        
        self.rightShadowView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        self.view.addSubview(self.rightShadowView)
        
        self.rightDragView.contentMode = .scaleAspectFit
        self.rightDragView.isUserInteractionEnabled = true
        self.view.addSubview(self.rightDragView)
        
        let rightPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(rightDragViewPan(sender:)))
        self.rightDragView.addGestureRecognizer(rightPanGestureRecognizer)
        rightPanGestureRecognizer.setTranslation(.zero, in: self.view)
        
        // 为了让触摸范围更大
        let thumbnailBarHeight = CGFloat(55)
        let dragViewImageSize = self.leftDragView.image!.size
        let imageWidth = thumbnailBarHeight / dragViewImageSize.height * dragViewImageSize.width
        let inset = (thumbnailBarHeight - imageWidth) / 2
        
        self.seekerView.isUserInteractionEnabled = true
        self.view.addSubview(self.seekerView)
        let seekerPin = UIView()
        seekerPin.layer.cornerRadius = 2.5
        seekerPin.layer.masksToBounds = true
        seekerPin.backgroundColor = .white
        self.seekerView.addSubview(seekerPin)
        
        self.segmentControl.addTarget(self, action: #selector(segmentControlValueChanged(sender:)), for: .valueChanged)
        self.view.addSubview(self.segmentControl)
        
        let seekerPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(seekerViewPan(sender:)))
        self.seekerView.addGestureRecognizer(seekerPanGestureRecognizer)
        
        self.tipsLabel.snp.makeConstraints { (make) in
            make.left.equalTo(self.thumbnailBar).offset(-imageWidth)
            make.top.equalTo(topLayoutGuide.snp.bottom).offset(10)
        }
        
        self.thumbnailBar.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(40)
            make.right.equalToSuperview().offset(-40)
            make.top.equalTo(self.tipsLabel.snp.bottom).offset(15)
            make.height.equalTo(thumbnailBarHeight)
        }
        
        self.leftShadowView.snp.makeConstraints { (make) in
            make.left.equalTo(self.thumbnailBar)
            self.leftShadowViewWidthConstraint = make.width.equalTo(0).constraint
            make.top.equalTo(self.thumbnailBar)
            make.bottom.equalTo(self.thumbnailBar)
        }
        
        self.leftDragView.snp.makeConstraints { (make) in
            make.top.equalTo(self.thumbnailBar)
            make.bottom.equalTo(self.thumbnailBar)
            make.right.equalTo(self.leftShadowView).offset(inset)
            make.width.equalTo(thumbnailBarHeight)
        }
        
        self.rightShadowView.snp.makeConstraints { (make) in
            make.right.equalTo(self.thumbnailBar)
            self.rightShadowViewWidthConstraint = make.width.equalTo(0).constraint
            make.top.equalTo(self.thumbnailBar)
            make.bottom.equalTo(self.thumbnailBar)
        }
        
        self.rightDragView.snp.makeConstraints { (make) in
            make.top.equalTo(self.thumbnailBar)
            make.bottom.equalTo(self.thumbnailBar)
            make.left.equalTo( self.rightShadowView).offset(-inset)
            make.width.equalTo(thumbnailBarHeight)
        }
        
        self.seekerView.snp.makeConstraints { (make) in
            self.seekerViewPosition = make.centerX.equalTo(self.thumbnailBar.snp.left).constraint
            make.centerY.equalTo(self.thumbnailBar)
            make.height.equalTo(thumbnailBarHeight + 20)
            make.width.equalTo(25)
        }
        
        seekerPin.snp.makeConstraints { (make) in
            make.width.equalTo(5)
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.centerX.equalToSuperview()
        }
        
        self.segmentControl.snp.makeConstraints { (make) in
            make.width.equalTo(self.thumbnailBar).offset(20)
            make.centerX.equalToSuperview()
            make.height.equalTo(40)
            make.top.equalTo(self.thumbnailBar.snp.bottom).offset(30)
        }
        
        DispatchQueue.main.async {
            let timeRange = self.originalMainTrackClip.timeRange
            self.leftShadowViewWidthConstraint.update(offset: Double(self.thumbnailBar.frame.size.width) * timeRange.startTime / self.originalMainTrackClip.originalDuration)
            self.rightShadowViewWidthConstraint.update(offset: Double(self.thumbnailBar.frame.size.width) * (self.originalMainTrackClip.originalDuration - timeRange.startTime - timeRange.duration) / self.originalMainTrackClip.originalDuration)
            self.seekerViewPosition.update(offset: TimeInterval(self.thumbnailBar.frame.size.width) * self.getCurrentAssetTime() / self.originalMainTrackClip.originalDuration)
            if fabsf(self.originalMainTrackClip.speed - 0.5) <= .ulpOfOne {
                self.segmentControl.selectedSegmentIndex = 0
            } else if fabsf(self.originalMainTrackClip.speed - 0.75) <= .ulpOfOne {
                self.segmentControl.selectedSegmentIndex = 1
            } else if fabsf(self.originalMainTrackClip.speed - 1) <= .ulpOfOne {
                self.segmentControl.selectedSegmentIndex = 2
            } else if fabsf(self.originalMainTrackClip.speed - 1.5) <= .ulpOfOne {
                self.segmentControl.selectedSegmentIndex = 3
            } else if fabsf(self.originalMainTrackClip.speed - 2) <= .ulpOfOne {
                self.segmentControl.selectedSegmentIndex = 4
            } else {
                ShowAlert(title: NSLocalizedString("global.error", comment: ""), message: NSLocalizedString("MDTrimViewController.invalidspeed", comment: ""), action: NSLocalizedString("global.ok", comment: ""), controller: self)
            }
            self.refreshTipsLabel()
        }
    }
    
    func getCurrentAssetTime() -> TimeInterval {
        if let speedEffect = self.speedEffect {
            return self.originalMainTrackClip.timeRange.startTime + speedEffect.removeFromTime(time: self.editor.currentTime) * Double(self.originalMainTrackClip.speed)
        } else if let repeateEffect = self.repeateEffect {
            return self.originalMainTrackClip.timeRange.startTime + repeateEffect.removeFromTime(time: self.editor.currentTime, totalDurationAtMainTrack: self.originalMainTrackClip.durationAtMainTrack) * Double(self.originalMainTrackClip.speed)
        } else {
            return self.originalMainTrackClip.timeRange.startTime + self.editor.currentTime * Double(self.originalMainTrackClip.speed)
        }
    }
    
    @objc func segmentControlValueChanged(sender: UISegmentedControl) {
        var speed = Float(1)
        switch sender.selectedSegmentIndex {
        case 0:
            speed = 0.5
        case 1:
            speed = 0.75
        case 2:
            speed = 1
        case 3:
            speed = 1.5
        case 4:
            speed = 2
        default:
            break
        }
        self.editor.draft.beginChangeTransaction()
        self.originalMainTrackClip.speed = speed
        for clip in self.editor.draft.mainTrackClips {
            clip.speed = speed
        }
        do {
            try self.editor.draft.commitChange()
        } catch {
            ShowErrorAlert(error: error, controller: self)
        }
        self.refreshTipsLabel()
    }
    
    @objc func resetButtonPressed(sender: UIButton) {
        self.leftShadowViewWidthConstraint.update(offset: 0)
        self.rightShadowViewWidthConstraint.update(offset: 0)
        self.segmentControl.selectedSegmentIndex = 2
        self.editor.draft.beginChangeTransaction()
        self.segmentControlValueChanged(sender: self.segmentControl)
        self.applyTrim()
        do {
            try self.editor.draft.commitChange()
        } catch {
            ShowErrorAlert(error: error, controller: self)
        }
        self.refreshTipsLabel()
    }
    
    @objc func currentTimeUpdated(sender: Notification) {
        if self.seeking {
            return
        }
        let test = self.getCurrentAssetTime()
        self.seekerViewPosition.update(offset: TimeInterval(self.thumbnailBar.frame.size.width) * test / self.originalMainTrackClip.originalDuration)
    }
    
    func refreshTipsLabel() {
        let endTime = (self.originalMainTrackClip.originalDuration * Double(self.thumbnailBar.frame.size.width - self.rightShadowViewWidthConstraint.layoutConstraints[0].constant) / Double(self.thumbnailBar.frame.size.width) - self.originalMainTrackClip.timeRange.startTime) / Double(self.originalMainTrackClip.speed)
        let startTime = (self.originalMainTrackClip.originalDuration * Double(self.leftShadowViewWidthConstraint.layoutConstraints[0].constant) / Double(self.thumbnailBar.frame.size.width) - self.originalMainTrackClip.timeRange.startTime) / Double(self.originalMainTrackClip.speed)
        let selectedDuration = self.applyEffectOnTime(time: endTime, isFirst: false) - self.applyEffectOnTime(time: startTime, isFirst: true)
        self.tipsLabel.text = String(format: NSLocalizedString("MDTrimViewController.selected", comment: ""), selectedDuration)
    }
    
    @objc func seekerViewPan(sender: UIPanGestureRecognizer) {
        if sender.state == .began {
            self.seeking = true
            self.editor.pause()
        } else if sender.state == .changed {
            let destPosition = self.seekerViewPosition.layoutConstraints[0].constant + sender.translation(in: self.view).x
            let minPosition = self.leftShadowViewWidthConstraint.layoutConstraints[0].constant
            let maxPosition = self.thumbnailBar.frame.size.width - self.rightShadowViewWidthConstraint.layoutConstraints[0].constant
            if destPosition >= maxPosition {
                self.seekerViewPosition.update(offset: maxPosition)
            } else if destPosition <= minPosition {
                self.seekerViewPosition.update(offset: minPosition)
            } else {
                self.seekerViewPosition.update(offset: destPosition)
            }
            sender.setTranslation(.zero, in: self.view)
            self.editor.seek(toTime: self.applyEffectOnTime(time: (self.originalMainTrackClip.originalDuration * TimeInterval(self.seekerViewPosition.layoutConstraints[0].constant / self.thumbnailBar.frame.size.width) - self.originalMainTrackClip.timeRange.startTime) / TimeInterval(self.originalMainTrackClip.speed), isFirst: true), accurate: true)
        } else {
            self.editor.seek(toTime: self.applyEffectOnTime(time: (self.originalMainTrackClip.originalDuration * TimeInterval(self.seekerViewPosition.layoutConstraints[0].constant / self.thumbnailBar.frame.size.width) - self.originalMainTrackClip.timeRange.startTime) / TimeInterval(self.originalMainTrackClip.speed), isFirst: true), accurate: true)
            self.seeking = false
        }
    }
    
    @objc func leftDragViewPan(sender: UIPanGestureRecognizer) {
        if sender.state == .began {
            self.seekerView.isHidden = true
            self.editor.pause()
            // 暂时取消 timeRange 和 time effect，以便预览 seek
            self.timeRangeBeforeStartTrim = self.originalMainTrackClip.timeRange
            let tmpMainTrackClip = self.originalMainTrackClip.copy() as! MSVMainTrackClip
            tmpMainTrackClip.timeRange = kMovieousTimeRangeDefault
            do {
                try self.editor.draft.update(mainTrackClips: [tmpMainTrackClip])
            } catch {
                ShowErrorAlert(error: error, controller: self)
            }
            self.editor.draft.beginChangeTransaction()
        } else if sender.state == .changed {
            let destPosition = self.leftShadowViewWidthConstraint.layoutConstraints[0].constant + sender.translation(in: self.view).x
            var maxPosition = self.thumbnailBar.frame.size.width - self.rightShadowViewWidthConstraint.layoutConstraints[0].constant - self.thumbnailBar.frame.size.width * (MinDuration * CGFloat(self.originalMainTrackClip.speed)) / CGFloat(self.originalMainTrackClip.originalDuration)
            if maxPosition < 0 {
                maxPosition = 0
            }
            if destPosition >= maxPosition {
                self.leftShadowViewWidthConstraint.update(offset: maxPosition)
            } else if destPosition <= 0 {
                self.leftShadowViewWidthConstraint.update(offset: 0)
            } else {
                self.leftShadowViewWidthConstraint.update(offset: destPosition)
            }
            sender.setTranslation(.zero, in: self.view)
            self.applyTrim()
            self.refreshTipsLabel()
            self.editor.seek(toTime: (self.originalMainTrackClip.originalDuration * TimeInterval(self.leftShadowViewWidthConstraint.layoutConstraints[0].constant / self.thumbnailBar.frame.size.width) - self.timeRangeBeforeStartTrim.startTime) / TimeInterval(self.originalMainTrackClip.speed), accurate: true)
        } else {
            self.seekerView.isHidden = false
            self.applyTrim()
            do {
                try self.editor.draft.commitChange()
            } catch {
                ShowErrorAlert(error: error, controller: self)
            }
        }
    }
    
    @objc func rightDragViewPan(sender: UIPanGestureRecognizer) {
        if sender.state == .began {
            self.seekerView.isHidden = true
            self.editor.pause()
            // 暂时取消 timeRange 和 time effect，以便预览 seek
            self.timeRangeBeforeStartTrim = self.originalMainTrackClip.timeRange
            let tmpMainTrackClip = self.originalMainTrackClip.copy() as! MSVMainTrackClip
            tmpMainTrackClip.timeRange = kMovieousTimeRangeDefault
            do {
                try self.editor.draft.update(mainTrackClips: [tmpMainTrackClip])
            } catch {
                ShowErrorAlert(error: error, controller: self)
            }
            self.editor.draft.beginChangeTransaction()
        } else if sender.state == .changed {
            let destPosition = self.rightShadowViewWidthConstraint.layoutConstraints[0].constant - sender.translation(in: self.view).x
            var maxPosition = self.thumbnailBar.frame.size.width - self.leftShadowViewWidthConstraint.layoutConstraints[0].constant - self.thumbnailBar.frame.size.width * (MinDuration * CGFloat(self.originalMainTrackClip.speed)) / CGFloat(self.originalMainTrackClip.originalDuration)
            if maxPosition < 0 {
                maxPosition = 0
            }
            if destPosition >= maxPosition {
                self.rightShadowViewWidthConstraint.update(offset: maxPosition)
            } else if destPosition <= 0 {
                self.rightShadowViewWidthConstraint.update(offset: 0)
            } else {
                self.rightShadowViewWidthConstraint.update(offset: destPosition)
            }
            sender.setTranslation(.zero, in: self.view)
            self.applyTrim()
            self.refreshTipsLabel()
            self.editor.seek(toTime: (self.originalMainTrackClip.originalDuration * TimeInterval((self.thumbnailBar.frame.size.width - self.rightShadowViewWidthConstraint.layoutConstraints[0].constant) / self.thumbnailBar.frame.size.width) - self.timeRangeBeforeStartTrim.startTime) / TimeInterval(self.originalMainTrackClip.speed), accurate: true)
        } else {
            self.seekerView.isHidden = false
            self.applyTrim()
            do {
                try self.editor.draft.commitChange()
            } catch {
                ShowErrorAlert(error: error, controller: self)
            }
        }
    }
    
    func applyEffectOnTime(time: TimeInterval, isFirst: Bool) -> TimeInterval {
        if let speedEffect = self.speedEffect {
            return speedEffect.applyOnTime(time: time)
        } else if let repeateEffect = self.repeateEffect {
            return repeateEffect.applyOnTime(time: time, numberOfRepeate: isFirst ? 1 : repeateEffect.repeateCount, totalDurationAtMainTrack: self.originalMainTrackClip.durationAtMainTrack)
        } else {
            return time
        }
    }
    
    func applyTrim() {
        let startTime = self.originalMainTrackClip.originalDuration * TimeInterval(self.leftShadowViewWidthConstraint.layoutConstraints[0].constant / self.thumbnailBar.frame.size.width)
        let endTime = self.originalMainTrackClip.originalDuration - self.originalMainTrackClip.originalDuration * TimeInterval(self.rightShadowViewWidthConstraint.layoutConstraints[0].constant / self.thumbnailBar.frame.size.width)
        self.applyTimeRange(timeRange: .init(startTime: startTime, duration: endTime - startTime))
    }
    
    func applyTimeRange(timeRange: MovieousTimeRange) {
        do {
            if let speedEffect = self.speedEffect {
                speedEffect.timeRangeAtMainTrack.startTime = (self.originalMainTrackClip.timeRange.startTime + speedEffect.timeRangeAtMainTrack.startTime * Double(self.originalMainTrackClip.speed) - timeRange.startTime) / Double(self.originalMainTrackClip.speed)
                self.originalMainTrackClip.timeRange = timeRange
                try self.editor.draft.update(mainTrackClips: speedEffect.applyOnMainTrackClips(mainTrackClips: [self.originalMainTrackClip]))
            } else if let repeateEffect = self.repeateEffect {
                repeateEffect.timeRangeAtMainTrack.startTime = (self.originalMainTrackClip.timeRange.startTime + repeateEffect.timeRangeAtMainTrack.startTime * Double(self.originalMainTrackClip.speed) - timeRange.startTime) / Double(self.originalMainTrackClip.speed)
                self.originalMainTrackClip.timeRange = timeRange
                try self.editor.draft.update(mainTrackClips: repeateEffect.applyOnMainTrackClips(mainTrackClips: [self.originalMainTrackClip]))
            } else {
                self.originalMainTrackClip.timeRange = timeRange
                try self.editor.draft.update(mainTrackClips: [self.originalMainTrackClip])
            }
        } catch {
            ShowErrorAlert(error: error, controller: self)
        }
    }
}
