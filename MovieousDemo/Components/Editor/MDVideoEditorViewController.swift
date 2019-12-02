//
//  MDVideoEditorViewController.swift
//  MovieousDemo
//
//  Created by Chris Wang on 2019/6/21.
//  Copyright © 2019 Movieous Team. All rights reserved.
//

import UIKit
import MovieousShortVideo
import SnapKit

let MDStickerEffectID = "MDStickerEffectID"
let MDGraffitiEffectID = "MDGraffitiEffectID"
// 边框和框内的图片之间的距离
let MDFrameViewMargin = CGFloat(10)
let MDDeleteButtonWidth = CGFloat(20)

class MDVideoEditorViewController: UIViewController {
    var draft: MSVDraft!
    var reverseVideoExporter: MSVExporter!
    var recorderMusic: MDMusic?
    var editor: MSVEditor!
    var toolboxNavigationController: UINavigationController!
    let playButton = MDButton()
    let frameView = MDFrameView()
    let deleteStickerButton = UIButton(type: .custom)
    lazy var tapGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped(sender:)))
    lazy var panGestureRecognizer: UIPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panned(sender:)))
    lazy var pinchGestureRecognizer: UIPinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinched(sender:)))
    lazy var rotationGestureRecognizer: UIRotationGestureRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(rotated(sender:)))
    var lastTranslation: CGPoint?
    var lastScale: CGFloat?
    var lastRotation: CGFloat?
    var selectedStickerEffect: MSVEditorEffect?
    weak var currentWordViewController: MDWordViewController?
    lazy var thumbnailsCache: MDThumbnailsCache = {
        let thumbnailsCache = MDThumbnailsCache(draft: self.editor.draft)
        let ratio = TimeInterval(self.draft.videoSize.width / self.draft.videoSize.height)
        if ratio >= 1 {
            thumbnailsCache.maximumSize = .init(width: MDThumbnailBarHeight * TimeInterval(UIScreen.main.scale) * ratio, height: MDThumbnailBarHeight * TimeInterval(UIScreen.main.scale))
        } else {
            thumbnailsCache.maximumSize = .init(width: MDThumbnailBarHeight * TimeInterval(UIScreen.main.scale), height: MDThumbnailBarHeight * TimeInterval(UIScreen.main.scale) / ratio)
        }
        return thumbnailsCache
    }()
    lazy var faceBeautyCaptureEffect = MSVFaceBeautyEditorEffect()
    lazy var filterCaptureEffect = MSVLUTFilterEditorEffect()
    var previeousGraffitiIndex = -1
    var previeousWordIndex = -1
    let tools = [
        ["MDVideoEditorViewController.volume", "sound_set"],
        ["MDVideoEditorViewController.music", "music_editor"],
        ["MDVideoEditorViewController.sticker", "sticker"],
        ["MDVideoEditorViewController.beauty", "face_beauty_set"],
        ["MDVideoEditorViewController.trim", "cut"],
        ["MDVideoEditorViewController.effect", "effect_set"],
        ["MDVideoEditorViewController.word", "font"],
        ["MDVideoEditorViewController.scrawl", "pencil"],
        //        ["MDVideoEditorViewController.cover", "Cover"],
        //        ["MDVideoEditorViewController.composition", "video_merge_set"],
        //        ["MDVideoEditorViewController.mv", "mv_effect_set"],
        //        ["MDVideoEditorViewController.split", "split_set"],
        //        ["MDVideoEditorViewController.concat", "pinjie_set"],
        //        ["MDVideoEditorViewController.particle", "piantoupianwei_set"],
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.view.backgroundColor = .black
        // 保存原始的主轨片段，后续应用的时间特效会改变主轨片段集合。
        self.draft.setAttachment(self.draft.mainTrackClips[0], forKey: MDOriginalMainTrackClipKey)
        self.reverseVideoExporter = MSVExporter(draft: self.draft)
        self.reverseVideoExporter.reverseVideo = true
        self.reverseVideoExporter.completionHandler = {(path) in
            self.draft.setAttachment(path, forKey: MDReversedVideoPathKey)
        }
        self.reverseVideoExporter.startExport()
        do {
            try self.draft.update(basicEffects: [self.faceBeautyCaptureEffect, self.filterCaptureEffect])
            try self.editor = MSVEditor(draft: self.draft)
        } catch {
            ShowErrorAlert(error: error, controller: self)
            return
        }
        NotificationCenter.default.addObserver(self, selector: #selector(currentTimeUpdated(sender:)), name: .msvEditorCurrentTimeUpdated, object: self.editor)
        self.editor.loop = true
        self.editor.delegate = self
        self.editor.play()
        self.editor.preview.clipsToBounds = true
        self.buildUI()
        self.thumbnailsCache.refreshThumbnails()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = false
        self.navigationController?.setTransparent(transparent: true)
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.editor.pause()
        self.syncWordEffect(videoSize: self.editor.draft.videoSize, contentFrame: self.editor.contentFrame)
    }
    
    func buildUI() {
        self.view.backgroundColor = .black
        self.navigationController?.navigationBar.tintColor = .white
        
        self.playButton.titleLabel?.font = .systemFont(ofSize: 12)
        self.playButton.addTarget(self, action: #selector(playButtonPressed(sender:)), for: .touchUpInside)
        self.playButton.frame = CGRect(x: 0, y: 0, width: 63, height: 26)
        self.playButton.setTitle(NSLocalizedString("MDVideoEditorViewController.pause", comment: ""), for: .normal)
        self.playButton.setTitle(NSLocalizedString("MDVideoEditorViewController.play", comment: ""), for: .selected)
        self.navigationItem.titleView = self.playButton
        
        let nextButton = MDButton()
        nextButton.titleLabel?.font = .systemFont(ofSize: 12)
        nextButton.addTarget(self, action: #selector(nextButtonPressed(sender:)), for: .touchUpInside)
        nextButton.frame = CGRect(x: 0, y: 0, width: 63, height: 26)
        nextButton.setTitle(NSLocalizedString("MDVideoEditorViewController.next", comment: ""), for: .normal)
        
        self.navigationItem.rightBarButtonItem = .init(customView: nextButton)
        
        let toolboxViewController = MDEditorToolboxViewController()
        toolboxViewController.delegate = self
        toolboxViewController.tools = self.tools
        self.toolboxNavigationController = UINavigationController(rootViewController: toolboxViewController)
        self.toolboxNavigationController?.interactivePopGestureRecognizer?.isEnabled = false
        self.toolboxNavigationController.navigationBar.tintColor = .white
        self.toolboxNavigationController.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        self.toolboxNavigationController.setTransparent(transparent: true)
        self.toolboxNavigationController.delegate = self
        self.view.addSubview(self.toolboxNavigationController.view)
        
        self.view.addSubview(self.editor.preview)
        
        self.editor.graffitiManager.brush = .init(lineWidth: 10, lineColor: .white)
        self.editor.graffitiManager.hideGraffitiView = true
        
        self.frameView.isHidden = true
        self.frameView.frameWidth = 2
        self.frameView.margin = MDDeleteButtonWidth / 2
        self.editor.preview.addSubview(self.frameView)
        
        self.deleteStickerButton.bounds = .init(x: 0, y: 0, width: MDDeleteButtonWidth, height: MDDeleteButtonWidth)
        self.deleteStickerButton.setImage(UIImage(named: "delete"), for: .normal)
        self.deleteStickerButton.addTarget(self, action: #selector(deleteStickerButtonPressed(sender:)), for: .touchUpInside)
        self.frameView.addSubview(self.deleteStickerButton)
        
        self.tapGestureRecognizer.delegate = self
        self.tapGestureRecognizer.cancelsTouchesInView = false
        self.editor.preview.addGestureRecognizer(self.tapGestureRecognizer)
        
        self.panGestureRecognizer.delegate = self
        self.panGestureRecognizer.cancelsTouchesInView = false
        self.editor.preview.addGestureRecognizer(self.panGestureRecognizer)
        
        self.pinchGestureRecognizer.delegate = self
        self.pinchGestureRecognizer.cancelsTouchesInView = false
        self.editor.preview.addGestureRecognizer(self.pinchGestureRecognizer)
        
        self.rotationGestureRecognizer.delegate = self
        self.rotationGestureRecognizer.cancelsTouchesInView = false
        self.editor.preview.addGestureRecognizer(self.rotationGestureRecognizer)
        
        self.toolboxNavigationController.view.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(240)
        }
        
        self.editor.preview.snp.makeConstraints { (make) in
            make.top.equalTo(topLayoutGuide.snp.bottom)
            make.bottom.equalTo(self.toolboxNavigationController.view.snp_top)
            make.right.equalToSuperview()
            make.left.equalToSuperview()
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    @objc func deleteStickerButtonPressed(sender: UIButton) {
        if let selectedStickerEffect = self.selectedStickerEffect {
            var basicEffects = self.editor.draft.basicEffects
            let index = basicEffects.firstIndex { (effect) -> Bool in
                return selectedStickerEffect.isEqual(effect)
                }!
            basicEffects.remove(at: index)
            do {
                try self.editor.draft.update(basicEffects: basicEffects)
            } catch {
                ShowErrorAlert(error: error, controller: self)
            }
        } else if let currentWordViewController = self.currentWordViewController {
            currentWordViewController.deleteButtonPressed()
        }
        self.frameView.isHidden = true
    }
    
    @objc func playButtonPressed(sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            self.editor.pause()
        } else {
            self.editor.play()
        }
    }
    
    @objc func nextButtonPressed(sender: UIButton) {
        let vc = MDExporterViewController()
        vc.draft = self.draft
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func syncWordEffect(videoSize: CGSize, contentFrame: CGRect) {
        if let currentWordViewController = self.currentWordViewController {
            if let selectedWordLabel = currentWordViewController.selectedWordLabel {
                selectedWordLabel.font = .systemFont(ofSize: selectedWordLabel.font.pointSize * videoSize.width / contentFrame.size.width)
                let size = CGSize(width: selectedWordLabel.bounds.size.width * videoSize.width / contentFrame.size.width, height: selectedWordLabel.bounds.size.height * videoSize.height / contentFrame.size.height)
                let center = CGPoint(x: selectedWordLabel.center.x * videoSize.width / contentFrame.size.width, y: selectedWordLabel.center.y * videoSize.height / contentFrame.size.height)
                selectedWordLabel.bounds = .init(origin: .zero, size: size)
                selectedWordLabel.center = center
                currentWordViewController.selectedWordContainerView?.frame = .init(origin: .zero, size: videoSize)
                let image = currentWordViewController.selectedWordContainerView!.snapshot()
                currentWordViewController.selectedWordEffect?.image = image
                currentWordViewController.selectedWordEffect?.destRect = .init(origin: .zero, size: videoSize)
                var basicEffects = self.editor.draft.basicEffects
                basicEffects.insert(currentWordViewController.selectedWordEffect!, at: self.previeousWordIndex)
                do {
                    try self.editor.draft.update(basicEffects: basicEffects)
                } catch {
                    ShowErrorAlert(error: error, controller: self)
                }
            }
        }
        self.currentWordViewController?.selectedWordContainerView?.removeFromSuperview()
        self.currentWordViewController?.selectedWordLabel = nil
        self.currentWordViewController?.selectedWordEffect = nil
        self.frameView.isHidden = true
    }
    
    @objc func tapped(sender: UITapGestureRecognizer) {
        let location = sender.location(in: self.editor.preview)
        if self.frameView.convert(self.deleteStickerButton.frame, to: self.editor.preview).contains(location) {
            return
        }
        let contentFrame = self.editor.contentFrame
        let videoSize = self.editor.draft.videoSize
        // 进入相应的工具箱才能调整相关的
        if self.toolboxNavigationController.topViewController!.isKind(of: MDStickerViewController.self) {
            self.selectedStickerEffect = nil
            self.frameView.isHidden = true
            if self.editor.draft.basicEffects.count > 0 {
                for i in (0...self.editor.draft.basicEffects.count - 1).reversed() {
                    var destRect: CGRect!
                    var rotation: CGFloat!
                    if let effect = self.editor.draft.basicEffects[i] as? MSVImageStickerEditorEffect {
                        if effect.getAttachmentForKey("type") as! String? != MDStickerEffectID {
                            continue
                        }
                        destRect = effect.destRect
                        rotation = effect.rotation
                    } else if let effect = self.editor.draft.basicEffects[i] as? MSVAnimatedStickerEditorEffect {
                        if effect.getAttachmentForKey("type") as! String? != MDStickerEffectID {
                            continue
                        }
                        destRect = effect.destRect
                        rotation = effect.rotation
                    } else {
                        continue
                    }
                    
                    let imageStickerFrame = CGRect(x: contentFrame.origin.x + destRect.origin.x / videoSize.width * contentFrame.size.width, y: contentFrame.origin.y + destRect.origin.y / videoSize.width * contentFrame.size.width, width: destRect.size.width / videoSize.width * contentFrame.size.width, height: destRect.size.height / videoSize.height * contentFrame.size.height)
                    if imageStickerFrame.contains(location) {
                        self.selectedStickerEffect = self.editor.draft.basicEffects[i]
                        self.frameView.bounds = .init(x: 0, y: 0, width: imageStickerFrame.size.width + 2 * MDFrameViewMargin + self.frameView.margin, height: imageStickerFrame.size.height + 2 * MDFrameViewMargin + self.frameView.margin)
                        self.frameView.center = .init(x: imageStickerFrame.midX, y: imageStickerFrame.midY)
                        self.frameView.transform = CGAffineTransform(rotationAngle: rotation)
                        self.frameView.isHidden = false
                        self.deleteStickerButton.center = .init(x: self.frameView.bounds.size.width - self.frameView.margin - self.frameView.frameWidth / 2, y: self.frameView.margin + self.frameView.frameWidth / 2)
                        break
                    }
                }
            }
        } else if let currentWordViewController = self.currentWordViewController {
            let location = sender.location(in: self.frameView)
            if !self.frameView.isHidden && self.frameView.bounds.contains(location) {
                return
            }
            if self.editor.draft.basicEffects.count > 0 {
                for i in (0...self.editor.draft.basicEffects.count - 1).reversed() {
                    if let effect = self.editor.draft.basicEffects[i] as? MSVImageStickerEditorEffect {
                        if effect.getAttachmentForKey("type") as! String? != MDWordEffectID {
                            continue
                        }
                        if self.editor.currentTime < effect.timeRangeAtMainTrack.startTime || self.editor.currentTime > effect.timeRangeAtMainTrack.startTime + effect.timeRangeAtMainTrack.duration {
                            continue
                        }
                        let containerView = (effect.getAttachmentForKey("containerView")! as! UIView)
                        let wordLabel = (containerView.subviews[0] as! UILabel)
                        let center = CGPoint(x: wordLabel.center.x / videoSize.width * contentFrame.size.width, y: wordLabel.center.y / videoSize.height * contentFrame.size.height)
                        let size = CGSize(width: wordLabel.bounds.size.width / videoSize.width * contentFrame.size.width, height: wordLabel.bounds.size.height / videoSize.height * contentFrame.size.height)
                        self.frameView.bounds = .init(x: 0, y: 0, width: size.width + 2 * MDFrameViewMargin + self.frameView.margin, height: size.height + 2 * MDFrameViewMargin + self.frameView.margin)
                        self.frameView.center = .init(x: center.x + contentFrame.origin.x, y: center.y + contentFrame.origin.y)
                        self.frameView.transform = wordLabel.transform
                        let location = sender.location(in: self.frameView)
                        if self.frameView.bounds.contains(location) {
                            var basicEffects = self.editor.draft.basicEffects
                            basicEffects.remove(at: i)
                            do {
                                try self.editor.draft.update(basicEffects: basicEffects)
                            } catch {
                                ShowErrorAlert(error: error, controller: self)
                            }
                            if i < self.previeousWordIndex {
                                self.previeousWordIndex -= 1
                            }
                            self.syncWordEffect(videoSize: videoSize, contentFrame: contentFrame)
                            currentWordViewController.selectedWordEffect = effect
                            currentWordViewController.selectedWordContainerView = containerView
                            currentWordViewController.selectedWordLabel = wordLabel
                            currentWordViewController.selectedWordContainerView?.frame = contentFrame
                            currentWordViewController.selectedWordLabel?.font = .systemFont(ofSize: currentWordViewController.selectedWordLabel!.font.pointSize * contentFrame.size.width / videoSize.width)
                            currentWordViewController.selectedWordLabel?.center = center
                            currentWordViewController.selectedWordLabel?.bounds = .init(origin: .zero, size: size)
                            self.editor.preview.addSubview(currentWordViewController.selectedWordContainerView!)
                            currentWordViewController.selectedWordLabel?.isHidden = false
                            
                            self.frameView.isHidden = false
                            self.deleteStickerButton.center = .init(x: self.frameView.bounds.size.width - self.frameView.margin - self.frameView.frameWidth / 2, y: self.frameView.margin + self.frameView.frameWidth / 2)
                            self.previeousWordIndex = i
                            return
                        }
                    } else {
                        continue
                    }
                }
            }
            self.syncWordEffect(videoSize: videoSize, contentFrame: contentFrame)
        }
    }
    
    @objc func panned(sender: UIPanGestureRecognizer) {
        if let selectedStickerEffect = self.selectedStickerEffect {
            let location = sender.location(in: self.editor.preview)
            if sender.state == .began {
                if self.frameView.frame.contains(location) {
                    self.lastTranslation = sender.translation(in: self.editor.preview)
                } else {
                    self.lastTranslation = nil
                }
            } else {
                guard let lastTranslation = self.lastTranslation else {
                    return
                }
                let contentFrame = self.editor.contentFrame
                let videoSize = self.editor.draft.videoSize
                let translation = sender.translation(in: self.editor.preview)
                let translationDelta = CGPoint(x: translation.x - lastTranslation.x, y: translation.y - lastTranslation.y)
                self.lastTranslation = translation
                if let imageStickerEffect = selectedStickerEffect as? MSVImageStickerEditorEffect {
                    imageStickerEffect.destRect = .init(x: imageStickerEffect.destRect.origin.x + translationDelta.x / contentFrame.size.width * videoSize.width, y: imageStickerEffect.destRect.origin.y + translationDelta.y / contentFrame.size.height * videoSize.height, width: imageStickerEffect.destRect.size.width, height: imageStickerEffect.destRect.size.height)
                } else if let gifStickerEffect = selectedStickerEffect as? MSVAnimatedStickerEditorEffect {
                    gifStickerEffect.destRect = .init(x: gifStickerEffect.destRect.origin.x + translationDelta.x / contentFrame.size.width * videoSize.width, y: gifStickerEffect.destRect.origin.y + translationDelta.y / contentFrame.size.height * videoSize.height, width: gifStickerEffect.destRect.size.width, height: gifStickerEffect.destRect.size.height)
                }
                self.frameView.center = .init(x: self.frameView.center.x + translationDelta.x, y: self.frameView.center.y + translationDelta.y)
                self.deleteStickerButton.center = .init(x: self.frameView.bounds.size.width - self.frameView.margin - self.frameView.frameWidth / 2, y: self.frameView.margin + self.frameView.frameWidth / 2)
            }
        } else if let currentWordViewController = self.currentWordViewController {
            if let selectedWordLabel = currentWordViewController.selectedWordLabel {
                let location = sender.location(in: self.editor.preview)
                if sender.state == .began {
                    if self.frameView.frame.contains(location) {
                        self.lastTranslation = sender.translation(in: self.editor.preview)
                    } else {
                        self.lastTranslation = nil
                    }
                } else {
                    guard let lastTranslation = self.lastTranslation else {
                        return
                    }
                    let translation = sender.translation(in: self.editor.preview)
                    let translationDelta = CGPoint(x: translation.x - lastTranslation.x, y: translation.y - lastTranslation.y)
                    self.lastTranslation = translation
                    selectedWordLabel.center = .init(x: selectedWordLabel.center.x + translationDelta.x, y: selectedWordLabel.center.y + translationDelta.y)
                    self.frameView.center = .init(x: self.frameView.center.x + translationDelta.x, y: self.frameView.center.y + translationDelta.y)
                    self.deleteStickerButton.center = .init(x: self.frameView.bounds.size.width - self.frameView.margin - self.frameView.frameWidth / 2, y: self.frameView.margin + self.frameView.frameWidth / 2)
                }
            }
        }
    }
    
    @objc func pinched(sender: UIPinchGestureRecognizer) {
        if let selectedStickerEffect = self.selectedStickerEffect {
            if sender.state == .began {
                self.lastScale = 1
            } else {
                guard let lastScale = self.lastScale else {
                    return
                }
                let deltaScale = sender.scale / lastScale
                self.lastScale = sender.scale
                var destRect: CGRect!
                if let imageStickerEffect = selectedStickerEffect as? MSVImageStickerEditorEffect {
                    destRect = imageStickerEffect.destRect;
                    imageStickerEffect.destRect = .init(x: imageStickerEffect.destRect.origin.x - imageStickerEffect.destRect.size.width * (deltaScale - 1) / 2, y: imageStickerEffect.destRect.origin.y - imageStickerEffect.destRect.size.height * (deltaScale - 1) / 2, width: imageStickerEffect.destRect.size.width * deltaScale, height: imageStickerEffect.destRect.size.height * deltaScale)
                } else if let gifStickerEffect = selectedStickerEffect as? MSVAnimatedStickerEditorEffect {
                    destRect = gifStickerEffect.destRect;
                    gifStickerEffect.destRect = .init(x: gifStickerEffect.destRect.origin.x - gifStickerEffect.destRect.size.width * (deltaScale - 1) / 2, y: gifStickerEffect.destRect.origin.y - gifStickerEffect.destRect.size.height * (deltaScale - 1) / 2, width: gifStickerEffect.destRect.size.width * deltaScale, height: gifStickerEffect.destRect.size.height * deltaScale)
                }
                let contentFrame = self.editor.contentFrame
                let videoSize = self.editor.draft.videoSize
                let imageStickerFrame = CGRect(x: contentFrame.origin.x + destRect.origin.x / videoSize.width * contentFrame.size.width, y: contentFrame.origin.y + destRect.origin.y / videoSize.width * contentFrame.size.width, width: destRect.size.width / videoSize.width * contentFrame.size.width, height: destRect.size.height / videoSize.height * contentFrame.size.height)
                self.frameView.bounds = .init(x: 0, y: 0, width: imageStickerFrame.size.width + 2 * MDFrameViewMargin + self.frameView.margin, height: imageStickerFrame.size.height + 2 * MDFrameViewMargin + self.frameView.margin)
                self.deleteStickerButton.center = .init(x: self.frameView.bounds.size.width - self.frameView.margin - self.frameView.frameWidth / 2, y: self.frameView.margin + self.frameView.frameWidth / 2)
            }
        } else if let currentWordViewController = self.currentWordViewController {
            if let selectedWordLabel = currentWordViewController.selectedWordLabel {
                if sender.state == .began {
                    self.lastScale = 1
                } else {
                    guard let lastScale = self.lastScale else {
                        return
                    }
                    let deltaScale = sender.scale / lastScale
                    self.lastScale = sender.scale
                    selectedWordLabel.font = .systemFont(ofSize: selectedWordLabel.font.pointSize * deltaScale)
                    selectedWordLabel.bounds.size = selectedWordLabel.sizeThatFits(.init(width: CGFloat.infinity, height: CGFloat.infinity))
                    self.frameView.bounds = .init(x: 0, y: 0, width: selectedWordLabel.bounds.size.width + 2 * MDFrameViewMargin + self.frameView.margin, height: selectedWordLabel.bounds.size.height + 2 * MDFrameViewMargin + self.frameView.margin)
                    self.deleteStickerButton.center = .init(x: self.frameView.bounds.size.width - self.frameView.margin - self.frameView.frameWidth / 2, y: self.frameView.margin + self.frameView.frameWidth / 2)
                }
            }
        }
    }
    
    @objc func rotated(sender: UIRotationGestureRecognizer) {
        if let selectedStickerEffect = self.selectedStickerEffect {
            if sender.state == .began {
                self.lastRotation = 0
            } else {
                guard let lastRotation = self.lastRotation else {
                    return
                }
                let deltaRotation = sender.rotation - lastRotation
                self.lastRotation = sender.rotation
                if let imageStickerEffect = selectedStickerEffect as? MSVImageStickerEditorEffect {
                    imageStickerEffect.rotation = imageStickerEffect.rotation + deltaRotation
                } else if let gifStickerEffect = selectedStickerEffect as? MSVAnimatedStickerEditorEffect {
                    gifStickerEffect.rotation = gifStickerEffect.rotation + deltaRotation
                }
                self.frameView.transform = self.frameView.transform.concatenating(CGAffineTransform(rotationAngle: deltaRotation))
            }
        } else if let currentWordViewController = self.currentWordViewController {
            if let selectedWordLabel = currentWordViewController.selectedWordLabel {
                if sender.state == .began {
                    self.lastRotation = 0
                } else {
                    guard let lastRotation = self.lastRotation else {
                        return
                    }
                    let deltaRotation = sender.rotation - lastRotation
                    self.lastRotation = sender.rotation
                    selectedWordLabel.transform = self.frameView.transform.concatenating(CGAffineTransform(rotationAngle: deltaRotation))
                    self.frameView.transform = selectedWordLabel.transform
                }
            }
        }
    }
    
    @objc func currentTimeUpdated(sender: Notification) {
        if let currentWordViewController = self.currentWordViewController {
            if let selectedWordEffect = currentWordViewController.selectedWordEffect {
                if self.editor.currentTime >= selectedWordEffect.timeRangeAtMainTrack.startTime && self.editor.currentTime <= selectedWordEffect.timeRangeAtMainTrack.startTime + selectedWordEffect.timeRangeAtMainTrack.duration {
                    self.frameView.isHidden = false
                    currentWordViewController.selectedWordLabel?.isHidden = false
                } else {
                    self.frameView.isHidden = true
                    currentWordViewController.selectedWordLabel?.isHidden = true
                }
            }
        }
    }
}

extension MDVideoEditorViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        if viewController.isKind(of: MDEditorToolboxViewController.self) {
            self.selectedStickerEffect = nil
            self.syncWordEffect(videoSize: self.editor.draft.videoSize, contentFrame: self.editor.contentFrame)
        }
    }
}

extension MDVideoEditorViewController: MSVEditorDelegate {
    func editor(_ editor: MSVEditor, playStateChanged playing: Bool) {
        self.playButton.isSelected = !playing
    }
}

extension MDVideoEditorViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

extension MDVideoEditorViewController: MDEditorToolboxViewControllerDelegate {
    func editorToolboxViewController(editorToolboxViewController: MDEditorToolboxViewController, didSelectedItemAt index: Int) {
        switch index {
        case 0:
            let viewController = MDVolumeViewController()
            viewController.editor = self.editor
            viewController.recorderMusic = self.recorderMusic
            self.toolboxNavigationController.pushViewController(viewController, animated: true)
        case 1:
            let viewController = MDEditorMusicViewController()
            viewController.editor = self.editor
            viewController.recorderMusic = self.recorderMusic
            self.toolboxNavigationController.pushViewController(viewController, animated: true)
        case 2:
            let viewController = MDStickerViewController()
            viewController.delegate = self
            self.toolboxNavigationController.pushViewController(viewController, animated: true)
        case 3:
            let controller = MDBeautyFilterViewController()
            controller.faceBeautyEditorEffect = self.faceBeautyCaptureEffect
            controller.filterEditorEffect = self.filterCaptureEffect
            self.toolboxNavigationController.pushViewController(controller, animated: true)
        case 4:
            let viewController = MDTrimViewController()
            viewController.editor = self.editor
            viewController.thumbnailsCache = self.thumbnailsCache
            self.toolboxNavigationController.pushViewController(viewController, animated: true)
        case 5:
            let viewController = MDSpecialEffectViewController()
            viewController.editor = self.editor
            viewController.thumbnailsCache = self.thumbnailsCache
            viewController.reverseVideoExporter = self.reverseVideoExporter
            self.toolboxNavigationController.pushViewController(viewController, animated: true)
        case 6:
            let viewController = MDWordViewController()
            viewController.editor = self.editor
            viewController.thumbnailsCache = self.thumbnailsCache
            viewController.delegate = self
            self.currentWordViewController = viewController
            self.toolboxNavigationController.pushViewController(viewController, animated: true)
        case 7:
            var basicEffects: [MSVEditorEffect] = []
            for i in 0 ..< self.editor.draft.basicEffects.count {
                let basicEffect = self.editor.draft.basicEffects[i]
                if let imageStickerEffect = basicEffect as? MSVImageStickerEditorEffect {
                    if imageStickerEffect.getAttachmentForKey("type") as! String? == MDGraffitiEffectID {
                        self.previeousGraffitiIndex = i
                        continue
                    }
                }
                basicEffects.append(basicEffect)
            }
            do {
                try self.editor.draft.update(basicEffects: basicEffects)
            } catch {
                ShowErrorAlert(error: error, controller: self)
            }
            let viewController = MDVideoGraffitiViewController()
            viewController.delegate = self
            viewController.graffitiManager = self.editor.graffitiManager
            viewController.snapshotSize = self.editor.draft.videoSize
            self.toolboxNavigationController.pushViewController(viewController, animated: true)
        default:
            return
        }
    }
}

extension MDVideoEditorViewController: MDStickerViewControllerDelegate {
    func stickerViewController(stickerViewController: MDStickerViewController, didSelectSticker sticker: MDSticker) {
        var effects = self.editor.draft.basicEffects
        let videoSize = self.editor.draft.videoSize
        var effect: MSVEditorEffect!
        switch sticker.type {
        case .image:
            let imageStickerEffect = MSVImageStickerEditorEffect()
            imageStickerEffect.image = UIImage(contentsOfFile: sticker.localPaths![0])!
            imageStickerEffect.setAttachment(MDStickerEffectID, forKey: "type")
            imageStickerEffect.destRect = .init(x: (videoSize.width - imageStickerEffect.image.size.width) / 2, y: (videoSize.height - imageStickerEffect.image.size.height) / 2, width: imageStickerEffect.image.size.width, height: imageStickerEffect.image.size.height)
            effect = imageStickerEffect
        case .gif:
            let gifStickerEffect = MSVAnimatedStickerEditorEffect(gifData: try! .init(contentsOf: .init(fileURLWithPath: sticker.localPaths![0])))
            gifStickerEffect.setAttachment(MDStickerEffectID, forKey: "type")
            gifStickerEffect.destRect = .init(x: (videoSize.width - gifStickerEffect.size.width) / 2, y: (videoSize.height - gifStickerEffect.size.height) / 2, width: gifStickerEffect.size.width, height: gifStickerEffect.size.height)
            effect = gifStickerEffect
            break
        case .images:
            let gifStickerEffect = MSVAnimatedStickerEditorEffect(imagePaths: sticker.localPaths!, interval: 1.0 / 24)
            gifStickerEffect.setAttachment(MDStickerEffectID, forKey: "type")
            gifStickerEffect.destRect = .init(x: (videoSize.width - gifStickerEffect.size.width) / 2, y: (videoSize.height - gifStickerEffect.size.height) / 2, width: gifStickerEffect.size.width, height: gifStickerEffect.size.height)
            effect = gifStickerEffect
            break
        default:
            break
        }
        effects.append(effect)
        do {
            try self.editor.draft.update(basicEffects: effects)
        } catch {
            ShowErrorAlert(error: error, controller: self)
        }
    }
}

extension MDVideoEditorViewController: MDVideoGraffitiViewControllerDelegate {
    func graffitiManagerController(graffitiManagerController: MDVideoGraffitiViewController, didGetGraffiti imageStickerEditorEffect: MSVImageStickerEditorEffect) {
        imageStickerEditorEffect.setAttachment(MDGraffitiEffectID, forKey: "type")
        var basicEffects = self.editor.draft.basicEffects
        if self.previeousGraffitiIndex >= 0 {
            basicEffects.insert(imageStickerEditorEffect, at: self.previeousGraffitiIndex)
        } else {
            basicEffects.append(imageStickerEditorEffect)
        }
        do {
            try self.editor.draft.update(basicEffects: basicEffects)
        } catch {
            ShowErrorAlert(error: error, controller: self)
        }
    }
}

extension MDVideoEditorViewController: MDWordViewControllerDelegate {
    func wordViewController(wordViewController: MDWordViewController, shouldPresnt viewController: UIViewController) {
        viewController.modalPresentationStyle = .pageSheet
        self.present(viewController, animated: true, completion: nil)
    }
}
