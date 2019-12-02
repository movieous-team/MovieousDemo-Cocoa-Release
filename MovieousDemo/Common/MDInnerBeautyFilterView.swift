//
//  MDInnerBeautyFilterView.swift
//  MovieousDemo
//
//  Created by Chris Wang on 2019/9/8.
//  Copyright © 2019 Movieous Team. All rights reserved.
//

import UIKit
import SnapKit
import MovieousShortVideo

class MDInnerBeautyFilterView: UIView {
    var faceBeautyEffect: MovieousFaceBeautyCaptureEffect! {
        didSet {
            self.beautySlider.value = Float(self.faceBeautyEffect.beautyLevel)
            self.brightSlider.value = Float(self.faceBeautyEffect.brightLevel)
            self.toneSlider.value = Float(self.faceBeautyEffect.toneLevel)
        }
    }
    var filterEffect: MovieousLUTFilterCaptureEffect!
    lazy var filterPath = Bundle.main.path(forResource: "Filters", ofType: "bundle")!
    lazy var lutFilePaths = try! FileManager.default.contentsOfDirectory(atPath: self.filterPath)
    let segmentControl = UISegmentedControl(items: [NSLocalizedString("MDInnerBeautyFilterView.beauty", comment: ""), NSLocalizedString("MDInnerBeautyFilterView.filter", comment: "")])
    let beautyLabel = UILabel()
    let brightLabel = UILabel()
    let toneLabel = UILabel()
    let beautySlider = MDSlider()
    let brightSlider = MDSlider()
    let toneSlider = MDSlider()
    var selectedFilterIndex = 0
    lazy var flowLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = .init(width: 50, height: 80)
        layout.sectionInset = .init(top: 0, left: 10, bottom: 0, right: 10)
        return layout
    }()
    lazy var filterCollectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: self.flowLayout)
        view.backgroundColor = .clear
        view.delegate = self
        view.dataSource = self
        view.register(MDInnerFilterCollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        return view
    }()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        self.segmentControl.selectedSegmentIndex = 0
        self.segmentControl.addTarget(self, action: #selector(segmentControlValueChanged(sender:)), for: .valueChanged)
        self.addSubview(self.segmentControl)
        
        self.beautyLabel.text = NSLocalizedString("MDInnerBeautyFilterView.beauty", comment: "")
        self.beautyLabel.textColor = .white
        self.beautyLabel.font = .systemFont(ofSize: 12)
        self.addSubview(self.beautyLabel)
        
        self.beautySlider.minimumValue = 0
        self.beautySlider.maximumValue = 1
        self.beautySlider.value = 0.5
        self.beautySlider.addTarget(self, action: #selector(beautySliderValueChanged(sender:)), for: .valueChanged)
        self.addSubview(self.beautySlider)
        
        self.brightLabel.text = NSLocalizedString("MDInnerBeautyFilterView.bright", comment: "")
        self.brightLabel.textColor = .white
        self.brightLabel.font = .systemFont(ofSize: 12)
        self.addSubview(self.brightLabel)
        
        self.brightSlider.minimumValue = 0
        self.brightSlider.maximumValue = 1
        self.brightSlider.value = 0.5
        self.brightSlider.addTarget(self, action: #selector(brightSliderValueChanged(sender:)), for: .valueChanged)
        self.addSubview(self.brightSlider)
        
        self.toneLabel.text = NSLocalizedString("MDInnerBeautyFilterView.tone", comment: "")
        self.toneLabel.textColor = .white
        self.toneLabel.font = .systemFont(ofSize: 12)
        self.addSubview(self.toneLabel)
        
        self.toneSlider.minimumValue = 0
        self.toneSlider.maximumValue = 1
        self.toneSlider.value = 0.5
        self.toneSlider.addTarget(self, action: #selector(toneSliderValueChanged(sender:)), for: .valueChanged)
        self.addSubview(self.toneSlider)
        
        self.filterCollectionView.isHidden = true
        self.addSubview(self.filterCollectionView)
        
        self.segmentControl.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(5)
        }
        
        self.beautyLabel.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.snp.top).offset(self.bounds.size.height / 4)
            make.left.equalToSuperview().offset(15)
        }
        
        self.beautySlider.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.beautyLabel)
            make.left.equalTo(self.beautyLabel.snp.right).offset(15)
            make.right.equalToSuperview().offset(-15)
        }
        
        self.brightLabel.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.snp.top).offset(2 * self.bounds.size.height / 4)
            make.left.equalToSuperview().offset(15)
        }
        
        self.brightSlider.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.brightLabel)
            make.left.equalTo(self.brightLabel.snp.right).offset(15)
            make.right.equalToSuperview().offset(-15)
        }
        
        self.toneLabel.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.snp.top).offset(3 * self.bounds.size.height / 4)
            make.left.equalToSuperview().offset(15)
        }
        
        self.toneSlider.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.toneLabel)
            make.left.equalTo(self.toneLabel.snp.right).offset(15)
            make.right.equalToSuperview().offset(-15)
        }
        
        self.filterCollectionView.snp.makeConstraints { (make) in
            make.top.equalTo(self.segmentControl.snp.bottom)
            make.bottom.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
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
            make.centerY.equalTo(self.snp.top).offset(3 *
                self.bounds.size.height / 4)
        }
    }
    
    @objc func segmentControlValueChanged(sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            self.beautyLabel.isHidden = false
            self.beautySlider.isHidden = false
            self.brightLabel.isHidden = false
            self.brightSlider.isHidden = false
            self.toneLabel.isHidden = false
            self.toneSlider.isHidden = false
            self.filterCollectionView.isHidden = true
        } else {
            self.beautyLabel.isHidden = true
            self.beautySlider.isHidden = true
            self.brightLabel.isHidden = true
            self.brightSlider.isHidden = true
            self.toneLabel.isHidden = true
            self.toneSlider.isHidden = true
            self.filterCollectionView.isHidden = false
        }
    }
    
    @objc func beautySliderValueChanged(sender: MDSlider) {
        self.faceBeautyEffect.beautyLevel = CGFloat(sender.value)
    }
    
    @objc func brightSliderValueChanged(sender: MDSlider) {
        self.faceBeautyEffect.brightLevel = CGFloat(sender.value)
    }
    
    @objc func toneSliderValueChanged(sender: MDSlider) {
        self.faceBeautyEffect.toneLevel = CGFloat(sender.value)
    }
}

