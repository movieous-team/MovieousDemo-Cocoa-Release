//
//  MDAudienceViewController.swift
//  MovieousDemo
//
//  Created by Chris Wang on 2019/4/9.
//  Copyright © 2019 Movieous Team. All rights reserved.
//

import UIKit
import MovieousPlayer
import SnapKit
import SVProgressHUD

enum MDAudienceError: Error {
    case serverResponseError(desc: String)
    var localizedDescription: String {
        switch self {
        case .serverResponseError(let desc):
            return desc
        }
    }
}

class MDAudienceViewController: UIViewController {
    var metadataArray: [MDShortVideoMetadata] = []
    let operationLock = NSRecursiveLock()
    var currentIndex: Int = 0
    var viewAppear = false
    var currentCover: UIImageView? = nil
    var upperCover: UIImageView? = nil
    var middleCover: UIImageView? = nil
    var lowerCover: UIImageView? = nil
    var currentPlayer: MovieousPlayerController? = nil
    var upperPlayer: MovieousPlayerController? = nil
    var middlePlayer: MovieousPlayerController? = nil
    var lowerPlayer: MovieousPlayerController? = nil
    let scrollView = UIScrollView()
    let authorNameLabel = UILabel()
    let descLabel = UILabel()
    let playImageView = UIImageView(image: UIImage(named: "media_play"))
    let createButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.currentIndex = -1
        if #available(iOS 11.0, *) {
            self.scrollView.contentInsetAdjustmentBehavior = .never
        }
        self.refreshMetadatas()
        self.buildUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.isNavigationBarHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.viewAppear = true
        self.currentPlayer?.play()
        self.playImageView.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.viewAppear = false
        self.currentPlayer?.pause()
    }
    
    @objc func viewTapped(sender: UITapGestureRecognizer) {
        if let player = self.currentPlayer {
            if player.playState.rawValue >= MPPlayerState.paused.rawValue {
                player.play()
                self.playImageView.isHidden = true
            } else {
                player.pause()
                self.playImageView.isHidden = false
            }
        }
    }
    
    @objc func createButtonPressed(button: UIButton) {
        let viewController = MDCreationViewController()
        if self.currentIndex >= 0 {
            viewController.currentMetadata = self.metadataArray[self.currentIndex]
        }
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.modalPresentationStyle = .fullScreen
        if #available(iOS 13.0, *) {
            navigationController.navigationBar.tintColor = .label
        } else {
            navigationController.navigationBar.tintColor = .black
            // Fallback on earlier versions
        }
        self.present(navigationController, animated: true, completion: nil)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}

extension MDAudienceViewController {
    func refreshMetadatas() {
        self.getPlayList { (metadataArray, error) in
            if let error = error {
                ShowErrorAlert(error: error, controller: self)
                return
            }
            guard let metadataArray = metadataArray else {
                ShowAlert(title: NSLocalizedString("MDAudienceViewController.error", comment: ""), message: NSLocalizedString("MDAudienceViewController.invmeta", comment: ""), action: NSLocalizedString("MDAudienceViewController.ok", comment: ""), controller: self)
                return
            }
            guard metadataArray.count > 0 else {
                ShowAlert(title: NSLocalizedString("MDAudienceViewController.error", comment: ""), message: NSLocalizedString("MDAudienceViewController.empmeta", comment: ""), action: NSLocalizedString("MDAudienceViewController.ok", comment: ""), controller: self)
                return
            }
            DispatchQueue.main.async {
                self.metadataArray = metadataArray
                self.currentIndex = 0
                self.currentPlayer = nil
                self.currentCover = nil
                self.upperPlayer?.playerView.removeFromSuperview()
                self.upperPlayer = nil
                self.upperCover?.removeFromSuperview()
                self.upperCover = nil
                self.middlePlayer?.playerView.removeFromSuperview()
                self.middlePlayer = nil
                self.middleCover?.removeFromSuperview()
                self.middleCover = nil
                self.lowerPlayer?.playerView.removeFromSuperview()
                self.lowerPlayer = nil
                self.lowerCover?.removeFromSuperview()
                self.lowerCover = nil
                let frame = self.view.frame
                self.scrollView.contentSize = CGSize(width: 0, height: frame.size.height * CGFloat(metadataArray.count < 3 ? metadataArray.count : 3))
                
                self.upperPlayer = self.generatePlayer(URL: metadataArray[0].videoURL, frame: frame)
                self.upperCover = self.generateCover(URL: metadataArray[0].coverURL, frame: frame)
                
                self.currentCover = self.upperCover
                self.currentPlayer = self.upperPlayer
                self.authorNameLabel.text = "@\(metadataArray[0].nickname)"
                self.descLabel.text = metadataArray[0].descriptions
                if self.viewAppear {
                    self.currentPlayer?.play()
                } else {
                    self.currentPlayer?.prepareToPlay()
                }
                self.playImageView.isHidden = true
                
                if metadataArray.count == 1 {
                    return
                }
                
                self.middlePlayer = self.generatePlayer(URL: metadataArray[1].videoURL, frame: CGRect(x: 0, y: frame.size.height, width: frame.size.width, height: frame.size.height))
                self.middleCover = self.generateCover(URL: metadataArray[1].coverURL, frame: CGRect(x: 0, y: frame.size.height, width: frame.size.width, height: frame.size.height))
                
                if metadataArray.count == 2 {
                    return
                }
                
                self.lowerPlayer = self.generatePlayer(URL: metadataArray[2].videoURL, frame: CGRect(x: 0, y: 2 * frame.size.height, width: frame.size.width, height: frame.size.height))
                self.lowerCover =  self.generateCover(URL: metadataArray[2].coverURL, frame: CGRect(x: 0, y: 2 * frame.size.height, width: frame.size.width, height: frame.size.height))
            }
        }
    }
    
