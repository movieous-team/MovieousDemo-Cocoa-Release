//
//  MDExporterViewController.swift
//  MovieousDemo
//
//  Created by Chris Wang on 2019/8/23.
//  Copyright © 2019 Movieous Team. All rights reserved.
//

import UIKit
import MovieousShortVideo
import SVProgressHUD

class MDExporterViewController: UIViewController {
    let exportButton = MDButton(cornerRadius: 25)
    var image: UIImage?
    var draft: MSVDraft?
    var exporter: MSVExporter?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.view.backgroundColor = .black
        if let draft = self.draft {
            self.exporter = MSVExporter(draft: draft)
            self.exporter!.saveToPhotosAlbum = true
            self.exporter!.progressHandler = { (progress) in
                SVProgressHUD.showProgress(progress, status: NSLocalizedString("MDExporterViewController.exporting", comment: ""))
            }
            self.exporter!.completionHandler = { (url) in
                SVProgressHUD.dismiss()
                ShowAlert(title: NSLocalizedString("global.alert", comment: ""), message: NSLocalizedString("MDExporterViewController.done", comment: ""), action: NSLocalizedString("global.ok", comment: ""), controller: self)
            }
            self.exporter!.failureHandler = { (error) in
                SVProgressHUD.dismiss()
                ShowErrorAlert(error: error, controller: self)
            }
        }
        
        self.exportButton.setTitle(NSLocalizedString("MDExporterViewController.export", comment: ""), for: .normal)
        self.exportButton.addTarget(self, action: #selector(exportButtonPressed(sender:)), for: .touchUpInside)
        self.view.addSubview(self.exportButton)
        self.exportButton.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.equalTo(280)
            make.height.equalTo(50)
        }
    }
    
    @objc func exportButtonPressed(sender: UIButton) {
        if let exporter = self.exporter {
            exporter.startExport()
        } else {
            UIImageWriteToSavedPhotosAlbum(self.image!, self, #selector(image(image:didFinishSavingWithError:contextInfo:)), nil)
        }
    }
    
    @objc func image(image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeMutableRawPointer?) {
        SVProgressHUD.dismiss()
        if let error = error {
            ShowErrorAlert(error: error, controller: self)
            return
        }
        ShowAlert(title: NSLocalizedString("global.alert", comment: ""), message: NSLocalizedString("MDExporterViewController.done", comment: ""), action: NSLocalizedString("global.ok", comment: ""), controller: self)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
