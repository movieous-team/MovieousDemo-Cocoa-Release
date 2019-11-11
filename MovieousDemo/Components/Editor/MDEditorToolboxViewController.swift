//
//  MDEditorToolboxViewController.swift
//  MovieousDemo
//
//  Created by Chris Wang on 2019/8/24.
//  Copyright © 2019 Movieous Team. All rights reserved.
//

import UIKit

protocol MDEditorToolboxViewControllerDelegate: NSObjectProtocol {
    func editorToolboxViewController(editorToolboxViewController: MDEditorToolboxViewController, didSelectedItemAt index: Int)
}

class MDEditorToolboxViewController: UIViewController {
    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: MDHorizontalPageFlowlayout(rowCount: 2, itemCountPerRow: 3, columnSpacing: 5, rowSpacing: 5, edgeInsets: UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)))
    let pageControl = UIPageControl()
    var tools: [[String]]!
    weak var delegate: MDEditorToolboxViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = NSLocalizedString("MDVideoEditorViewController.edit", comment: "")
        
        self.collectionView.isPagingEnabled = true
        self.collectionView.register(MDEditorToolboxCollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.showsHorizontalScrollIndicator = false
        
        let layout = self.collectionView.collectionViewLayout as! MDHorizontalPageFlowlayout
        self.pageControl.addTarget(self, action: #selector(pageControlValueChanged(sender:)), for: .valueChanged)
        self.pageControl.numberOfPages = (self.tools.count - 1) / (layout.rowCount * layout.itemCountPerRow) + 1
        self.view.addSubview(self.pageControl)
        
        self.view.addSubview(self.collectionView)
        
        self.pageControl.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview()
            make.centerX.equalToSuperview()
        }
        
        self.collectionView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(44)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalTo(self.pageControl.snp.top)
        }
    }
}

extension MDEditorToolboxViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.tools.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! MDEditorToolboxCollectionViewCell
        let tool = self.tools[indexPath.item]
        cell.setTitle(title: NSLocalizedString(tool[0], comment: ""))
        cell.setIcon(icon: UIImage(named: tool[1])!)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let delegate = self.delegate {
            delegate.editorToolboxViewController(editorToolboxViewController: self, didSelectedItemAt: indexPath.item)
        }
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        self.pageControl.currentPage = Int(targetContentOffset.pointee.x / self.collectionView.frame.size.width)
    }
    
    @objc func pageControlValueChanged(sender: UIPageControl) {
        self.collectionView.setContentOffset(CGPoint(x: self.collectionView.frame.size.width * CGFloat(sender.currentPage), y: 0), animated: true)
    }
}

class MDEditorToolboxCollectionViewCell: UICollectionViewCell {
    let titleLabel = UILabel()
    let iconView = UIImageView()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor(r: 41, g: 41, b: 41, a: 1)
        
        self.titleLabel.font = .systemFont(ofSize: 10)
        self.titleLabel.textColor = .white
        self.contentView.addSubview(titleLabel)
        self.titleLabel.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.contentView)
            make.bottom.equalTo(self.contentView).offset(-16)
        }
        
        self.iconView.contentMode = .scaleAspectFit
        self.contentView.addSubview(iconView)
        iconView.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.contentView)
            make.bottom.equalTo(titleLabel.snp.top).offset(-6)
            make.width.equalTo(25)
            make.height.equalTo(25)
        }
    }
    
    func setTitle(title: String) {
        self.titleLabel.text = title
    }
    
    func setIcon(icon: UIImage) {
        iconView.image = icon
    }
}