    func getPlayList(completionHandler: @escaping([MDShortVideoMetadata]?, Error?) -> Void) {
        let serverURL = URL(string: "\(MDServerHost)/api/demo/videos")!
        URLSession.shared.dataTask(with: serverURL) { (data: Data?, response: URLResponse?, error: Error?) in
            if let error = error {
                completionHandler(nil, error)
                return
            }
            if (response as! HTTPURLResponse).statusCode != 200 {
                completionHandler(nil, MDAudienceError.serverResponseError(desc: "\(NSLocalizedString("MDAudienceViewController.list.status.error", comment: ""))\((response as! HTTPURLResponse).statusCode)"))
                return
            }
            guard let data = data else {
                completionHandler(nil, MDAudienceError.serverResponseError(desc: NSLocalizedString("MDAudienceViewController.list.nodata.error", comment: "")))
                return
            }
            
            var metadataArray: [MDShortVideoMetadata] = []
            do {
                let obj = try JSONSerialization.jsonObject(with: data) as? Array<Dictionary<String, String>>
                guard let array = obj else {
                    throw MDAudienceError.serverResponseError(desc: NSLocalizedString("MDAudienceViewController.list.invaliddata.error", comment: ""))
                }
                for element in array {
                    guard let videoURLString = element["videoURL"] else {
                        throw MDAudienceError.serverResponseError(desc: NSLocalizedString("MDAudienceViewController.list.invaliddata.error", comment: ""))
                    }
                    guard let videoURL = URL(string: videoURLString) else {
                        throw MDAudienceError.serverResponseError(desc: NSLocalizedString("MDAudienceViewController.list.invaliddata.error", comment: ""))
                    }
                    guard let coverURLString = element["coverURL"] else {
                        throw MDAudienceError.serverResponseError(desc: NSLocalizedString("MDAudienceViewController.list.invaliddata.error", comment: ""))
                    }
                    guard let coverURL = URL(string: coverURLString) else {
                        throw MDAudienceError.serverResponseError(desc: NSLocalizedString("MDAudienceViewController.list.invaliddata.error", comment: ""))
                    }
                    guard let descriptions = element["descriptions"] else {
                        throw MDAudienceError.serverResponseError(desc: NSLocalizedString("MDAudienceViewController.list.invaliddata.error", comment: ""))
                    }
                    guard let nickname = element["nickname"] else {
                        throw MDAudienceError.serverResponseError(desc: NSLocalizedString("MDAudienceViewController.list.invaliddata.error", comment: ""))
                    }
                    let metadata = MDShortVideoMetadata(videoURL: videoURL, coverURL: coverURL, descriptions: descriptions, nickname: nickname)
                    metadataArray.append(metadata)
                }
            } catch {
                completionHandler(nil, error)
                return
            }
            completionHandler(metadataArray, nil)
            }.resume()
    }
    
