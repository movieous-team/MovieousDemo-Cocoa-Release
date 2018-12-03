//
//  UploaderViewController.swift
//  MovieousDemo
//
//  Created by Chris Wang on 2018/11/18.
//  Copyright © 2018 Movieous Team. All rights reserved.
//

import UIKit
import MovieousShortVideo

class UploaderViewController: UIViewController {
    @objc var draft: MSVDraft?
    var exporter: MSVVideoExporter?
    let ufileSDK = UFileSDK(publicKey: "TOKEN_218481a2-1fb0-45d4-9905-fcbd999096de", privateKey: "b253bb25-3596-4372-9c19-c97d10bce448", bucket: "twsy")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        do {
            try exporter = MSVVideoExporter(draft: draft)
        } catch {
            showErrorAlert(error: error)
            return
        }
        exporter!.saveToPhotosAlbum = true
        exporter!.progressHandler = {(progress: Float) -> Void in
            print(progress)
        }
        weak var wSelf = self
        exporter!.completionHandler = {(URL: URL) -> Void in
            if let strongSelf = wSelf {
                strongSelf.ufileSDK.multipartUpload(URL: URL, contentType:"video/mpeg4", progressHandler: { (progress: Double) in
                    print(progress)
                }, completionHandler: { (fileName: String) in
                    strongSelf.showAlert(title: "上传完成", message: fileName, actionMessage: "好的")
                }, failureHandler: { (error: Error) in
                    strongSelf.showUcloudError(error: error)
                })
            }
        }
        exporter!.failureHandler = {[weak self] (error: Error) -> Void in
            self?.showErrorAlert(error: error)
            return
        }
    }
    
    override open var prefersStatusBarHidden: Bool {
        get {
            return true
        }
    }
    
    func showUcloudError(error: Error) {
        let err  = error as NSError
        var errMsg: String? = nil;
        if err.domain == kUFileSDKAPIErrorDomain {
            errMsg = err.userInfo["ErrMsg"] as? NSString as String?;
            NSLog("%@", err.userInfo);
        } else {
            errMsg = err.description
        }
        self.showAlert(title: "错误", message: errMsg ?? "", actionMessage: "好的")
    }
    
    func showErrorAlert(error: Error) {
        self.showAlert(title: "错误", message: error.localizedDescription, actionMessage: "好的")
    }
    
    func showAlert(title: String, message: String, actionMessage: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: actionMessage, style: .default, handler: nil)
        alertController.addAction(action)
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func uploadButtonPressed(_ sender: UIButton) {
        exporter?.startExport()
    }
}
