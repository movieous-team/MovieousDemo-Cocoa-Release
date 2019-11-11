//
//  MDAudioTrimView.swift
//  MovieousDemo
//
//  Created by Chris Wang on 2019/7/22.
//  Copyright © 2019 Movieous Team. All rights reserved.
//

import UIKit

class MDAudioTrimView: UIView {
    let leftBar = UIImageView(image: UIImage(named: "audio_bar_left"))
    let rightBar = UIImageView(image: UIImage(named: "audio_bar_right"))
    
    override func layoutSubviews() {
        super.layoutSubviews()
        for subview in self.subviews {
            subview.removeFromSuperview()
        }
        self.addSubview(self.leftBar)
        self.leftBar.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.width.equalTo(self.bounds.size.height / self.leftBar.image!.size.height * self.leftBar.image!.size.width)
        }
        
        self.addSubview(self.rightBar)
        self.rightBar.snp.makeConstraints { (make) in
            make.right.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.width.equalTo(self.bounds.size.height / self.rightBar.image!.size.height * self.rightBar.image!.size.width)
        }
    }
}
