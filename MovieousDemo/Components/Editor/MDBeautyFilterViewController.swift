//
//  MDBeautyFilterViewController.swift
//  MovieousDemo
//
//  Created by Chris Wang on 2019/7/10.
//  Copyright © 2019 Movieous Team. All rights reserved.
//

import UIKit
import MovieousShortVideo

protocol MDBeautyFilterViewControllerDelegate: NSObjectProtocol {
    func beautyFilterViewController(beautyParamDidChange beautyFilterViewController: MDBeautyFilterViewController)
}

class MDBeautyFilterViewController: UIViewController {
    var faceBeautyEditorEffect: MSVFaceBeautyEditorEffect?
    var filterEditorEffect: MSVLUTFilterEditorEffect?
    weak var delegate: MDBeautyFilterViewControllerDelegate?
    lazy var beautifyView: UIView = {
        var view: UIView!
        switch vendorType {
        case .none:
            view = MDInnerBeautyFilterView()
            (view as! MDInnerBeautyFilterView).faceBeautyEffect = self.faceBeautyEditorEffect
            (view as! MDInnerBeautyFilterView).filterEffect = self.filterEditorEffect
        default:
            view = UIView()
        }
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.view.backgroundColor = .black
        self.title = NSLocalizedString("MDBeautyFilterViewController.title", comment: "")
        self.view.addSubview(self.beautifyView)
        self.beautifyView.snp.makeConstraints({ (make) in
            make.top.equalTo(topLayoutGuide.snp.bottom)
            make.bottom.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        })
    }
}