    func generatePlayer(URL: URL, frame: CGRect) -> MovieousPlayerController {
        let options = MovieousPlayerOptions.default()
        options.allowMixAudioWithOthers = false
        let player = MovieousPlayerController(url: URL, options: options)
        player.scalingMode = .aspectFit
        player.delegate = self
        player.loop = true
        player.interruptInBackground = true
        player.interruptionOperation = .pause
        player.prepareToPlay()
        player.playerView.frame = frame
        self.scrollView.addSubview(player.playerView)
        return player
    }
    
    func generateCover(URL: URL, frame: CGRect) -> UIImageView {
        let cover = UIImageView()
        cover.backgroundColor = .black
        cover.contentMode = .scaleAspectFit
        cover.sd_setImage(with: URL)
        cover.frame = frame
        self.scrollView.addSubview(cover)
        return cover
    }
    
    func buildUI() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(viewTapped(sender:)))
        self.view.addGestureRecognizer(tapGestureRecognizer)
        
        self.view.backgroundColor = .black
        
        self.scrollView.delegate = self
        self.scrollView.isPagingEnabled = true
        self.scrollView.showsVerticalScrollIndicator = false
        self.scrollView.showsHorizontalScrollIndicator = false
        self.view.addSubview(self.scrollView)
        
        self.descLabel.textColor = .white
        self.descLabel.font = .systemFont(ofSize: 17)
        self.descLabel.numberOfLines = 0
        self.descLabel.shadowColor = .black
        self.descLabel.shadowOffset = .init(width: 1, height: 1)
        self.view.addSubview(self.descLabel)
        
        self.authorNameLabel.textColor = .white
        self.authorNameLabel.font = .boldSystemFont(ofSize: 17)
        self.authorNameLabel.shadowColor = .black
        self.authorNameLabel.shadowOffset = .init(width: 1, height: 1)
        self.view.addSubview(self.authorNameLabel)
        
        self.playImageView.isHidden = true
        self.view.addSubview(self.playImageView)
        
        self.createButton.setImage(UIImage(named: "create"), for: .normal)
        self.createButton.addTarget(self, action: #selector(createButtonPressed(button:)), for: .touchUpInside)
        self.view.addSubview(self.createButton)
        
        self.scrollView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }

        self.descLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.bottom.equalTo(bottomLayoutGuide.snp.top).offset(-60)
        }
        
        self.authorNameLabel.snp.makeConstraints { (make) in
            make.left.equalTo(self.descLabel)
            make.right.equalTo(self.descLabel)
            make.bottom.equalTo(self.descLabel.snp_top).offset(-10)
        }
        
        self.playImageView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.equalTo(55)
            make.height.equalTo(55)
        }
        
        self.createButton.snp.makeConstraints { (make) in
            make.width.equalTo(44)
            make.height.equalTo(44)
            make.centerX.equalToSuperview()
            make.bottom.equalTo(bottomLayoutGuide.snp.top).offset(-6)
        }
    }
}

extension MDAudienceViewController: MovieousPlayerControllerDelegate {
    func movieousPlayerControllerFirstVideoFrameRendered(_ playerController: MovieousPlayerController) {
        if playerController == self.currentPlayer {
            self.currentCover?.isHidden = true
        }
    }
    
    func movieousPlayerController(_ playerController: MovieousPlayerController, playStateDidChangeWithPreviousState previousState: MPPlayerState, newState: MPPlayerState) {
        if playerController == self.currentPlayer && previousState == .paused && newState == .playing {
            self.currentCover?.isHidden = true
        }
    }
}

