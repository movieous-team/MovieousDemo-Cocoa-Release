
//
//  MDStickerViewController.swift
//  MovieousDemo
//
//  Created by Chris Wang on 2019/6/27.
//  Copyright © 2019 Movieous Team. All rights reserved.
//

import UIKit
import MovieousShortVideo
import SDWebImage
import M13ProgressSuite

protocol MDStickerViewControllerDelegate: NSObjectProtocol {
    func stickerViewController(stickerViewController: MDStickerViewController, didSelectSticker sticker: MDSticker)
}

class MDStickerViewController: UIViewController {
    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: MDHorizontalPageFlowlayout(rowCount: 2, itemCountPerRow: 4, columnSpacing: 5, rowSpacing: 5, edgeInsets: UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)))
    let pageControl = UIPageControl()
    weak var delegate: MDStickerViewControllerDelegate?
    var stickerType = MDSticker.StickerType.all {
        didSet {
            self.updateValidStickers()
        }
    }
    var validStickers: [MDSticker] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.buildUI()
//        NotificationCenter.default.addObserver(self, selector: #selector(stickerLibraryRefreshDone(sender:)), name: .MDStickerLibraryRefreshDone, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(stickerLibraryRefreshError(sender:)), name: .MDStickerLibraryRefreshError, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(stickerDidUpdated(sender:)), name: .MDStickerDidUpdated, object: nil)
//        MDStickerLibrary.refreshStickers()
    }
    
    func buildUI() {
        self.title = NSLocalizedString("MDStickerViewController.title", comment: "")
        self.view.backgroundColor = .black
        
        let view = FUStickerView()
        self.view.addSubview(view)
        view.snp.makeConstraints({ (make) in
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        })
        
//        self.collectionView.isPagingEnabled = true
//        self.collectionView.register(MDStickerCollectionViewCell.self, forCellWithReuseIdentifier: "cell")
//        self.collectionView.delegate = self
//        self.collectionView.dataSource = self
//        self.collectionView.showsHorizontalScrollIndicator = false
//        self.view.addSubview(self.collectionView)
//        // 只能异步执行才能保证 contentInset 被清空
//        DispatchQueue.main.async {
//            self.collectionView.contentInset = .zero
//        }
//
//        self.pageControl.addTarget(self, action: #selector(pageControlValueChanged(sender:)), for: .valueChanged)
//        self.view.addSubview(self.pageControl)
//
//        self.pageControl.snp.makeConstraints { (make) in
//            make.bottom.equalToSuperview()
//            make.centerX.equalToSuperview()
//        }
//
//        self.collectionView.snp.makeConstraints { (make) in
//            make.top.equalTo(topLayoutGuide.snp.bottom)
//            make.left.equalToSuperview()
//            make.right.equalToSuperview()
//            make.bottom.equalTo(self.pageControl.snp.top)
//        }
    }
    
    func updateValidStickers() {
        DispatchQueue.main.async {
            self.validStickers.removeAll()
            for sticker in MDStickerLibrary.stickers {
                if self.stickerType.rawValue & sticker.type.rawValue != 0 {
                    self.validStickers.append(sticker)
                }
            }
            let layout = self.collectionView.collectionViewLayout as! MDHorizontalPageFlowlayout
            self.pageControl.numberOfPages = (self.validStickers.count - 1) / (layout.rowCount * layout.itemCountPerRow) + 1
            self.collectionView.reloadData()
        }
    }
    
    @objc func stickerLibraryRefreshDone(sender: Notification) {
        self.updateValidStickers()
    }
    
    @objc func stickerLibraryRefreshError(sender: Notification) {
        ShowErrorAlert(error: sender.userInfo![MDStickerLibraryRefreshErrorKey]! as! Error, controller: self)
    }
    
    @objc func stickerDidUpdated(sender: Notification) {
        let sticker = sender.userInfo![MDStickerDidUpdatedKey]! as! MDSticker
        if let cell = self.collectionView.cellForItem(at: IndexPath(item: self.validStickers.firstIndex(of: sticker)!, section: 0)) {
            self.updateCell(cell as! MDStickerCollectionViewCell, sticker: sticker, animated: true)
        }
        if sticker.localPaths != nil {
            if let delegate = self.delegate {
                delegate.stickerViewController(stickerViewController: self, didSelectSticker: sticker)
            }
        }
    }
    
    func updateCell(_ cell: MDStickerCollectionViewCell, sticker: MDSticker, animated: Bool) {
        cell.setThumbnailURL(thumbnailURL: sticker.thumbnailURL)
        if sticker.localPaths == nil {
            if sticker.isDownLoading {
                cell.setProgress(progress: sticker.progress, animated: animated)
                cell.setDownloadIconHidden(isHidden: true)
                cell.setProgressViewHidden(isHidden: false)
            } else {
                cell.setDownloadIconHidden(isHidden: false)
                cell.setProgressViewHidden(isHidden: true)
            }
        } else {
            cell.setDownloadIconHidden(isHidden: true)
            cell.setProgressViewHidden(isHidden: true)
        }
    }
    
    @objc func pageControlValueChanged(sender: UIPageControl) {
        self.collectionView.setContentOffset(CGPoint(x: self.collectionView.frame.size.width * CGFloat(sender.currentPage), y: 0), animated: true)
    }
}

extension MDStickerViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let sticker = self.validStickers[indexPath.item]
        if sticker.localPaths == nil {
            sticker.download()
        } else {
            if let delegate = self.delegate {
                delegate.stickerViewController(stickerViewController: self, didSelectSticker: sticker)
            }
        }
    }
}

extension MDStickerViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.validStickers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! MDStickerCollectionViewCell
        self.updateCell(cell, sticker: self.validStickers[indexPath.item], animated: false)
        return cell
    }
}

class MDStickerCollectionViewCell: UICollectionViewCell {
    let thumbnailView = UIImageView()
    let downloadIcon = UIImageView(image: UIImage(named: "download"))
    let progressView = M13ProgressViewPie()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.thumbnailView.contentMode = .scaleAspectFit
        self.contentView.addSubview(self.thumbnailView)
        self.thumbnailView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.size.equalToSuperview()
        }
        
        self.contentView.addSubview(self.downloadIcon)
        
        self.progressView.primaryColor = .init(r: 173, g: 173, b: 173, a: 1)
        self.progressView.secondaryColor = .init(r: 126, g: 126, b: 126, a: 1)
        self.progressView.animationDuration = 0.01
        self.contentView.addSubview(self.progressView)
        
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
    
    func setThumbnailURL(thumbnailURL: URL) {
        self.thumbnailView.sd_setImage(with: thumbnailURL, completed: nil)
    }
    
    func setDownloadIconHidden(isHidden: Bool) {
        self.downloadIcon.isHidden = isHidden
    }
    
    func setProgressViewHidden(isHidden: Bool) {
        self.progressView.isHidden = isHidden
    }
    
    func setProgress(progress: CGFloat, animated: Bool) {
        self.progressView.setProgress(progress, animated: animated)
    }
}
