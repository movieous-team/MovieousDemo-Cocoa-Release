//
//  MDInnerBeautyView.swift
//  MovieousDemo
//
//  Created by Chris Wang on 2019/9/8.
//  Copyright © 2019 Movieous Team. All rights reserved.
//

import UIKit
import SnapKit
import MovieousShortVideo

class MDInnerBeautyView: UIView {
    var faceBeautyCaptureEffect: MovieousFaceBeautyCaptureEffect! {
        didSet {
            self.beautySlider.value = Float(self.faceBeautyCaptureEffect.beautyLevel)
            self.brightSlider.value = Float(self.faceBeautyCaptureEffect.brightLevel)
            self.toneSlider.value = Float(self.faceBeautyCaptureEffect.toneLevel)
        }
    }
    let beautyLabel = UILabel()
    let brightLabel = UILabel()
    let toneLabel = UILabel()
    let beautySlider = MDSlider()
    let brightSlider = MDSlider()
    let toneSlider = MDSlider()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        self.beautyLabel.text = NSLocalizedString("MDInnerBeautyView.beauty", comment: "")
        self.beautyLabel.textColor = .white
        self.beautyLabel.font = .systemFont(ofSize: 12)
        self.addSubview(self.beautyLabel)
        
        self.beautySlider.minimumValue = 0
        self.beautySlider.maximumValue = 1
        self.beautySlider.value = 0.5
        self.beautySlider.addTarget(self, action: #selector(beautySliderValueChanged(sender:)), for: .valueChanged)
        self.addSubview(self.beautySlider)
        
        self.brightLabel.text = NSLocalizedString("MDInnerBeautyView.bright", comment: "")
        self.brightLabel.textColor = .white
        self.brightLabel.font = .systemFont(ofSize: 12)
        self.addSubview(self.brightLabel)
        
        self.brightSlider.minimumValue = 0
        self.brightSlider.maximumValue = 1
        self.brightSlider.value = 0.5
        self.brightSlider.addTarget(self, action: #selector(brightSliderValueChanged(sender:)), for: .valueChanged)
        self.addSubview(self.brightSlider)
        
        self.toneLabel.text = NSLocalizedString("MDInnerBeautyView.tone", comment: "")
        self.toneLabel.textColor = .white
        self.toneLabel.font = .systemFont(ofSize: 12)
        self.addSubview(self.toneLabel)
        
        self.toneSlider.minimumValue = 0
        self.toneSlider.maximumValue = 1
        self.toneSlider.value = 0.5
        self.toneSlider.addTarget(self, action: #selector(toneSliderValueChanged(sender:)), for: .valueChanged)
        self.addSubview(self.toneSlider)
        
        self.beautyLabel.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.snp.top).offset(frame.size.height / 4)
            make.left.equalToSuperview().offset(15)
        }
        
        self.beautySlider.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.beautyLabel)
            make.left.equalTo(self.beautyLabel.snp.right).offset(15)
            make.right.equalToSuperview().offset(-15)
        }
        
        self.brightLabel.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.snp.top).offset(2 * frame.size.height / 4)
            make.left.equalToSuperview().offset(15)
        }
        
        self.brightSlider.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.brightLabel)
            make.left.equalTo(self.brightLabel.snp.right).offset(15)
            make.right.equalToSuperview().offset(-15)
        }
        
        self.toneLabel.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.snp.top).offset(3 * frame.size.height / 4)
            make.left.equalToSuperview().offset(15)
        }
        
        self.toneSlider.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.toneLabel)
            make.left.equalTo(self.toneLabel.snp.right).offset(15)
            make.right.equalToSuperview().offset(-15)
        }
    }
    
    override func layoutSubviews() {
        self.beautyLabel.snp.updateConstraints { (make) in
            make.centerY.equalTo(self.snp.top).offset(self.bounds.size.height / 4)
        }
        
        self.brightLabel.snp.updateConstraints { (make) in
            make.centerY.equalTo(self.snp.top).offset(2 * self.bounds.size.height / 4)
        }
        
        self.toneLabel.snp.updateConstraints { (make) in
            make.centerY.equalTo(self.snp.top).offset(3 * self.bounds.size.height / 4)
        }
    }
    
    @objc func beautySliderValueChanged(sender: MDSlider) {
        self.faceBeautyCaptureEffect.beautyLevel = CGFloat(sender.value)
    }
    
    @objc func brightSliderValueChanged(sender: MDSlider) {
        self.faceBeautyCaptureEffect.brightLevel = CGFloat(sender.value)
    }
    
    @objc func toneSliderValueChanged(sender: MDSlider) {
        self.faceBeautyCaptureEffect.toneLevel = CGFloat(sender.value)
    }
}
