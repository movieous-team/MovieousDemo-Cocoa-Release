//
//  MDEditorViewController.swift
//  MovieousDemo
//
//  Created by Chris Wang on 2019/8/30.
//  Copyright © 2019 Movieous Team. All rights reserved.
//

import UIKit
import MovieousShortVideo

class MDEditorViewController: UIViewController {
    var draft: MSVDraft!
    var editor: MSVEditor!
    let playButton = MDButton()
    lazy var thumbnailScrollView: UIScrollView = {
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(pinched(sender:)))
        let thumbnailScrollView = UIScrollView()
        thumbnailScrollView.addGestureRecognizer(pinch)
        thumbnailScrollView.delegate = self
        thumbnailScrollView.showsVerticalScrollIndicator = false
        thumbnailScrollView.showsHorizontalScrollIndicator = false
        return thumbnailScrollView
    }()
    let contentView = UIView()
    let videoTimeIndicator: UIView = {
        let videoTimeIndicator = UIView()
        videoTimeIndicator.backgroundColor = .white
        return videoTimeIndicator
    }()
    var durationPerThumbnail = MDDefaultDurationPerThumbnail
    let toolboxCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let toolboxCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        return toolboxCollectionView
    }()
    var lastScale: CGFloat!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        do {
            self.editor = try MSVEditor(draft: self.draft)
        } catch {
            ShowErrorAlert(error: error, controller: self)
        }
        NotificationCenter.default.addObserver(self, selector: #selector(currentTimeUpdated(sender:)), name: .msvEditorCurrentTimeUpdated, object: self.editor)
        self.editor.loop = true
        self.editor.delegate = self
        self.editor.preview.clipsToBounds = true
        self.buildUI()
        self.editor.play()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = false
        self.navigationController?.setTransparent(transparent: true)
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
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
        
        self.view.addSubview(self.editor.preview)
        
        self.view.addSubview(self.thumbnailScrollView)
        
        self.thumbnailScrollView.backgroundColor = .blue
        self.contentView.backgroundColor = .red
        self.thumbnailScrollView.addSubview(self.contentView)
        
        self.view.addSubview(self.toolboxCollectionView)
        
        self.view.addSubview(self.videoTimeIndicator)
        
        self.editor.preview.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.bottom.equalTo(self.thumbnailScrollView.snp_top)
            make.right.equalToSuperview()
            make.left.equalToSuperview()
        }
        
        self.contentView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(self.view.frame.size.width / 2)
            make.right.equalToSuperview().offset(-self.view.frame.size.width / 2)
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalToSuperview()
        }
        
        var left = self.contentView.snp.left
        for clip in self.editor.draft.mainTrackClips {
            let thumbnailCache = MDThumbnailsCache(clip: clip)
            let ratio = TimeInterval(clip.size.width / clip.size.height)
            if ratio >= 1 {
                thumbnailCache.maximumSize = .init(width: MDThumbnailBarHeight * TimeInterval(UIScreen.main.scale) * ratio, height: MDThumbnailBarHeight * TimeInterval(UIScreen.main.scale))
            } else {
                thumbnailCache.maximumSize = .init(width: MDThumbnailBarHeight * TimeInterval(UIScreen.main.scale), height: MDThumbnailBarHeight * TimeInterval(UIScreen.main.scale) / ratio)
            }
            let thumbnailBar = MDThumbnailBar(thumbnailCache: thumbnailCache)
            thumbnailBar.layer.masksToBounds = true
            thumbnailBar.layer.cornerRadius = 2
            self.contentView.addSubview(thumbnailBar)
            thumbnailBar.snp.makeConstraints { (make) in
                if clip == self.editor.draft.mainTrackClips.first {
                    make.left.equalTo(left)
                } else {
                    make.left.equalTo(left).offset(2)
                }
                make.width.equalTo(MDThumbnailBarHeight * clip.timeRange.duration / self.durationPerThumbnail)
                make.top.equalToSuperview().offset(50)
                make.height.equalTo(MDThumbnailBarHeight)
            }
            clip.setAttachment(thumbnailBar, forKey: "thumbnailBar")
            left = thumbnailBar.snp.right
        }
        self.contentView.snp.makeConstraints { (make) in
            make.right.equalTo(left)
        }
        
        self.thumbnailScrollView.snp.makeConstraints { (make) in
            make.right.equalToSuperview()
            make.left.equalToSuperview()
            make.height.equalTo(210)
            make.bottom.equalTo(self.toolboxCollectionView.snp.top)
        }
        
        self.toolboxCollectionView.snp.makeConstraints { (make) in
            make.right.equalToSuperview()
            make.left.equalToSuperview()
            make.height.equalTo(44)
            make.bottom.equalToSuperview()
        }
        
        self.videoTimeIndicator.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.width.equalTo(2)
            make.top.equalTo(self.thumbnailScrollView)
            make.bottom.equalTo(self.thumbnailScrollView)
        }
    }
    
    @objc func currentTimeUpdated(sender: Notification) {
        if !self.thumbnailScrollView.isDragging {
            self.thumbnailScrollView.setContentOffset(.init(x: self.contentView.frame.size.width * CGFloat(self.editor.currentTime / self.editor.draft.duration), y: 0), animated: false)
        }
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
        self.navigationController?.push(vc, animated: true)
    }
    
    @objc func pinched(sender: UIPinchGestureRecognizer) {
        if sender.state == .began {
            self.lastScale = 1
        } else {
            var deltaScale = sender.scale / self.lastScale
            self.lastScale = sender.scale
            let pendingDurationPerThumbnail = self.durationPerThumbnail / TimeInterval(deltaScale)
            if pendingDurationPerThumbnail > MDMaxDurationPerThumbnail {
                deltaScale = CGFloat(self.durationPerThumbnail / MDMaxDurationPerThumbnail)
                self.durationPerThumbnail = MDMaxDurationPerThumbnail
            } else if pendingDurationPerThumbnail < 1.0 / MDVideoFrameRate {
                deltaScale = CGFloat(self.durationPerThumbnail * MDVideoFrameRate)
                self.durationPerThumbnail = 1.0 / MDVideoFrameRate
            } else {
                self.durationPerThumbnail = pendingDurationPerThumbnail
            }
            for clip in self.editor.draft.mainTrackClips {
                let thumbnailBar = clip.getAttachmentForKey("thumbnailBar")! as! MDThumbnailBar
                thumbnailBar.snp.updateConstraints { (make) in
                    make.width.equalTo(MDThumbnailBarHeight * clip.timeRange.duration / self.durationPerThumbnail)
                }
            }
            self.thumbnailScrollView.contentOffset = .init(x: self.thumbnailScrollView.contentOffset.x * deltaScale, y: self.thumbnailScrollView.contentOffset.y)
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}

extension MDEditorViewController: MSVEditorDelegate {
    func editor(_ editor: MSVEditor, playStateChanged playing: Bool) {
        self.playButton.isSelected = !playing
    }
}

extension MDEditorViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.editor.pause()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.isDragging {
            let time = self.editor.draft.duration * TimeInterval(scrollView.contentOffset.x / self.contentView.frame.size.width)
            self.editor.seek(toTime: time, accurate: true)
        }
    }
}
