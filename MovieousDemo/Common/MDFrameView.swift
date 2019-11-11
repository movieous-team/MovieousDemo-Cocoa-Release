//
//  MDFrameView.swift
//  MovieousDemo
//
//  Created by Chris Wang on 2019/7/7.
//  Copyright © 2019 Movieous Team. All rights reserved.
//

import UIKit

class MDFrameView: UIView {
    var frameColor: UIColor = .white {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    var margin: CGFloat = 0 {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    var frameWidth: CGFloat = 1 {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        let ctx = UIGraphicsGetCurrentContext()
        self.frameColor.setStroke()
        ctx?.setLineWidth(self.frameWidth)
        let halfFrameWidth = self.frameWidth / 2
        let path = UIBezierPath()
        path.move(to: .init(x: self.margin, y: self.margin + halfFrameWidth))
        path.addLine(to: .init(x: rect.size.width - self.margin, y: self.margin + halfFrameWidth))
        path.move(to: .init(x: rect.size.width - self.margin - halfFrameWidth, y: self.margin + halfFrameWidth))
        path.addLine(to: .init(x: rect.size.width - self.margin - halfFrameWidth, y: rect.size.height - self.margin))
        path.move(to: .init(x: rect.size.width - self.margin - halfFrameWidth, y: rect.size.height - self.margin - halfFrameWidth))
        path.addLine(to: .init(x:self.margin, y: rect.size.height - self.margin - halfFrameWidth))
        path.move(to: .init(x: self.margin + halfFrameWidth, y: rect.size.height - self.margin - halfFrameWidth))
        path.addLine(to: .init(x: self.margin + halfFrameWidth, y: self.margin))
        ctx?.addPath(path.cgPath)
        ctx?.setBlendMode(.copy)
        ctx?.strokePath()
    }
}
