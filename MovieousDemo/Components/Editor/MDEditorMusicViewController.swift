//
//  MDEditorMusicViewController.swift
//  MovieousDemo
//
//  Created by Chris Wang on 2019/6/27.
//  Copyright © 2019 Movieous Team. All rights reserved.
//

import UIKit
import SVProgressHUD
import M13ProgressSuite
import MovieousShortVideo

class MDEditorMusicViewController: UIViewController {
    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: MDHorizontalPageFlowlayout(rowCount: 2, itemCountPerRow: 3, columnSpacing: 5, rowSpacing: 5, edgeInsets: UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)))
    let pageControl = UIPageControl()
    var selectedMusicIndex = -1
    var editor: MSVEditor!
    var recorderMusic: MDMusic?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.buildUI()
        NotificationCenter.default.addObserver(self, selector: #selector(musicLibraryRefreshDone(sender:)), name: .MDMusicLibraryRefreshDone, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(musicLibraryRefreshError(sender:)), name: .MDMusicLibraryRefreshError, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(musicDidUpdated(sender:)), name: .MDMusicDidUpdated, object: nil)
        MDMusicLibrary.refreshMusics()
    }
    
    @objc func musicLibraryRefreshDone(sender: Notification) {
        DispatchQueue.main.async {
            if let clip = self.editor.draft.mixTrackClips.first {
                for music in MDMusicLibrary.musics {
                    if let localPath = music.localPath {
                        if localPath == clip.path {
                            self.selectedMusicIndex = MDMusicLibrary.musics.firstIndex(of: music)!
                            break
                        }
                    }
                }
            } else {
                if let recorderMusic = self.recorderMusic {
                    for music in MDMusicLibrary.musics {
                        if recorderMusic == music {
                            self.selectedMusicIndex = MDMusicLibrary.musics.firstIndex(of: music)!
                            break
                        }
                    }
                }
            }
            let layout = self.collectionView.collectionViewLayout as! MDHorizontalPageFlowlayout
            self.pageControl.numberOfPages = (MDMusicLibrary.musics.count - 1) / (layout.rowCount * layout.itemCountPerRow) + 1
            self.collectionView.reloadData()
        }
    }
    
    @objc func musicLibraryRefreshError(sender: Notification) {
        ShowErrorAlert(error: sender.userInfo![MDMusicLibraryRefreshErrorKey]! as! Error, controller: self)
    }
    
    @objc func musicDidUpdated(sender: Notification) {
        let music = sender.userInfo![MDMusicDidUpdatedKey]! as! MDMusic
        if let cell = self.collectionView.cellForItem(at: IndexPath(item: MDMusicLibrary.musics.firstIndex(of: music)!, section: 0)) {
            (cell as! MDEditorMusicCollectionViewCell).update(with: music, animated: true)
        }
        if music.localPath != nil {
            if MDMusicLibrary.musics.firstIndex(of: music) == self.selectedMusicIndex {
                self.updateMusic(music: music)
            }
        }
    }
    
    @objc func pageControlValueChanged(sender: UIPageControl) {
        self.collectionView.setContentOffset(CGPoint(x: self.collectionView.frame.size.width * CGFloat(sender.currentPage), y: 0), animated: true)
    }
    
    @objc func cancelButtonPressed(sender: UIButton) {
        self.updateMusic(music: nil)
        self.selectedMusicIndex = -1
        self.collectionView.reloadData()
    }
    
    func buildUI() {
        self.title = NSLocalizedString("MDEditorMusicViewController.title", comment: "")
        self.view.backgroundColor = .black
        
        if recorderMusic == nil {
            let cancelButton = MDButton()
            cancelButton.titleLabel?.font = .systemFont(ofSize: 12)
            cancelButton.addTarget(self, action: #selector(cancelButtonPressed(sender:)), for: .touchUpInside)
            cancelButton.frame = CGRect(x: 0, y: 0, width: 63, height: 26)
            cancelButton.setTitle(NSLocalizedString("MDEditorMusicViewController.cancel", comment: ""), for: .normal)
            self.navigationItem.rightBarButtonItem = .init(customView: cancelButton)
        }
        
        self.collectionView.isPagingEnabled = true
        self.collectionView.register(MDEditorMusicCollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.showsHorizontalScrollIndicator = false
        self.view.addSubview(self.collectionView)
        // 只能异步执行才能保证 contentInset 被清空
        DispatchQueue.main.async {
            self.collectionView.contentInset = .zero
        }
        
        self.pageControl.addTarget(self, action: #selector(pageControlValueChanged(sender:)), for: .valueChanged)
        self.view.addSubview(self.pageControl)
        let layout = self.collectionView.collectionViewLayout as! MDHorizontalPageFlowlayout
        self.pageControl.numberOfPages = (MDMusicLibrary.musics.count - 1) / (layout.rowCount * layout.itemCountPerRow) + 1
        
        self.pageControl.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview()
            make.centerX.equalToSuperview()
        }
        
        self.collectionView.snp.makeConstraints { (make) in
            make.top.equalTo(topLayoutGuide.snp.bottom)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalTo(self.pageControl.snp.top)
        }
    }
    
    func updateMusic(music: MDMusic?) {
        self.editor.draft.beginChangeTransaction()
        do {
            if let music = music {
                if music == self.recorderMusic {
                    for clip in self.editor.draft.mainTrackClips {
                        clip.volume = 1
                    }
                    try self.editor.draft.update(mixTrackClips:nil)
                } else {
                    (self.editor.draft.getAttachmentForKey(MDOriginalMainTrackClipKey) as! MSVMainTrackClip?)?.volume = 0
                    for clip in self.editor.draft.mainTrackClips {
                        clip.volume = 0
                    }
                    try self.editor.draft.update(mixTrackClips: [try .init(type: .AV, path: music.localPath!)])
                }
            } else {
                for clip in self.editor.draft.mainTrackClips {
                    clip.volume = 1
                }
                try self.editor.draft.update(mixTrackClips:nil)
            }
        } catch {
            ShowErrorAlert(error: error, controller: self)
            return
        }
        do {
            try self.editor.draft.commitChange()
        } catch {
            ShowErrorAlert(error: error, controller: self)
            return
        }
    }
}

extension MDEditorMusicViewController: UICollectionViewDelegate {
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        self.pageControl.currentPage = Int(targetContentOffset.pointee.x / self.collectionView.frame.size.width)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let music = MDMusicLibrary.musics[indexPath.item]
        self.selectedMusicIndex = indexPath.item
        if music.localPath == nil {
            music.download()
        } else {
            self.updateMusic(music: music)
        }
        self.collectionView.reloadData()
    }
}

