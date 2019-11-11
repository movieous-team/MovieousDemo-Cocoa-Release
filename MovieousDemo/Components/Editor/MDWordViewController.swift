//
//  MDWordViewController.swift
//  MovieousDemo
//
//  Created by Chris Wang on 2019/8/13.
//  Copyright © 2019 Movieous Team. All rights reserved.
//

import UIKit
import MovieousShortVideo

let MDWordEffectID = "MDWordEffectID"

protocol MDWordViewControllerDelegate: NSObjectProtocol {
//    func wordViewController(wordViewController: MDWordViewController, didSelectedWordAt index: Int)
    func wordViewController(wordViewController: MDWordViewController, shouldPresnt viewController: UIViewController)
}

class MDWordViewController: UIViewController {
    weak var delegate: MDWordViewControllerDelegate?
    var editor: MSVEditor!
    var thumbnailsCache: MDThumbnailsCache!
    var thumbnailBar: MDThumbnailBar!
    var originalMainTrackClip: MSVMainTrackClip!
    var scrollView = UIScrollView()
    let wordInterval = TimeInterval(0.1)
    let currentTimeIndicator: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()
    lazy var addWordButton: MDButton = {
        let button = MDButton(cornerRadius: 1)
        button.setImage(UIImage(named: "plus"), for: .normal)
        button.contentEdgeInsets = .init(top: 7, left: 7, bottom: 7, right: 7)
        button.addTarget(self, action: #selector(addWordButtonPressed(sender:)), for: .touchUpInside)
        return button
    }()
    let offset = UIScreen.main.bounds.size.width / 2
    let thumbBarWidth = CGFloat(1000)
    var selectedWordEffect: MSVImageStickerEditorEffect?
    var selectedWordLabel: UILabel?
    var selectedWordContainerView: UIView?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.view.backgroundColor = .black
        self.title = NSLocalizedString("MDWordViewController.title", comment: "")
        
        self.originalMainTrackClip = (self.editor.draft.getAttachmentForKey(MDOriginalMainTrackClipKey)! as! MSVMainTrackClip)
        
        NotificationCenter.default.addObserver(self, selector: #selector(currentTimeUpdated(sender:)), name: .msvEditorCurrentTimeUpdated, object: self.editor)
        
        self.view.addSubview(self.scrollView)
        
        self.scrollView.showsVerticalScrollIndicator = false
        self.scrollView.showsHorizontalScrollIndicator = false
        self.scrollView.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.top.equalTo(topLayoutGuide.snp.bottom).offset(10)
            make.height.equalTo(MDThumbnailBarHeight * 2 + 30)
        }
        
        self.thumbnailBar = .init(thumbnailCache: self.thumbnailsCache, timeRange: self.originalMainTrackClip.timeRange)
        self.scrollView.addSubview(self.thumbnailBar)
        self.scrollView.delegate = self
        self.thumbnailBar.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(self.offset)
            make.width.equalTo(self.thumbBarWidth)
            make.right.equalToSuperview().offset(-self.offset)
            make.top.equalToSuperview()
            make.height.equalTo(MDThumbnailBarHeight)
            make.bottom.equalToSuperview()
        }
        
        self.view.addSubview(self.currentTimeIndicator)
        self.currentTimeIndicator.snp.makeConstraints { (make) in
            make.top.equalTo(topLayoutGuide.snp.bottom)
            make.width.equalTo(1)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        self.view.addSubview(self.addWordButton)
        self.addWordButton.snp.makeConstraints { (make) in
            make.left.equalTo(self.currentTimeIndicator.snp.right).offset(2)
            make.top.equalTo(self.scrollView.snp.bottom)
            make.size.equalTo(30)
        }
        
        DispatchQueue.main.async {
            self.scrollView.setContentOffset(.init(x: self.thumbnailBar.frame.size.width * CGFloat(self.editor.currentTime / self.editor.draft.duration), y: 0), animated: false)
            for i in (0...self.editor.draft.basicEffects.count - 1).reversed() {
                if let effect = self.editor.draft.basicEffects[i] as? MSVImageStickerEditorEffect {
                    if effect.getAttachmentForKey("type") as! String? != MDWordEffectID {
                        continue
                    }
                    let thumbnailLabel = effect.getAttachmentForKey("thumbnailLabel") as! UILabel
                    self.scrollView.addSubview(thumbnailLabel)
                    thumbnailLabel.snp.makeConstraints { (make) in
                        make.top.equalTo(self.thumbnailBar.snp.bottom).offset(10)
                        make.height.equalTo(MDThumbnailBarHeight)
                        make.left.equalToSuperview().offset(self.thumbBarWidth * CGFloat(effect.timeRangeAtMainTrack.startTime /
                            self.editor.draft.timeRange.duration) + self.offset)
                        make.width.equalTo(self.thumbBarWidth * CGFloat(effect.timeRangeAtMainTrack.duration / self.editor.draft.timeRange.duration))
                    }
                }
            }
            self.syncAddWordButton()
        }
    }
    
