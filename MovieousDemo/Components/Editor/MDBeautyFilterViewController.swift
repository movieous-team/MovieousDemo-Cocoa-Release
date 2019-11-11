//
//  MDBeautyFilterViewController.swift
//  MovieousDemo
//
//  Created by Chris Wang on 2019/7/10.
//  Copyright © 2019 Movieous Team. All rights reserved.
//

import UIKit

protocol MDBeautyFilterViewControllerDelegate: NSObjectProtocol {
    func beautyFilterViewController(beautyParamDidChange beautyFilterViewController: MDBeautyFilterViewController)
}

class MDBeautyFilterViewController: UIViewController {
    weak var delegate: MDBeautyFilterViewControllerDelegate?
    lazy var beautifyView: UIView = {
        var view: UIView!
        switch vendorType {
        case .faceunity:
            view = FUAPIDemoBar()
            (view as! FUAPIDemoBar).delegate = self
        case .sensetime:
            view = MDSTBeautyFilterView()
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
        if vendorType == .faceunity {
            self.demoBarSetBeautyDefultParams()
        }
    }
    
    func demoBarSetBeautyDefultParams() {
        let view = self.beautifyView as! FUAPIDemoBar
       view.delegate = nil ;
       view.skinDetect = FUManager.share().skinDetectEnable;
       view.blurType = FUManager.share().blurType ;
       view.blurLevel_0 = FUManager.share().blurLevel_0;
       view.blurLevel_1 = FUManager.share().blurLevel_1;
       view.blurLevel_2 = FUManager.share().blurLevel_2;
       view.colorLevel = FUManager.share().whiteLevel ;
       view.redLevel = FUManager.share().redLevel;
       view.eyeBrightLevel = FUManager.share().eyelightingLevel ;
       view.toothWhitenLevel = FUManager.share().beautyToothLevel ;
       
       view.vLevel =  FUManager.share().vLevel;
       view.eggLevel = FUManager.share().eggLevel;
       view.narrowLevel = FUManager.share().narrowLevel;
       view.smallLevel = FUManager.share().smallLevel;
        //    view.faceShape = FUManager.share().faceShape ;
        view.enlargingLevel = FUManager.share().enlargingLevel ;
        view.thinningLevel = FUManager.share().thinningLevel ;
        //    view.enlargingLevel_new = FUManager.share().enlargingLevel_new ;
        //    view.thinningLevel_new = FUManager.share().thinningLevel_new ;
        view.chinLevel = FUManager.share().jewLevel ;
        view.foreheadLevel = FUManager.share().foreheadLevel ;
        view.noseLevel = FUManager.share().noseLevel ;
        view.mouthLevel = FUManager.share().mouthLevel ;
        
        view.filtersDataSource = FUManager.share().filtersDataSource ;
        view.beautyFiltersDataSource = FUManager.share().beautyFiltersDataSource ;
        view.filtersCHName = FUManager.share().filtersCHName ;
        view.selectedFilter = FUManager.share().selectedFilter ;
        view.selectedFilterLevel = FUManager.share().selectedFilterLevel;
        view.delegate = self;
        view.demoBar.makeupView.delegate = self;
        view.demoBar.selMakeupIndex = view.demoBar.makeupView.supIndex;
    }
}

extension MDBeautyFilterViewController: FUAPIDemoBarDelegate {
    func demoBarBeautyParamChanged() {
        let view = self.beautifyView as! FUAPIDemoBar
        FUManager.share().skinDetectEnable = view.skinDetect;
        FUManager.share().blurType = view.blurType;
        FUManager.share().blurLevel_0 = view.blurLevel_0;
        FUManager.share().blurLevel_1 = view.blurLevel_1;
        FUManager.share().blurLevel_2 = view.blurLevel_2;
        FUManager.share().whiteLevel = view.colorLevel;
        FUManager.share().redLevel = view.redLevel;
        FUManager.share().eyelightingLevel = view.eyeBrightLevel;
        FUManager.share().beautyToothLevel = view.toothWhitenLevel;
        FUManager.share().vLevel = view.vLevel;
        FUManager.share().eggLevel = view.eggLevel;
        FUManager.share().narrowLevel = view.narrowLevel;
        FUManager.share().smallLevel = view.smallLevel;
        FUManager.share().enlargingLevel = view.enlargingLevel;
        FUManager.share().thinningLevel = view.thinningLevel;
        //    FUManager.share().enlargingLevel_new = view.enlargingLevel_new;
        //    FUManager.share().thinningLevel_new = view.thinningLevel_new;
        
        FUManager.share().jewLevel = view.chinLevel;
        FUManager.share().foreheadLevel = view.foreheadLevel;
        FUManager.share().noseLevel = view.noseLevel;
        FUManager.share().mouthLevel = view.mouthLevel;
        
        /* 暂时解决展示表中，没有显示滤镜，引起bug */
        if (!FUManager.share().beautyFiltersDataSource.contains(view.selectedFilter)) {
            return;
        }
        FUManager.share().selectedFilter = view.selectedFilter ;
        FUManager.share().selectedFilterLevel = view.selectedFilterLevel;
        if let delegate = self.delegate {
            delegate.beautyFilterViewController(beautyParamDidChange: self)
        }
    }
}

extension MDBeautyFilterViewController: FUMakeUpViewDelegate {
    func makeupViewDidSelectedNamaStr(_ namaStr: String?, valueArr: [Any]?) {
        FUManager.share()?.setMakeupItemStr(namaStr, valueArr: valueArr)
    }
    
    func makeupViewDidSelectedNamaStr(_ namaStr: String?, imageName: String?) {
        guard let imageName = imageName else { return }
        FUManager.share()?.setMakeupItemParamImage(UIImage(named: imageName), param: namaStr)
    }
    
    func makeupViewDidChangeValue(_ value: Float, namaValueStr namaStr: String?) {
        FUManager.share()?.setMakeupItemIntensity(value, param: namaStr)
    }
    
    func makeupFilter(_ filterStr: String?, value filterValue: Float) {
        guard let filterStr = filterStr else { return }
        if filterStr == "" {
            return
        }
        let view = self.beautifyView as! FUAPIDemoBar
        view.selectedFilter = filterStr
        view.selectedFilterLevel = Double(filterValue)
        FUManager.share().selectedFilter = filterStr
        FUManager.share()?.selectedFilterLevel = Double(filterValue)
    }
}