extension MDEditorMusicViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return MDMusicLibrary.musics.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! MDEditorMusicCollectionViewCell
        let music = MDMusicLibrary.musics[indexPath.item]
        cell.update(with: music, animated: false)
        cell.setIsSelected(isSelected: self.selectedMusicIndex == indexPath.item)
        return cell
    }
}

class MDEditorMusicCollectionViewCell: UICollectionViewCell {
    private let nameLabel = UILabel()
    private let authorLabel = UILabel()
    private let downloadIcon = UIImageView(image: UIImage(named: "download"))
    private let progressView = M13ProgressViewPie()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = .init(r: 41, g: 41, b: 41, a: 1)
        
        self.nameLabel.font = .systemFont(ofSize: 11)
        self.nameLabel.textColor = .init(r: 173, g: 173, b: 173, a: 1)
        self.nameLabel.numberOfLines = 3
        self.contentView.addSubview(self.nameLabel)
        
        self.authorLabel.font = .systemFont(ofSize: 9)
        self.authorLabel.textColor = .init(r: 126, g: 126, b: 126, a: 1)
        self.authorLabel.numberOfLines = 3
        self.contentView.addSubview(self.authorLabel)
        
        self.contentView.addSubview(self.downloadIcon)
        
        self.progressView.primaryColor = .init(r: 173, g: 173, b: 173, a: 1)
        self.progressView.secondaryColor = .init(r: 126, g: 126, b: 126, a: 1)
        self.progressView.animationDuration = 0.01
        self.contentView.addSubview(self.progressView)
        
        self.nameLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(11)
            make.right.equalToSuperview().offset(-11)
            make.top.equalToSuperview().offset(11)
        }
        
        self.authorLabel.snp.makeConstraints { (make) in
            make.left.equalTo(self.nameLabel)
            make.right.equalTo(self.nameLabel)
            make.top.equalTo(self.nameLabel.snp.bottom).offset(7)
        }
        
        self.downloadIcon.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-10)
            make.bottom.equalToSuperview().offset(-10)
            make.width.equalTo(7)
            make.height.equalTo(6)
        }
        
        self.progressView.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-10)
            make.bottom.equalToSuperview().offset(-10)
            make.width.equalTo(15)
            make.height.equalTo(15)
        }
    }
    
    func update(with music: MDMusic, animated: Bool) {
        self.nameLabel.text = music.name
        self.authorLabel.text = music.author
        if music.localPath == nil {
            if music.isDownLoading {
                self.progressView.setProgress(music.progress, animated: animated)
                self.downloadIcon.isHidden = true
                self.progressView.isHidden = false
            } else {
                self.downloadIcon.isHidden = false
                self.progressView.isHidden = true
            }
        } else {
            self.downloadIcon.isHidden = true
            self.progressView.isHidden = true
        }
    }
    
    func setIsSelected(isSelected: Bool) {
        if isSelected {
            self.backgroundColor = .init(r: 60, g: 60, b: 60, a: 1)
        } else {
            self.backgroundColor = .init(r: 41, g: 41, b: 41, a: 1)
        }
    }
}
