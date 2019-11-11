//
//  MDProgressBar.swift
//  MovieousDemo
//
//  Created by Chris Wang on 2019/6/20.
//  Copyright © 2019 Movieous Team. All rights reserved.
//

import UIKit
import SnapKit

enum MDProgressBarProgressStyle {
    case normal
    case delete
}

class MDProgressBar: UIView {
    var progressSegments: [UIView] = []
    var lastProgressStyle: MDProgressBarProgressStyle = .normal {
        didSet {
            DispatchQueue.main.async {
                if self.lastProgressStyle == .normal {
                    self.progressSegments.last?.backgroundColor =  .init(r: 229, g: 61, b: 146, a: 1)
                } else {
                    self.progressSegments.last?.backgroundColor = .red
                }
            }
        }
    }
    var currentSegment: UIView?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.buildUI()
    }
    
    init() {
        super.init(frame: .zero)
        self.buildUI()
    }
    
    func buildUI() {
        DispatchQueue.main.async {
            self.backgroundColor = UIColor(r: 43, g: 42, b: 55, a: 1)
        }
    }
    
    func beginSegment() {
        self.cancelSegment()
        self.lastProgressStyle = .normal
        DispatchQueue.main.async {
            let lastProgressSegment = self.progressSegments.last
            self.currentSegment = UIView()
            self.currentSegment?.backgroundColor = .init(r: 229, g: 61, b: 146, a: 1)
            self.addSubview(self.currentSegment!)
            self.currentSegment?.snp.makeConstraints { (make) in
                if let lastProgressView = lastProgressSegment {
                    make.left.equalTo(lastProgressView.snp_right)
                } else {
                    make.left.equalToSuperview()
                }
                make.top.equalToSuperview()
                make.bottom.equalToSuperview()
                make.width.equalTo(0)
            }
        }
    }
    
    func finishSegment() {
        DispatchQueue.main.async {
            guard let segment = self.currentSegment else {
                return
            }
            self.currentSegment = nil
            self.progressSegments.append(segment)
            if segment.frame.origin.x + segment.frame.size.width < self.frame.size.width {
                let segmentGap = UIView()
                segmentGap.backgroundColor = .white
                segment.addSubview(segmentGap)
                segmentGap.snp.remakeConstraints { (make) in
                    make.right.equalToSuperview()
                    make.centerY.equalToSuperview()
                    make.width.equalTo(2)
                    make.height.equalToSuperview()
                }
            }
        }
    }
    
    func cancelSegment() {
        DispatchQueue.main.async {
            guard let segment = self.currentSegment else {
                return
            }
            self.currentSegment = nil
            segment.removeFromSuperview()
        }
    }
    
    func updateProgress(progress: Float) {
        DispatchQueue.main.async {
            guard let segment = self.currentSegment else {
                return
            }
            segment.snp.updateConstraints { (make) in
                make.width.equalTo(Float(self.frame.size.width) * progress)
            }
        }
    }
    
    func deleteLastProgress() {
        self.lastProgressStyle = .normal
        DispatchQueue.main.async {
            if let lastProgressView = self.progressSegments.last {
                lastProgressView.removeFromSuperview()
                self.progressSegments.removeLast()
            }
        }
    }
    
    func deleteAllProgresses() {
        DispatchQueue.main.async {
            while self.progressSegments.count != 0 {
                self.progressSegments.last!.removeFromSuperview()
                self.progressSegments.removeLast()
            }
        }
    }
}