    @objc func currentTimeUpdated(sender: Notification) {
        if !scrollView.isDragging {
            self.scrollView.setContentOffset(.init(x: self.thumbnailBar.frame.size.width * CGFloat(self.editor.currentTime / self.editor.draft.duration), y: 0), animated: false)
        }
        self.syncAddWordButton()
    }
    
    func syncAddWordButton() {
        for effect in self.editor.draft.basicEffects {
            if let effect = effect as? MSVImageStickerEditorEffect {
                if effect.getAttachmentForKey("type") as! String? != MDWordEffectID {
                    continue
                }
                if self.editor.currentTime >= effect.timeRangeAtMainTrack.startTime - self.wordInterval && self.editor.currentTime <= effect.timeRangeAtMainTrack.startTime + effect.timeRangeAtMainTrack.duration + self.wordInterval {
                    self.addWordButton.isHidden = true
                    return
                }
            }
        }
        if let selectedWordEffect = self.selectedWordEffect {
            if self.editor.currentTime >= selectedWordEffect.timeRangeAtMainTrack.startTime - self.wordInterval && self.editor.currentTime <= selectedWordEffect.timeRangeAtMainTrack.startTime + selectedWordEffect.timeRangeAtMainTrack.duration + self.wordInterval {
                self.addWordButton.isHidden = true
                return
            }
        }
        self.addWordButton.isHidden = false
    }
    
    @objc func addWordButtonPressed(sender: UIButton) {
        let vc = MDWordInputViewController()
        vc.delegate = self
        if let delegate = self.delegate {
            delegate.wordViewController(wordViewController: self, shouldPresnt: vc)
        }
    }
    
    func deleteButtonPressed() {
        self.selectedWordContainerView?.removeFromSuperview()
        let thumbnailLabel = self.selectedWordEffect?.getAttachmentForKey("thumbnailLabel") as! UILabel?
        thumbnailLabel?.removeFromSuperview()
        self.selectedWordLabel = nil
        self.selectedWordEffect = nil
        self.addWordButton.isHidden = false
    }
}

extension MDWordViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.editor.pause()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.isDragging {
            let time = self.editor.draft.duration * TimeInterval(scrollView.contentOffset.x / self.thumbnailBar.frame.size.width)
            self.editor.seek(toTime: time, accurate: true)
        }
    }
}

