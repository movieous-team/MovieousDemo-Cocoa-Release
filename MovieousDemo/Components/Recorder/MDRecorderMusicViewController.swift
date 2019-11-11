//
//  MDRecorderMusicViewController.swift
//  MovieousDemo
//
//  Created by Chris Wang on 2019/4/10.
//  Copyright © 2019 Movieous Team. All rights reserved.
//

import UIKit
import SDWebImage
import M13ProgressSuite
import SVProgressHUD
import MovieousShortVideo

protocol MDRecorderMusicViewControllerDelegate: NSObject {
    func controller(_ controller: MDRecorderMusicViewController, didSelect music: MDMusic)
}

class MDRecorderMusicTableViewCell: UITableViewCell {
    enum State {
        case normal
        case playing
        case loading
    }
    let coverImageView = UIImageView()
    let nameLabel = UILabel()
    let authorLabel = UILabel()
    let playIcon = UIImageView(image: UIImage(named: "play_white")!)
    let pauseIcon = UIImageView(image: UIImage(named: "pause_white")!)
    let progressView = M13ProgressViewRing()
    var state = State.normal {
        didSet {
            switch self.state {
            case .normal:
                self.playIcon.isHidden = false
                self.pauseIcon.isHidden = true
                self.progressView.isHidden = true
            case .playing:
                self.playIcon.isHidden = true
                self.pauseIcon.isHidden = false
                self.progressView.isHidden = true
            case .loading:
                self.playIcon.isHidden = true
                self.pauseIcon.isHidden = true
                self.progressView.isHidden = false
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.contentView.addSubview(self.coverImageView)
        
        self.nameLabel.font = .boldSystemFont(ofSize: 18)
        if #available(iOS 13.0, *) {
            self.nameLabel.textColor = .label
        } else {
            // Fallback on earlier versions
            self.nameLabel.textColor = .black
        }
        self.contentView.addSubview(self.nameLabel)
        
        self.authorLabel.font = .systemFont(ofSize: 13)
        self.authorLabel.textColor = .init(r: 150, g: 150, b: 150, a: 1)
        self.contentView.addSubview(self.authorLabel)
        
        self.coverImageView.addSubview(self.playIcon)
        self.coverImageView.addSubview(self.pauseIcon)
        self.progressView.secondaryColor = .white
        self.progressView.showPercentage = false
        self.progressView.indeterminate = true
        self.coverImageView.addSubview(self.progressView)
        
        self.coverImageView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(20)
            make.top.equalToSuperview().offset(5)
            make.bottom.equalToSuperview().offset(-5)
            make.width.equalTo(self.coverImageView.snp.height)
        }
        
        self.nameLabel.snp.makeConstraints { (make) in
            make.left.equalTo(self.coverImageView.snp.right).offset(10)
            make.bottom.equalTo(self.contentView.snp.centerY).offset(-2)
        }
        
        self.authorLabel.snp.makeConstraints { (make) in
            make.left.equalTo(self.nameLabel.snp.left)
            make.top.equalTo(self.contentView.snp.centerY).offset(2)
        }
        
        self.playIcon.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.size.equalTo(20)
        }
        
        self.pauseIcon.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.size.equalTo(20)
        }
        
        self.progressView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.size.equalTo(20)
        }
    }
    
    func update(with music: MDMusic) {
        self.coverImageView.sd_setImage(with: music.coverURL, completed: nil)
        self.nameLabel.text = music.name
        self.authorLabel.text = music.author
        self.playIcon.isHidden = false
        self.pauseIcon.isHidden = true
        self.progressView.isHidden = true
    }
}

