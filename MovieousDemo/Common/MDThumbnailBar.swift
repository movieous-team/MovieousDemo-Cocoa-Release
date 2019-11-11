//
//  MDThumbnailBar.swift
//  MovieousDemo
//
//  Created by Chris Wang on 2019/7/24.
//  Copyright © 2019 Movieous Team. All rights reserved.
//

import UIKit
import MovieousShortVideo

class MDThumbnail {
    let requestedTime: TimeInterval
    let image: UIImage
    let actualTime: TimeInterval
    
    init(requestedTime: TimeInterval, image: UIImage, actualTime: TimeInterval) {
        self.requestedTime = requestedTime
        self.image = image
        self.actualTime = actualTime
    }
}

class MDThumbnailsCache: NSObject {
    public static let thumbnailCacheRefreshedNotification: NSNotification.Name = NSNotification.Name(rawValue: "thumbnailCacheRefreshed")
    public static let thumbnailCacheRefreshedThumbnailKey = "thumbnailCacheRefreshedThumbnailKey"
    static let thumbnailFrameRate = TimeInterval(24)

    var draft: MSVDraft?
    var clip: MSVClip?
    let duration: TimeInterval
    var thumbnails: [MDThumbnail] = []
    var refreshing = false
    var maximumSize: CGSize
    
    init(draft: MSVDraft) {
        self.draft = draft
        self.duration = draft.duration
        self.maximumSize = draft.videoSize
        super.init()
    }
    
    init(clip: MSVClip) {
        self.clip = clip
        self.duration = clip.originalDuration
        self.maximumSize = clip.size
        super.init()
    }
    
    func refreshThumbnails() {
        if self.refreshing {
            return
        }
        self.refreshing = true
        self.thumbnails.removeAll()
        NotificationCenter.default.post(name: MDThumbnailsCache.thumbnailCacheRefreshedNotification, object: self, userInfo: [MDThumbnailsCache.thumbnailCacheRefreshedThumbnailKey: self.thumbnails])
        var generator: MSVSnapshotGenerator!
        if let draft = self.draft {
            generator = draft.imageGenerator
        } else {
            generator = self.clip!.imageGenerator
        }
        generator.maximumSize = self.maximumSize
        var requestTimes: [NSNumber] = []
        let interval = 1.0 / MDThumbnailsCache.thumbnailFrameRate
        var timePointer = TimeInterval(0)
        while timePointer <= self.duration {
            requestTimes.append(.init(value: timePointer))
            timePointer += interval
        }
        var callbackCount = 0
        generator.generateSnapshotsAsynchronously(forTimes: requestTimes) { (requestedTime, image, actualTime, result, error) in
            callbackCount += 1
            if callbackCount == requestTimes.count {
                self.refreshing = false
            }
            if result == .succeeded {
                self.thumbnails.append(.init(requestedTime: requestedTime, image: image!, actualTime: actualTime))
                NotificationCenter.default.post(name: MDThumbnailsCache.thumbnailCacheRefreshedNotification, object: self, userInfo: [MDThumbnailsCache.thumbnailCacheRefreshedThumbnailKey: self.thumbnails])
            } else if result == .failed {
                print("generate snapshot failed for : \(String(describing: error))")
            }
        }
    }
}

class MDThumbnailBar: UIView {
    let thumbnailCache: MDThumbnailsCache
    var timeRange: MovieousTimeRange {
        didSet {
            DispatchQueue.main.async {
                self.setNeedsLayout()
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        fatalError("init(frame:) has not been implemented")
    }
    
    init(thumbnailCache: MDThumbnailsCache, timeRange: MovieousTimeRange = kMovieousTimeRangeDefault) {
        self.thumbnailCache = thumbnailCache
        self.timeRange = timeRange
        super.init(frame: .zero)
        self.clipsToBounds = true
        NotificationCenter.default.addObserver(self, selector: #selector(thumbnailCacheRefreshed(_:)), name: MDThumbnailsCache.thumbnailCacheRefreshedNotification, object: thumbnailCache)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        for subview in self.subviews {
            subview.removeFromSuperview()
        }
        let originalThumbnails = self.thumbnailCache.thumbnails
        let width = self.frame.size.height
        let snapshotCount = Int(ceil(self.frame.size.width / width))
        var interval: TimeInterval!
        var startTime: TimeInterval!
        if MovieousTimeRangeIsDefault(self.timeRange) {
            startTime = 0
            interval = self.thumbnailCache.duration * TimeInterval(width / self.frame.size.width)
        } else {
            startTime = self.timeRange.startTime
            interval = self.timeRange.duration * TimeInterval(width / self.frame.size.width)
        }
        var position = self.snp.left
        for i in 0 ..< snapshotCount {
            let pendingTimestamp = startTime + interval * Double(i)
            var thumbnailToUse: MDThumbnail?
            for thumbnail in originalThumbnails {
                if thumbnail.requestedTime >= pendingTimestamp && thumbnail.requestedTime <= pendingTimestamp + interval {
                    thumbnailToUse = thumbnail
                    break
                }
            }
            if let thumbnailToUse = thumbnailToUse {
                let thumbnailView = UIImageView(image: thumbnailToUse.image)
                thumbnailView.contentMode = .scaleAspectFill
                thumbnailView.clipsToBounds = true
                self.addSubview(thumbnailView)
                thumbnailView.snp.makeConstraints { (make) in
                    make.left.equalTo(position)
                    make.top.equalToSuperview()
                    make.bottom.equalToSuperview()
                    make.width.equalTo(width)
                }
                position = thumbnailView.snp.right
            } else {
                let thumbnailView = UIView()
                thumbnailView.clipsToBounds = true
                self.addSubview(thumbnailView)
                thumbnailView.snp.makeConstraints { (make) in
                    make.left.equalTo(position)
                    make.top.equalToSuperview()
                    make.bottom.equalToSuperview()
                    make.width.equalTo(width)
                }
                position = thumbnailView.snp.right
            }
        }
    }
    
    @objc func thumbnailCacheRefreshed(_ notification: Notification) {
        DispatchQueue.main.async {
            self.setNeedsLayout()
        }
    }
}