extension MDAudienceViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.operationLock.lock()
        let offset = scrollView.contentOffset.y
        let frame = view.frame
        
        if self.currentPlayer == self.upperPlayer && offset >= frame.size.height {
            self.currentPlayer?.pause()
            self.currentPlayer?.currentTime = 0
            self.currentCover?.isHidden = false
            self.currentCover = self.middleCover
            self.currentPlayer = self.middlePlayer
            self.currentIndex += 1
            self.authorNameLabel.text = "@\(self.metadataArray[self.currentIndex].nickname)"
            self.descLabel.text = self.metadataArray[self.currentIndex].descriptions
            self.currentPlayer?.play()
            self.playImageView.isHidden = true
        }
        
        if self.currentPlayer == self.middlePlayer && offset <= 0 {
            self.currentPlayer?.pause()
            self.currentPlayer?.currentTime = 0
            self.currentCover?.isHidden = false
            self.currentPlayer = self.upperPlayer
            self.currentCover = self.upperCover
            self.currentIndex -= 1
            if self.currentIndex > 0 {
                self.lowerPlayer?.playerView.removeFromSuperview()
                self.lowerCover?.removeFromSuperview()
                self.lowerPlayer = self.middlePlayer
                self.lowerCover = self.middleCover
                self.lowerPlayer?.playerView.frame = CGRect(x: 0, y: 2 * frame.size.height, width: frame.size.width, height: frame.size.height)
                self.lowerCover?.frame = CGRect(x: 0, y: 2 * frame.size.height, width: frame.size.width, height: frame.size.height)
                self.middlePlayer = self.upperPlayer
                self.middleCover = self.upperCover
                self.middlePlayer?.playerView.frame = CGRect(x: 0, y: frame.size.height, width: frame.size.width, height: frame.size.height)
                self.middleCover?.frame = CGRect(x: 0, y: frame.size.height, width: frame.size.width, height: frame.size.height)
                self.upperPlayer = self.generatePlayer(URL: self.metadataArray[self.currentIndex - 1].videoURL, frame: frame)
                self.upperCover = self.generateCover(URL: self.metadataArray[self.currentIndex - 1].coverURL, frame: frame)
                self.scrollView.contentOffset = CGPoint(x: 0, y: offset + frame.size.height)
            }
            self.authorNameLabel.text = "@\(self.metadataArray[self.currentIndex].nickname)"
            self.descLabel.text = self.metadataArray[self.currentIndex].descriptions
            self.currentPlayer?.play()
            self.playImageView.isHidden = true
        }
        
        if self.currentPlayer == middlePlayer && offset >= 2 * frame.size.height {
            self.currentPlayer?.pause()
            self.currentPlayer?.currentTime = 0
            self.currentCover?.isHidden = false
            self.currentPlayer = self.lowerPlayer
            self.currentCover = self.lowerCover
            self.currentIndex += 1
            if self.currentIndex < self.metadataArray.count - 1 {
                self.upperPlayer?.playerView.removeFromSuperview()
                self.upperCover?.removeFromSuperview()
                self.upperPlayer = self.middlePlayer
                self.upperCover = self.middleCover
                self.upperPlayer?.playerView.frame = frame
                self.upperCover?.frame = frame
                self.middlePlayer = self.lowerPlayer
                self.middleCover = self.lowerCover
                self.middlePlayer?.playerView.frame = CGRect(x: 0, y: frame.size.height, width: frame.size.width, height: frame.size.height)
                self.middleCover?.frame = CGRect(x: 0, y: frame.size.height, width: frame.size.width, height: frame.size.height)
                self.lowerPlayer = self.generatePlayer(URL: self.metadataArray[self.currentIndex + 1].videoURL, frame: CGRect(x: 0, y: 2 * frame.size.height, width: frame.size.width, height: frame.size.height))
                self.lowerCover = self.generateCover(URL: self.metadataArray[self.currentIndex + 1].coverURL, frame: CGRect(x: 0, y: 2 * frame.size.height, width: frame.size.width, height: frame.size.height))
                self.scrollView.contentOffset = CGPoint(x: 0, y: offset - frame.size.height)
            }
            self.authorNameLabel.text = "@\(self.metadataArray[self.currentIndex].nickname)"
            self.descLabel.text = self.metadataArray[self.currentIndex].descriptions
            self.currentPlayer?.play()
            self.playImageView.isHidden = true
            
            if (self.currentIndex == self.metadataArray.count - 6) {
                // 获取更多数据
            }
        }
        
        if self.currentPlayer == self.lowerPlayer && offset <= frame.size.height {
            self.currentPlayer?.pause()
            self.currentPlayer?.currentTime = 0
            self.currentCover?.isHidden = false
            self.currentCover = self.middleCover
            self.currentPlayer = self.middlePlayer
            self.currentIndex -= 1
            self.authorNameLabel.text = "@\(self.metadataArray[self.currentIndex].nickname)"
            self.descLabel.text = self.metadataArray[self.currentIndex].descriptions
            self.currentPlayer?.play()
            self.playImageView.isHidden = true
        }
        self.operationLock.unlock()
    }
}

class MDShortVideoMetadata {
    let videoURL: URL
    let coverURL: URL
    let descriptions: String
    let nickname: String
    
    init(videoURL: URL, coverURL: URL, descriptions: String, nickname: String) {
        self.videoURL = videoURL
        self.coverURL = coverURL
        self.descriptions = descriptions
        self.nickname = nickname
    }
}
