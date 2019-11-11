//
//  FUStickerView.swift
//  MovieousDemo
//
//  Created by Chris Wang on 2019/7/2.
//  Copyright © 2019 Movieous Team. All rights reserved.
//

import UIKit

class FUCategoryCollectionViewCellA: UICollectionViewCell {
    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        self.contentView.addSubview(imageView)
        imageView.snp.makeConstraints({ (make) in
            make.center.equalToSuperview()
            make.size.equalTo(25)
        })
        return imageView
    }()
    
    func setImage(image: UIImage) {
        self.imageView.image = image
    }
}

class FUCategoryCollectionViewCellB: UICollectionViewCell {
    lazy var label: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 14)
        self.contentView.addSubview(label)
        label.snp.makeConstraints({ (make) in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalTo(self.bottomSignView.snp.bottom)
        })
        return label
    }()
    
    lazy var bottomSignView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        self.contentView.addSubview(view)
        view.snp.makeConstraints({ (make) in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
            make.width.equalTo(30)
            make.height.equalTo(2)
        })
        return view
    }()
    
    func setText(text: String) {
        self.label.text = text
    }
    
    func setTextColor(color: UIColor) {
        self.label.textColor = color
    }
    
    func setBottomSignHidden(isHidden: Bool) {
        self.bottomSignView.isHidden = isHidden
    }
}

class FUStickerCollectionViewCell: UICollectionViewCell {
    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        self.addSubview(imageView)
        imageView.snp.makeConstraints({ (make) in
            make.center.equalToSuperview()
            make.size.equalTo(41)
        })
        return imageView
    }()
    
    lazy var frameView: UIImageView = {
        let frameView = UIImageView(image: UIImage(named: "selection")!)
        self.addSubview(frameView)
        frameView.snp.makeConstraints({ (make) in
            make.center.equalToSuperview()
            make.size.equalToSuperview()
        })
        return frameView
    }()
    
    func setImage(image: UIImage) {
        self.imageView.image = image
    }
    
    func setFrameViewHidded(isHidden: Bool) {
        self.frameView.isHidden = isHidden
    }
}

class FUStickerView: UIView {
    lazy var topCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = .init(width: 80, height: 36)
        layout.scrollDirection = .horizontal
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .init(r: 0, g: 0, b: 0, a: 0.8)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(FUCategoryCollectionViewCellA.self, forCellWithReuseIdentifier: "cellA")
        collectionView.register(FUCategoryCollectionViewCellB.self, forCellWithReuseIdentifier: "cellB")
        self.addSubview(collectionView)
        return collectionView
    }()
    lazy var bottomCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = .init(width: 55, height: 55)
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        layout.sectionInset = .init(top: 5, left: 5, bottom: 5, right: 5)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .init(r: 0, g: 0, b: 0, a: 0.7)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.showsVerticalScrollIndicator = false
        collectionView.register(FUStickerCollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        self.addSubview(collectionView)
        return collectionView
    }()
    var showingCategoryIndex: Int = 0
    var selectedCategoryIndex: Int = -1
    var selectedRowIndex: Int = -1
    lazy var stickerCategories: [String] = {
        var categories: [String] = []
        for model in FUManager.share().dataSource {
            let liveModel = model as! FULiveModel
            if liveModel.enble && liveModel.items.count > 0 {
                categories.append(liveModel.title!)
            }
        }
        return categories
    }()
    lazy var models: [[String]] = {
        var models: [[String]] = []
        for model in FUManager.share().dataSource {
            let liveModel = model as! FULiveModel
            if liveModel.enble && liveModel.items.count > 0 {
                models.append(liveModel.items as! [String])
            }
        }
        return models
    }()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    func commonInit() {
        self.backgroundColor = .clear
        
        self.topCollectionView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(36)
        }
        
        self.bottomCollectionView.snp.makeConstraints { (make) in
            make.top.equalTo(self.topCollectionView.snp.bottom)
            make.bottom.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }
    }
}

extension FUStickerView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == self.topCollectionView {
            if indexPath.item == 0 {
                self.selectedCategoryIndex = -1
                self.selectedRowIndex = -1
                FUManager.share().loadItem("noitem")
                self.bottomCollectionView.reloadData()
            } else if indexPath.item - 1 != self.showingCategoryIndex {
                self.showingCategoryIndex = indexPath.item - 1
                collectionView.reloadData()
                self.bottomCollectionView.reloadData()
            }
        } else {
            self.selectedCategoryIndex = self.showingCategoryIndex
            self.selectedRowIndex = indexPath.item
            FUManager.share().loadItem(self.models[self.selectedCategoryIndex][indexPath.item])
            if let hint = FUManager.share().hint(forItem: self.models[self.selectedCategoryIndex][indexPath.item]) {
                if hint.count > 0 {
                    NotificationCenter.default.post(name: .MDShowHint, object: self, userInfo: [MDHintNotificationKey: hint])
                }
            }
            collectionView.reloadData()
        }
    }
}

extension FUStickerView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.topCollectionView {
            return self.stickerCategories.count + 1
        } else {
            return self.models[self.showingCategoryIndex].count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == self.topCollectionView {
            if indexPath.item == 0 {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellA", for: indexPath) as! FUCategoryCollectionViewCellA
                cell.setImage(image: UIImage(named: "noitem")!)
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellB", for: indexPath) as! FUCategoryCollectionViewCellB
                cell.setText(text: self.stickerCategories[indexPath.item - 1])
                if indexPath.item - 1 == self.showingCategoryIndex {
                    cell.setTextColor(color: .white)
                    cell.setBottomSignHidden(isHidden: false)
                } else {
                    cell.setTextColor(color: .lightGray)
                    cell.setBottomSignHidden(isHidden: true)
                }
                return cell
            }
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! FUStickerCollectionViewCell
            cell.setImage(image: UIImage(named: self.models[self.showingCategoryIndex][indexPath.item])!)
            if self.showingCategoryIndex == self.selectedCategoryIndex && indexPath.item == self.selectedRowIndex {
                cell.setFrameViewHidded(isHidden: false)
            } else {
                cell.setFrameViewHidded(isHidden: true)
            }
            return cell
        }
    }
}