extension MDInnerBeautyFilterView: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.lutFilePaths.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! MDInnerFilterCollectionViewCell
        if indexPath.item == 0 {
            cell.image = UIImage(named: "noitem")
            cell.title = "none"
        } else {
            cell.image = UIImage(named: "filter_template.jpg")
            cell.title = self.lutFilePaths[indexPath.item - 1]
        }
        if indexPath.item == self.selectedFilterIndex {
            cell.image = UIImage(named: "done")
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.selectedFilterIndex = indexPath.item
        collectionView.reloadData()
        if indexPath.item == 0 {
            self.filterEffect.image = nil
        } else {
            self.filterEffect.image = UIImage(contentsOfFile: "\(self.filterPath)/\(self.lutFilePaths[indexPath.item - 1])")
        }
    }
}

class MDInnerFilterCollectionViewCell: UICollectionViewCell {
    var imageView = UIImageView()
    var label = UILabel()
    var image: UIImage! {
        didSet {
            self.imageView.image = self.image
        }
    }
    var title: String! {
        didSet {
            self.label.text = self.title
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(self.imageView)
        self.addSubview(self.label)
        
        self.imageView.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(self.imageView.snp.width)
            make.top.equalToSuperview()
        }
        
        self.label.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.top.equalTo(self.imageView.snp.bottom)
            make.bottom.equalToSuperview()
        }
    }
}