extension MDWordViewController: MDWordInputViewControllerDelegate {
    func wordInputViewController(_ wordInputViewController: MDWordInputViewController, didInputText text: String) {
        if text.count > 0 {
            self.addWordButton.isHidden = true
            
            let label = UILabel()
            label.numberOfLines = 0
            label.font = .systemFont(ofSize: 100)
            label.textColor = .white
            label.backgroundColor = .red
            label.text = text
            label.allowsDefaultTighteningForTruncation = true
            let size = label.sizeThatFits(.init(width: CGFloat.infinity, height: CGFloat.infinity))
            let videoSize = self.editor.draft.videoSize
            let containerView = UIView()
            containerView.frame = .init(origin: .zero, size: videoSize)
            containerView.clipsToBounds = true
            containerView.addSubview(label)
            label.frame = .init(origin: .init(x: (videoSize.width - size.width) / 2, y: (videoSize.height - size.height) / 2), size: size)
            let image = containerView.snapshot()
            
            let imageEffect = MSVImageStickerEditorEffect()
            imageEffect.image = image
            imageEffect.setAttachment(MDWordEffectID, forKey: "type")
            let startTime = self.editor.currentTime
            var duration = TimeInterval(2)
            for effect in self.editor.draft.basicEffects {
                if let effect = effect as? MSVImageStickerEditorEffect {
                    if effect.getAttachmentForKey("type") as! String? != MDWordEffectID {
                        continue
                    }
                    if effect.timeRangeAtMainTrack.startTime - startTime - self.wordInterval > 0 && effect.timeRangeAtMainTrack.startTime - startTime - self.wordInterval < duration {
                        duration = effect.timeRangeAtMainTrack.startTime - startTime - self.wordInterval
                    }
                }
            }
            if let selectedWordEffect = self.selectedWordEffect {
                if selectedWordEffect.timeRangeAtMainTrack.startTime - startTime - self.wordInterval > 0 && selectedWordEffect.timeRangeAtMainTrack.startTime - startTime - self.wordInterval < duration {
                    duration = selectedWordEffect.timeRangeAtMainTrack.startTime - startTime - self.wordInterval
                }
            }
            if self.editor.draft.timeRange.duration - startTime < duration {
                duration = self.editor.draft.timeRange.duration - startTime
            }
            imageEffect.timeRangeAtMainTrack = .init(startTime: startTime, duration: duration)
            imageEffect.destRect = .init(origin: .init(x: (videoSize.width - videoSize.width) / 2, y: (videoSize.height - videoSize.height) / 2), size: videoSize)
            imageEffect.setAttachment(containerView, forKey: "containerView")
            
            let thumbnailLabel = UILabel()
            thumbnailLabel.textColor = .white
            thumbnailLabel.backgroundColor = .init(r: 235, g: 97, b: 111, a: 1)
            thumbnailLabel.text = text
            thumbnailLabel.lineBreakMode = .byClipping
            self.scrollView.addSubview(thumbnailLabel)
            thumbnailLabel.snp.makeConstraints { (make) in
                make.top.equalTo(self.thumbnailBar.snp.bottom).offset(10)
                make.height.equalTo(MDThumbnailBarHeight)
                make.left.equalToSuperview().offset(self.thumbBarWidth * CGFloat(imageEffect.timeRangeAtMainTrack.startTime /
                    self.editor.draft.timeRange.duration) + self.offset)
                make.width.equalTo(self.thumbBarWidth * CGFloat(imageEffect.timeRangeAtMainTrack.duration / self.editor.draft.timeRange.duration))
            }
            imageEffect.setAttachment(thumbnailLabel, forKey: "thumbnailLabel")
            
            do {
                var effects = self.editor.draft.basicEffects
                effects.append(imageEffect)
                try self.editor.draft.update(basicEffects: effects)
            } catch {
                ShowErrorAlert(error: error, controller: self)
            }
        }
    }
}

protocol MDWordInputViewControllerDelegate: NSObjectProtocol {
    func wordInputViewController(_ wordInputViewController: MDWordInputViewController, didInputText text: String)
}

class MDWordInputViewController: UIViewController {
    weak var delegate: MDWordInputViewControllerDelegate?
    let navigationBar = UINavigationBar()
    let textView = UITextView()
    
    override func viewDidLoad() {
        self.view.backgroundColor = .black
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        let item = UINavigationItem(title: "")
        let right = UIBarButtonItem(title: "确定", style: .plain, target: self, action: #selector(doneButtonPressed(sender:)))
        item.rightBarButtonItem = right
        let left = UIBarButtonItem(title: "取消", style: .plain, target: self, action: #selector(doneButtonPressed(sender:)))
        item.leftBarButtonItem = left
        self.navigationBar.pushItem(item, animated: false)
        self.navigationBar.barTintColor = .black
        self.navigationBar.tintColor = .white
        self.view.addSubview(self.navigationBar)
        self.navigationBar.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.top.equalToSuperview()
        }
        
        self.textView.backgroundColor = .black
        self.textView.textColor = .white
        self.textView.tintColor = .white
        self.textView.font = .systemFont(ofSize: 20)
        self.textView.textAlignment = .center
        self.view.addSubview(self.textView)
        self.textView.snp.makeConstraints { (make) in
            make.top.equalTo(self.navigationBar.snp.bottom)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        self.textView.becomeFirstResponder()
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            self.textView.snp.updateConstraints { (make) in
                make.bottom.equalToSuperview().offset(-keyboardHeight)
            }
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    @objc func doneButtonPressed(sender: UIBarButtonItem) {
        if let delegate = self.delegate {
            delegate.wordInputViewController(self, didInputText: self.textView.text)
        }
        self.textView.resignFirstResponder()
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func cancelButtonPressed(sender: UIBarButtonItem) {
        self.textView.resignFirstResponder()
        self.dismiss(animated: true, completion: nil)
    }
}
