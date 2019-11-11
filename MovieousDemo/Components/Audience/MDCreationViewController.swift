//
//  MDCreationViewController.swift
//  MovieousDemo
//
//  Created by Chris Wang on 2019/7/23.
//  Copyright © 2019 Movieous Team. All rights reserved.
//

import UIKit
import SVProgressHUD

class MDCreationCollectionViewCell: UICollectionViewCell {
    let iconView = UIImageView()
    let nameLabel = UILabel()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = MDColorA
        self.layer.cornerRadius = 5
        self.layer.masksToBounds = true
        
        self.iconView.contentMode = .scaleAspectFit
        self.contentView.addSubview(self.iconView)
        self.iconView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-18)
            make.width.equalTo(30)
            make.height.equalTo(30)
        }
        
        self.nameLabel.font = .boldSystemFont(ofSize: 15)
        self.contentView.addSubview(self.nameLabel)
        self.nameLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(18)
        }
    }
    
    func setIcon(icon: UIImage) {
        self.iconView.image = icon
    }
    
    func setTitle(title: String) {
        self.nameLabel.text = title
    }
}

class MDCreationViewController: UIViewController {
    var currentMetadata: MDShortVideoMetadata!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.title = NSLocalizedString("MDCreationViewController.title", comment: "")
        self.navigationItem.leftBarButtonItem = .init(image: UIImage(named: "close"), style: .plain, target: self, action: #selector(closeButtonPressed(sender:)))
        self.navigationItem.rightBarButtonItem = .init(image: UIImage(named: "settings"), style: .plain, target: self, action: #selector(settingsButtonPressed(sender:)))
        
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = .init(width: UIScreen.main.bounds.size.width / 2 - 20, height: 100)
        layout.sectionInset = .init(top: 10, left: 10, bottom: 10, right: 10)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        if #available(iOS 13.0, *) {
            collectionView.backgroundColor = .systemBackground
        } else {
            // Fallback on earlier versions
            collectionView.backgroundColor = .white
        }
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(MDCreationCollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        self.view.addSubview(collectionView)
        
        collectionView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.size.equalToSuperview()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = false
    }
    
    @objc func closeButtonPressed(sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func settingsButtonPressed(sender: UIBarButtonItem) {
        let viewController = MDShotConfigViewController()
        self.navigationController?.push(viewController, animated: true)
    }
}

extension MDCreationViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! MDCreationCollectionViewCell
        switch indexPath.item {
        case 0:
            cell.setIcon(icon: UIImage(named: "short_video_icon")!)
            cell.setTitle(title: NSLocalizedString("MDCreationViewController.single", comment: ""))
        case 1:
            cell.setIcon(icon: UIImage(named: "edit_set")!)
            cell.setTitle(title:  NSLocalizedString("MDCreationViewController.duet", comment: ""))
        default:
            break
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch indexPath.item {
        case 0:
            self.navigationController?.pushViewController(MDRecorderViewController(), animated: true)
        case 1:
            self.view.isUserInteractionEnabled = false
            SVProgressHUD.show(withStatus: NSLocalizedString("MDCreationViewController.preparing", comment: ""))
            let session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
            session.downloadTask(with: self.currentMetadata.videoURL).resume()
            session.finishTasksAndInvalidate()
        default:
            break
        }
    }
}

extension MDCreationViewController: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        self.view.isUserInteractionEnabled = true
        SVProgressHUD.dismiss()
        if let error = error {
            ShowErrorAlert(error: error, controller: self)
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        SVProgressHUD.showProgress(Float(totalBytesWritten) / Float(totalBytesExpectedToWrite), status: NSLocalizedString("MDCreationViewController.preparing", comment: ""))
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        do {
            let dirPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            try FileManager.default.createDirectory(atPath: dirPath, withIntermediateDirectories: true, attributes: nil)
            let filePath = "\(dirPath)/\(Date().timeIntervalSince1970).mp4"
            try FileManager.default.moveItem(atPath: location.path, toPath: filePath)
            let controller = MDRecorderViewController()
            controller.duetVideoPath = filePath
            self.view.isUserInteractionEnabled = true
            SVProgressHUD.dismiss {
                self.navigationController?.push(controller, animated: true)
            }
        } catch {
            self.view.isUserInteractionEnabled = true
            SVProgressHUD.dismiss {
                ShowErrorAlert(error: error, controller: self)
            }
        }
    }
}