class MDRecorderMusicViewController: UIViewController {
    weak var delegate: MDRecorderMusicViewControllerDelegate?
    let tableView = UITableView(frame: .zero, style: .plain)
    let navigationBar = UINavigationBar()
    let musicPlayer = AVPlayer()
    var currentPlayingIndexPath: IndexPath?
    var isPlayerLoading = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        // Do any additional setup after loading the view.
        let item = UINavigationItem(title: NSLocalizedString("MDRecorderMusicViewController.musics", comment: ""))
        item.leftBarButtonItem = .init(image: UIImage(named: "close"), style: .plain, target: self, action: #selector(closeButtonPressed(sender:)))
        item.rightBarButtonItem = .init(title: NSLocalizedString("MDRecorderMusicViewController.save", comment: ""), style: .done, target: self, action: #selector(saveButtonPressed(sender:)))
        if #available(iOS 13.0, *) {
            item.leftBarButtonItem?.tintColor = .label
            item.rightBarButtonItem?.tintColor = .label
        } else {
            // Fallback on earlier versions
            item.leftBarButtonItem?.tintColor = .black
            item.rightBarButtonItem?.tintColor = .black
        }
        
        self.navigationBar.pushItem(item, animated: false)
        self.navigationBar.delegate = self
        self.view.addSubview(self.navigationBar)
        self.navigationBar.snp.makeConstraints { (make) in
            make.top.equalTo(topLayoutGuide.snp.bottom)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.register(MDRecorderMusicTableViewCell.self, forCellReuseIdentifier: "cell")
        self.view.addSubview(self.tableView)
        self.tableView.snp.makeConstraints { (make) in
            make.top.equalTo(self.navigationBar.snp.bottom)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(musicLibraryRefreshDone(sender:)), name: .MDMusicLibraryRefreshDone, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(musicLibraryRefreshError(sender:)), name: .MDMusicLibraryRefreshError, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(musicDidUpdated(sender:)), name: .MDMusicDidUpdated, object: nil)
        MDMusicLibrary.refreshMusics()
    }
    
    @objc func musicLibraryRefreshDone(sender: Notification) {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    @objc func musicLibraryRefreshError(sender: Notification) {
        ShowErrorAlert(error: sender.userInfo![MDMusicLibraryRefreshErrorKey]! as! Error, controller: self)
    }
    
    @objc func musicDidUpdated(sender: Notification) {
        let music = sender.userInfo![MDMusicDidUpdatedKey]! as! MDMusic
        if music.localPath != nil {
            if let delegate = self.delegate {
                delegate.controller(self, didSelect: music)
            }
            SVProgressHUD.dismiss {
                self.dismiss()
            }
        } else {
            SVProgressHUD.showProgress(Float(music.progress), status: NSLocalizedString("MDRecorderMusicViewController.downloading", comment: ""))
        }
    }
    
    @objc func closeButtonPressed(sender: UIButton) {
        self.dismiss()
    }
    
    @objc func saveButtonPressed(sender: UIButton) {
        self.view.isUserInteractionEnabled = false
        guard let currentPlayingIndexPath = self.currentPlayingIndexPath else {
            self.dismiss()
            return
        }
        let music = MDMusicLibrary.musics[currentPlayingIndexPath.item]
        SVProgressHUD.show(withStatus: NSLocalizedString("MDRecorderMusicViewController.downloading", comment: ""))
        music.download()
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .fade
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    func dismiss() {
        self.removeObservers()
        self.musicPlayer.pause()
        self.dismiss(animated: true, completion: nil)
    }
}

extension MDRecorderMusicViewController: UINavigationBarDelegate {
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}

extension MDRecorderMusicViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.currentPlayingIndexPath == indexPath {
            let cell = tableView.cellForRow(at: indexPath)! as! MDRecorderMusicTableViewCell
            if cell.state == .loading {
                return
            }
            if self.musicPlayer.rate == 0 {
                self.musicPlayer.play()
                cell.state = .playing
            } else {
                self.musicPlayer.pause()
                cell.state = .normal
            }
        } else {
            let music = MDMusicLibrary.musics[indexPath.item]
            if let currentPlayingIndexPath = self.currentPlayingIndexPath {
                self.removeObservers()
                if let cell = self.tableView.cellForRow(at: currentPlayingIndexPath) as! MDRecorderMusicTableViewCell? {
                    cell.state = .normal
                }
            }
            if let localPath = music.localPath {
                self.musicPlayer.replaceCurrentItem(with: .init(url: .init(fileURLWithPath: localPath)))
            } else {
                self.musicPlayer.replaceCurrentItem(with: .init(url: music.sourceURL))
            }
            self.musicPlayer.play()
            self.addObservers()
            self.currentPlayingIndexPath = indexPath
            let cell = tableView.cellForRow(at: indexPath)! as! MDRecorderMusicTableViewCell
            cell.state = .loading
            self.isPlayerLoading = true
        }
    }
    
    func addObservers() {
        guard let item = self.musicPlayer.currentItem else { return }
        item.addObserver(self, forKeyPath: "status", options: .new, context: nil)
    }
    
    func removeObservers() {
        guard let item = self.musicPlayer.currentItem else { return }
        item.removeObserver(self, forKeyPath: "status")
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
}

extension MDRecorderMusicViewController {
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        DispatchQueue.main.async {
            guard let keyPath = keyPath else { return }
            guard let change = change else { return }
            switch keyPath {
            case "status":
                let status = change[.newKey] as! NSNumber
                if status.intValue == AVPlayerItem.Status.readyToPlay.rawValue {
                    self.isPlayerLoading = false
                    guard let indexPath = self.currentPlayingIndexPath else { return }
                    guard let cell = self.tableView.cellForRow(at: indexPath) as! MDRecorderMusicTableViewCell? else { return }
                    cell.state = .playing
                }
                return
            default:
                return
            }
        }
    }
}

extension MDRecorderMusicViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return MDMusicLibrary.musics.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")! as! MDRecorderMusicTableViewCell
        let music = MDMusicLibrary.musics[indexPath.item]
        cell.update(with: music)
        if indexPath == self.currentPlayingIndexPath {
            if self.isPlayerLoading {
                cell.state = .loading
            } else {
                if self.musicPlayer.rate == 0 {
                    cell.state = .normal
                } else {
                    cell.state = .playing
                }
            }
        }
        return cell
    }
}
