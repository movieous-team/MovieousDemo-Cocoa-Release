//
//  MDRecorderViewController.swift
//  MovieousDemo
//
//  Created by Chris Wang on 2019/4/9.
//  Copyright © 2019 Movieous Team. All rights reserved.
//

import UIKit
import MovieousShortVideo
import CoreServices
import SVProgressHUD

let MaxRecordDuration = 10.0
let RecorderVideoHeight = CGFloat(960)
let RecorderVideoWidth = CGFloat(544)

class MDRecorderViewController: UIViewController {
    let recordButton = UIButton()
    lazy var recordTypeView = MDRecordTypeSelectView()
    var duetVideoPath: String?
    var recorder: MSVRecorder?
    let progressBar = MDProgressBar()
    let backButton = UIButton()
    let switchCameraButton = UIButton()
    let switchCameraLabel = UILabel()
    let beautyButton = UIButton()
    let beautyLabel = UILabel()
    let speedAdjustButton = UIButton()
    let speedAdjustLabel = UILabel()
    let countdownButton = UIButton()
    let countdownLabel = UILabel()
    var speed = Float(1.0)
    let discardButton = UIButton()
    let doneButton = UIButton()
    let importButton = UIButton()
    let importLabel = UILabel()
    let stickerButton = UIButton()
    let stickerLabel = UILabel()
    let duetVideoPlayer = AVPlayer()
    let duetPlayerView = MDAVPlayerView()
    let speedContainerView = UIView()
    let countDownLabel = UILabel()
    let hintLabel = UILabel()
    lazy var musicView = UIView()
    lazy var musicLabel = UILabel()
    var currentSelectedMusic: MDMusic?
    var recordType = MDRecordTypeSelectView.RecordType.video
    var lastScale = CGFloat(1)
    lazy var faceBeautyCaptureEffect = MovieousFaceBeautyCaptureEffect()
    lazy var filterCaptureEffect = MovieousLUTFilterCaptureEffect()
    lazy var stickerView: UIView = {
        var view: UIView!
        switch vendorType {
        case .faceunity:
            view = FUStickerView()
            self.view.addSubview(view)
            view.snp.makeConstraints({ (make) in
                make.bottom.equalToSuperview()
                make.left.equalToSuperview()
                make.right.equalToSuperview()
                make.height.equalTo(230)
            })
        case .sensetime:
            view = STStickerView()
            self.view.addSubview(view)
            view.snp.makeConstraints({ (make) in
                make.bottom.equalToSuperview()
                make.left.equalToSuperview()
                make.right.equalToSuperview()
                make.height.equalTo(181)
            })
        case .tusdk:
            view = StickerPanelView()
            self.view.addSubview(view)
            view.snp.makeConstraints({ (make) in
                make.bottom.equalToSuperview()
                make.left.equalToSuperview()
                make.right.equalToSuperview()
                make.height.equalTo(230)
            })
        default:
            view = UIView()
            self.view.addSubview(view)
            view.snp.makeConstraints({ (make) in
                make.bottom.equalToSuperview()
                make.left.equalToSuperview()
                make.right.equalToSuperview()
                make.height.equalTo(230)
            })
        }
        view.isHidden = true
        return view
    }()
    
    lazy var beautifyView: UIView = {
        var view: UIView!
        switch vendorType {
        case .none:
            view = MDInnerBeautyFilterView()
            (view as! MDInnerBeautyFilterView).faceBeautyEffect = self.faceBeautyCaptureEffect
            (view as! MDInnerBeautyFilterView).filterEffect = self.filterCaptureEffect
            self.view.addSubview(view)
            view.snp.makeConstraints { (make) in
                make.bottom.equalToSuperview()
                make.left.equalToSuperview()
                make.right.equalToSuperview()
                make.height.equalTo(194)
            }
        case .faceunity:
            view = FUAPIDemoBar()
            (view as! FUAPIDemoBar).delegate = self
            (view as! FUAPIDemoBar).demoBar.makeupView.delegate = self
            self.view.addSubview(view)
            view.snp.makeConstraints { (make) in
                make.bottom.equalToSuperview()
                make.left.equalToSuperview()
                make.right.equalToSuperview()
                make.height.equalTo(194)
            }
        case .sensetime:
            view = MDSTBeautyFilterView()
            self.view.addSubview(view)
            view.snp.makeConstraints { (make) in
                make.bottom.equalToSuperview()
                make.left.equalToSuperview()
                make.right.equalToSuperview()
                make.height.equalTo(215)
            }
        default:
            view = UIView()
            break
        }
        view.isHidden = true
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.navigationItem.title = ""
        self.view.backgroundColor = .black
        let audioConfiguration = MSVRecorderAudioConfiguration.default()
        let videoConfiguration = MSVRecorderVideoConfiguration.default()
        videoConfiguration.preferredSessionPreset = .hd1280x720
        videoConfiguration.previewScalingMode = .aspectFill
        videoConfiguration.preferredTorchMode = .off
        videoConfiguration.preferredFlashMode = .off
        videoConfiguration.size = CGSize(width: RecorderVideoWidth, height: RecorderVideoHeight)
        var captureEffects: [MovieousCaptureEffect] = []
        if vendorType == .none {
            captureEffects.append(self.faceBeautyCaptureEffect)
            captureEffects.append(self.filterCaptureEffect)
        } else {
            let externalFilterCaptureEffect = MovieousExternalFilterCaptureEffect()
            externalFilterCaptureEffect.externalFilterClass = MDFilter.self
            captureEffects.append(externalFilterCaptureEffect)
        }
        videoConfiguration.captureEffects = captureEffects
        do {
            self.recorder = try MSVRecorder(audioConfiguration: audioConfiguration, videoConfiguration: videoConfiguration)
        } catch {
            ShowErrorAlert(error: error, controller: self)
            return
        }
        self.recorder?.delegate = self
        if let duetVideoPath = self.duetVideoPath {
            self.recorder?.mirrorFrontEncoded = true
            self.duetVideoPlayer.replaceCurrentItem(with: AVPlayerItem(url: .init(fileURLWithPath: duetVideoPath)))
            self.duetPlayerView.player = self.duetVideoPlayer
            self.duetPlayerView.videoGravity = .resizeAspectFill
        }
        NotificationCenter.default.addObserver(self, selector: #selector(ShowHint(notification:)), name: .MDShowHint, object: nil)
        self.buildUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = true;
        MDFilter.shared.dispose()
        MDFilter.shared.setup()
        self.recorder?.startCapturing(completion: { (audioGranted, audioError, videoGranted, videoError) in
            if let error = videoError {
                ShowErrorAlert(error: error, controller: self)
            }
            if let error = audioError {
                ShowErrorAlert(error: error, controller: self)
            }
            if !videoGranted {
                ShowAlert(title: NSLocalizedString("MDRecorderViewController.warning", comment: ""), message: NSLocalizedString("MDRecorderViewController.vpermission", comment: ""), action: NSLocalizedString("MDRecorderViewController.ok", comment: ""), controller: self)
            }
            if !audioGranted {
                ShowAlert(title: NSLocalizedString("MDRecorderViewController.warning", comment: ""), message: NSLocalizedString("MDRecorderViewController.apermission", comment: ""), action: NSLocalizedString("MDRecorderViewController.ok", comment: ""), controller: self)
            }
        })
        if vendorType == .faceunity {
            self.demoBarSetBeautyDefultParams()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.recorder?.stopCapturing()
    }
    
    @objc func ShowHint(notification: Notification) {
        self.hintLabel.isHidden = false
        self.hintLabel.text = notification.userInfo![MDHintNotificationKey] as! String?
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(dismissHint), object: nil)
        self.perform(#selector(dismissHint), with: nil, afterDelay: 3)
    }
    
    @objc func dismissHint() {
        self.hintLabel.isHidden = true
    }
    
    @objc func slowerButtonPressed(sender: UIButton) {
        for button in self.speedContainerView.subviews {
            (button as! UIButton).isSelected = false
        }
        sender.isSelected = true
        self.speed = 0.5
    }
    
    @objc func slowButtonPressed(sender: UIButton) {
        for button in self.speedContainerView.subviews {
            (button as! UIButton).isSelected = false
        }
        sender.isSelected = true
        self.speed = 0.75
    }
    
    @objc func normalButtonPressed(sender: UIButton) {
        for button in self.speedContainerView.subviews {
            (button as! UIButton).isSelected = false
        }
        sender.isSelected = true
        self.speed = 1
    }
    
    @objc func fastButtonPressed(sender: UIButton) {
        for button in self.speedContainerView.subviews {
            (button as! UIButton).isSelected = false
        }
        sender.isSelected = true
        self.speed = 1.5
    }
    
    @objc func fasterButtonPressed(sender: UIButton) {
        for button in self.speedContainerView.subviews {
            (button as! UIButton).isSelected = false
        }
        sender.isSelected = true
        self.speed = 2
    }
    
    @objc func switchCameraButtonPressed(sender: UIButton) {
        self.recorder?.switchCamera()
    }
    
    @objc func speedAdjustButtonPressed(sender: UIButton) {
        self.speedContainerView.isHidden = !self.speedContainerView.isHidden
    }
    
    @objc func musicButtonPressed(sender: UITapGestureRecognizer) {
        if self.currentSelectedMusic == nil {
            let viewController = MDRecorderMusicViewController()
            viewController.delegate = self
            viewController.modalPresentationStyle = .pageSheet
            self.present(viewController, animated: true, completion: nil)
        } else {
            let vc = UIAlertController()
            vc.addAction(.init(title: NSLocalizedString("MDRecorderViewController.clear", comment: ""), style: .destructive, handler: { (action) in
                self.currentSelectedMusic = nil
                try! self.recorder?.setBackgroundAudioWith(nil)
                self.musicLabel.text = NSLocalizedString("MDRecorderViewController.musics", comment: "")
            }))
            vc.addAction(.init(title: NSLocalizedString("MDRecorderViewController.change", comment: ""), style: .default, handler: { (action) in
                let viewController = MDRecorderMusicViewController()
                viewController.delegate = self
                viewController.modalPresentationStyle = .pageSheet
                self.present(viewController, animated: true, completion: nil)
            }))
            vc.addAction(.init(title: NSLocalizedString("MDRecorderViewController.cancel", comment: ""), style: .cancel, handler: nil))
            self.present(vc, animated: true, completion: nil)
        }
    }
    
    @objc func countdownButtonPressed(sender: UIButton) {
        let alertController = UIAlertController(title: NSLocalizedString("MDRecorderViewController.alert", comment: ""), message: NSLocalizedString("MDRecorderViewController.countdownmsg", comment: ""), preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("MDRecorderViewController.cancel", comment: ""), style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("MDRecorderViewController.confirm", comment: ""), style: .default, handler: { (action) in
            self.speedAdjustButton.isHidden = true
            self.speedAdjustLabel.isHidden = true
            self.countdownButton.isHidden = true
            self.countdownLabel.isHidden = true
            
            self.speedContainerView.isHidden = true
            self.backButton.isHidden = true
            self.importLabel.isHidden = true
            self.recordTypeView.isHidden = true
            self.importButton.isHidden = true
            self.discardButton.isHidden = true
            self.doneButton.isHidden = true
            self.countDownLabel.isHidden = false
            self.view.isUserInteractionEnabled = false
            self.animateCountDown(remaining: 3)
        }))
        self.present(alertController, animated: true, completion: nil)
    }
    
    @objc func discardButtonPressed(sender: UIButton) {
        if self.progressBar.lastProgressStyle == .normal {
            self.progressBar.lastProgressStyle = .delete
        } else {
            do {
                try self.recorder?.discardLastClip()
            } catch {
                ShowErrorAlert(error: error, controller: self)
            }
            self.progressBar.deleteLastProgress()
            self.duetVideoPlayer.seek(to: CMTime(seconds: self.recorder!.recordedClipsRealDuration, preferredTimescale: 1000), toleranceBefore: .zero, toleranceAfter: .zero)
            if self.recorder?.draft.mainTrackClips.count == 0 {
                self.recordTypeView.isHidden = false
                self.importLabel.isHidden = false
                self.importButton.isHidden = false
                if self.duetVideoPath == nil {
                    self.musicView.alpha = 1
                    self.musicView.isUserInteractionEnabled = true
                }
                
                self.discardButton.isHidden = true
                self.doneButton.isHidden = true
            }
        }
    }
    
    @objc func doneButtonPressed(sender: UIButton) {
        if let recorder = self.recorder {
            self.ShowEditorViewController(draft: recorder.draft)
        }
    }
    
    @objc func importButtonPressed(sender: UIButton) {
        let controller = UIImagePickerController()
        controller.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
        controller.allowsEditing = true
        controller.delegate = self
        controller.videoQuality = .typeHigh
        self.present(controller, animated: true, completion: nil)
    }
    
    @objc func stickerButtonPressed(sender: UIButton) {
        if vendorType == .none {
            ShowAlert(title: NSLocalizedString("global.alert", comment: ""), message: NSLocalizedString("global.vendornosticker", comment: ""), action: NSLocalizedString("global.ok", comment: ""), controller: self)
        } else {
            self.stickerView.isHidden = false
            self.beautifyView.isHidden = true
            self.stickerButton.isHidden = true
            self.stickerLabel.isHidden = true
            self.recordButton.isHidden = true
            self.recordTypeView.isHidden = true
            self.importButton.isHidden = true
            self.importLabel.isHidden = true
            self.speedContainerView.isHidden = true
            self.discardButton.isHidden = true
            self.doneButton.isHidden = true
        }
    }
    
    @objc func beautyButtonPressed(sender: UIButton) {
        if vendorType == .tusdk {
            ShowAlert(title: NSLocalizedString("global.alert", comment: ""), message: NSLocalizedString("global.vendornobeauty", comment: ""), action: NSLocalizedString("global.ok", comment: ""), controller: self)
        } else {
            self.beautifyView.isHidden = false
            self.stickerView.isHidden = true
            self.stickerButton.isHidden = true
            self.stickerLabel.isHidden = true
            self.recordButton.isHidden = true
            self.recordTypeView.isHidden = true
            self.importButton.isHidden = true
            self.importLabel.isHidden = true
            self.speedContainerView.isHidden = true
            self.discardButton.isHidden = true
            self.doneButton.isHidden = true
        }
    }
    
    @objc func viewTapped(sender: UITapGestureRecognizer) {
        guard let recorder = self.recorder else { return }
        self.stickerView.isHidden = true
        self.beautifyView.isHidden = true
        self.stickerButton.isHidden = false
        self.stickerLabel.isHidden = false
        self.recordButton.isHidden = false
        if !recorder.recording {
            if recorder.draft.mainTrackClips.count == 0 {
                self.recordTypeView.isHidden = false
                self.importButton.isHidden = false
                self.importLabel.isHidden = false
                self.discardButton.isHidden = true
                self.doneButton.isHidden = true
            } else {
                self.recordTypeView.isHidden = true
                self.importButton.isHidden = true
                self.importLabel.isHidden = true
                self.discardButton.isHidden = false
                self.doneButton.isHidden = false
            }
        }
    }
    
    @objc func pinched(sender: UIPinchGestureRecognizer) {
        if sender.state == .began {
            self.lastScale = 1
        } else {
            let deltaScale = sender.scale / self.lastScale
            self.lastScale = sender.scale
            var zoomFactor = self.recorder!.videoZoomFactor * deltaScale
            if zoomFactor > self.recorder!.videoMaxZoomFactor {
                zoomFactor = self.recorder!.videoMaxZoomFactor
            } else if zoomFactor < 1 {
                zoomFactor = 1
            }
            self.recorder?.preferredVideoZoomFactor = zoomFactor
        }
    }
    
    @objc func recordButtonPressed(sender: UIButton) {
        if sender.isSelected {
            self.stopRecording(completion: nil)
        } else {
            self.startRecording()
        }
    }
    
    @objc func backButtonPressed(sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    func buildUI() {
        if self.duetVideoPath == nil {
            self.view.addSubview(self.recorder!.previewView)
            self.recorder?.previewView.snp.makeConstraints({ (make) in
                make.center.equalToSuperview()
                make.width.equalToSuperview()
                make.height.equalToSuperview()
            })
            
            self.recordTypeView.delegate = self
            self.view.addSubview(self.recordTypeView)
            self.recordTypeView.snp.makeConstraints { (make) in
                make.bottom.equalToSuperview()
                make.height.equalTo(50)
                make.left.equalToSuperview()
                make.right.equalToSuperview()
            }
        } else {
            let viewRatio = self.view.frame.size.width / self.view.frame.size.height
            let videoRatio = RecorderVideoWidth * 2 / RecorderVideoHeight
            var videoSize = CGSize.zero
            if viewRatio > videoRatio {
                videoSize = .init(width: self.view.frame.size.height / RecorderVideoHeight * RecorderVideoWidth, height: self.view.frame.size.height)
            } else {
                videoSize = .init(width: self.view.frame.size.width / 2, height: self.view.frame.size.width / 2 / RecorderVideoWidth * RecorderVideoHeight)
            }
            self.recorder?.previewScalingMode = .aspectFit
            self.view.insertSubview(self.recorder!.previewView, at: 0)
            
            self.view.insertSubview(self.duetPlayerView, at: 0)
            
            self.recorder?.previewView.snp.makeConstraints({ (make) in
                make.left.equalToSuperview().offset(self.view.frame.size.width / 2 - videoSize.width)
                make.top.equalToSuperview().offset((self.view.frame.size.height - videoSize.height) / 2)
                make.width.equalTo(videoSize.width)
                make.height.equalTo(videoSize.height)
            })
            
            self.duetPlayerView.snp.makeConstraints { (make) in
                make.left.equalTo(self.recorder!.previewView.snp.right)
                make.top.equalToSuperview().offset((self.view.frame.size.height - videoSize.height) / 2)
                make.width.equalTo(videoSize.width)
                make.height.equalTo(videoSize.height)
            }
        }
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(viewTapped(sender:)))
        tapGestureRecognizer.delegate = self
        self.view.addGestureRecognizer(tapGestureRecognizer)
        
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(pinched(sender:)))
        pinch.delegate = self
        self.view.addGestureRecognizer(pinch)
        
        self.view.addSubview(self.progressBar)
        
        let backImage = UIImage(named: "goback_arrow")!
        self.backButton.setImage(backImage, for: .normal)
        self.backButton.addTarget(self, action: #selector(backButtonPressed(sender:)), for: .touchUpInside)
        self.view.addSubview(self.backButton)
        
        self.switchCameraButton.setImage(UIImage(named: "switch_camera"), for: .normal)
        self.switchCameraButton.addTarget(self, action: #selector(switchCameraButtonPressed(sender:)), for: .touchUpInside)
        self.view.addSubview(self.switchCameraButton)
        
        self.switchCameraLabel.text = NSLocalizedString("MDRecorderViewController.switch", comment: "")
        self.switchCameraLabel.textColor = .white
        self.switchCameraLabel.font = .systemFont(ofSize: 9)
        self.switchCameraLabel.shadowColor = .black
        self.switchCameraLabel.shadowOffset = CGSize(width: 1, height: 1)
        self.view.addSubview(self.switchCameraLabel)
        
        self.beautyButton.setImage(UIImage(named: "beauty"), for: .normal)
        self.beautyButton.addTarget(self, action: #selector(beautyButtonPressed(sender:)), for: .touchUpInside)
        self.view.addSubview(self.beautyButton)
        
        self.beautyLabel.text = NSLocalizedString("MDRecorderViewController.beauty", comment: "")
        self.beautyLabel.textColor = .white
        self.beautyLabel.font = .systemFont(ofSize: 9)
        self.beautyLabel.shadowColor = .black
        self.beautyLabel.shadowOffset = CGSize(width: 1, height: 1)
        self.view.addSubview(self.beautyLabel)
        
        self.speedAdjustButton.setImage(UIImage(named: "quick_slow"), for: .normal)
        self.speedAdjustButton.addTarget(self, action: #selector(speedAdjustButtonPressed(sender:)), for: .touchUpInside)
        self.view.addSubview(self.speedAdjustButton)
        
        self.speedAdjustLabel.text = NSLocalizedString("MDRecorderViewController.speed", comment: "")
        self.speedAdjustLabel.textColor = .white
        self.speedAdjustLabel.font = .systemFont(ofSize: 9)
        self.speedAdjustLabel.shadowColor = .black
        self.speedAdjustLabel.shadowOffset = CGSize(width: 1, height: 1)
        self.view.addSubview(self.speedAdjustLabel)
        
        self.countdownButton.setImage(UIImage(named: "count_down"), for: .normal)
        self.countdownButton.addTarget(self, action: #selector(countdownButtonPressed(sender:)), for: .touchUpInside)
        self.view.addSubview(self.countdownButton)
        
        self.countdownLabel.text = NSLocalizedString("MDRecorderViewController.countdown", comment: "")
        self.countdownLabel.textColor = .white
        self.countdownLabel.font = .systemFont(ofSize: 9)
        self.countdownLabel.shadowColor = .black
        self.countdownLabel.shadowOffset = CGSize(width: 1, height: 1)
        self.view.addSubview(self.countdownLabel)
        
        self.recordButton.setImage(UIImage(named: "start_btn"), for: .normal)
        self.recordButton.setImage(UIImage(named: "starting_btn"), for: .selected)
        self.recordButton.addTarget(self, action: #selector(recordButtonPressed(sender:)
            ), for: .touchUpInside)
        self.view.addSubview(self.recordButton)
        
        self.doneButton.isHidden = true
        self.doneButton.setImage(UIImage(named: "done"), for: .normal)
        self.doneButton.addTarget(self, action: #selector(doneButtonPressed(sender:)), for: .touchUpInside)
        self.view.addSubview(self.doneButton)
        
        self.discardButton.isHidden = true
        self.discardButton.setImage(UIImage(named: "goback"), for: .normal)
        self.discardButton.addTarget(self, action: #selector(discardButtonPressed(sender:)), for: .touchUpInside)
        self.view.addSubview(self.discardButton)
        
        self.importButton.addTarget(self, action: #selector(importButtonPressed(sender:)), for: .touchUpInside)
        self.importButton.layer.borderWidth = 3
        self.importButton.layer.borderColor = UIColor.white.cgColor
        self.fillImportButtonImage()
        self.view.addSubview(self.importButton)
        
        self.importLabel.text = NSLocalizedString("MDRecorderViewController.import", comment: "")
        self.importLabel.textColor = .white
        self.importLabel.font = .systemFont(ofSize: 10)
        self.importLabel.shadowColor = .black
        self.importLabel.shadowOffset = CGSize(width: 1, height: 1)
        self.view.addSubview(self.importLabel)
        
        self.stickerButton.setImage(UIImage(named: "sticker"), for: .normal)
        self.stickerButton.addTarget(self, action: #selector(stickerButtonPressed(sender:)), for: .touchUpInside)
        self.view.addSubview(self.stickerButton)
        
        self.stickerLabel.text = NSLocalizedString("MDRecorderViewController.sticker", comment: "")
        self.stickerLabel.textColor = .white
        self.stickerLabel.font = .systemFont(ofSize: 10)
        self.stickerLabel.shadowColor = .black
        self.stickerLabel.shadowOffset = CGSize(width: 1, height: 1)
        self.view.addSubview(self.stickerLabel)
        
        self.countDownLabel.isHidden = true
        self.countDownLabel.textColor = .white
        self.countDownLabel.font = .systemFont(ofSize: 150)
        self.view.addSubview(self.countDownLabel)
        
        self.speedContainerView.layer.cornerRadius = 3
        self.speedContainerView.layer.masksToBounds = true
        
        let slowerButton = self.generateSpeedButton(titleKey: "global.slower")
        slowerButton.addTarget(self, action: #selector(slowerButtonPressed(sender:)), for: .touchUpInside)
        
        let slowButton = self.generateSpeedButton(titleKey: "global.slow")
        slowButton.addTarget(self, action: #selector(slowButtonPressed(sender:)), for: .touchUpInside)
        
        let normalButton = self.generateSpeedButton(titleKey: "global.standard")
        normalButton.isSelected = true
        normalButton.addTarget(self, action: #selector(normalButtonPressed(sender:)), for: .touchUpInside)
        
        let fastButton = self.generateSpeedButton(titleKey: "global.fast")
        fastButton.addTarget(self, action: #selector(fastButtonPressed(sender:)), for: .touchUpInside)
        
        let fasterButton = self.generateSpeedButton(titleKey: "global.faster")
        fasterButton.addTarget(self, action: #selector(fasterButtonPressed(sender:)), for: .touchUpInside)
        
        self.view.addSubview(self.speedContainerView)
        
        self.hintLabel.textColor = .white
        self.hintLabel.font = .systemFont(ofSize: 17)
        self.view.addSubview(self.hintLabel)
        
        if self.duetVideoPath == nil {
            let musicIcon = UIImageView(image: UIImage(named: "music_white"))
            self.musicView.addSubview(musicIcon)
            musicIcon.snp.makeConstraints { (make) in
                make.left.equalToSuperview()
                make.centerY.equalToSuperview()
                make.height.equalTo(20)
                make.width.equalTo(musicIcon.snp.height)
            }
            
            self.musicLabel.textColor = .white
            self.musicLabel.text = NSLocalizedString("MDRecorderViewController.musics", comment: "")
            self.musicLabel.shadowOffset = .init(width: 1, height: 1)
            self.musicLabel.shadowColor = .black
            self.musicView.addSubview(self.musicLabel)
            self.musicLabel.snp.makeConstraints { (make) in
                make.left.equalTo(musicIcon.snp.right)
                make.right.equalToSuperview()
                make.top.equalToSuperview()
                make.bottom.equalToSuperview()
            }
            
            let musicTap = UITapGestureRecognizer(target: self, action: #selector(musicButtonPressed(sender:)))
            self.musicView.addGestureRecognizer(musicTap)
            
            self.view.addSubview(self.musicView)
            self.musicView.snp.makeConstraints { (make) in
                make.centerX.equalToSuperview()
                make.centerY.equalTo(self.backButton)
            }
        }
        
        self.progressBar.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.top.equalToSuperview().offset(9)
            make.height.equalTo(5)
        }
        
        self.backButton.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(20)
            make.top.equalTo(self.progressBar.snp_bottom).offset(5)
            make.size.equalTo(50)
        }
        
        self.switchCameraButton.snp.makeConstraints { (make) in
            make.top.equalTo(self.progressBar.snp.bottom).offset(24)
            make.right.equalToSuperview().offset(-15)
            make.width.equalTo(32)
            make.height.equalTo(29)
        }
        
        self.switchCameraLabel.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.switchCameraButton)
            make.top.equalTo(self.switchCameraButton.snp.bottom)
        }
        
        self.beautyButton.snp.makeConstraints { (make) in
            make.top.equalTo(self.switchCameraLabel.snp.bottom).offset(10)
            make.centerX.equalTo(self.switchCameraButton)
            make.width.equalTo(30)
            make.height.equalTo(33)
        }
        
        self.beautyLabel.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.beautyButton)
            make.top.equalTo(self.beautyButton.snp.bottom)
        }
        
        self.speedAdjustButton.snp.makeConstraints { (make) in
            make.top.equalTo(self.beautyLabel.snp.bottom).offset(10)
            make.centerX.equalTo(self.switchCameraButton)
            make.width.equalTo(30)
            make.height.equalTo(31)
        }
        
        self.speedAdjustLabel.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.speedAdjustButton)
            make.top.equalTo(self.speedAdjustButton.snp.bottom)
        }
        
        self.countdownButton.snp.makeConstraints { (make) in
            make.top.equalTo(self.speedAdjustLabel.snp.bottom).offset(10)
            make.centerX.equalTo(self.switchCameraButton)
            make.width.equalTo(27)
            make.height.equalTo(34)
        }
        
        self.countdownLabel.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.countdownButton)
            make.top.equalTo(self.countdownButton.snp.bottom)
        }
        
        self.recordButton.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-55)
            make.width.equalTo(64)
            make.height.equalTo(64)
        }
        
        self.doneButton.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-50)
            make.centerY.equalTo(self.recordButton)
            make.width.equalTo(32)
            make.height.equalTo(32)
        }
        
        self.discardButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.recordButton)
            make.right.equalTo(self.doneButton.snp.left).offset(-25)
            make.width.equalTo(24)
            make.height.equalTo(18)
        }
        
        self.importButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.recordButton)
            make.centerX.equalTo(self.recordButton).offset(100)
            make.width.equalTo(25)
            make.height.equalTo(25)
        }
        
        self.importLabel.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.importButton)
            make.top.equalTo(self.importButton.snp_bottom).offset(5)
        }
        
        self.stickerButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.recordButton)
            make.centerX.equalTo(self.recordButton).offset(-100)
            make.width.equalTo(28)
            make.height.equalTo(28)
        }
        
        self.stickerLabel.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.stickerButton)
            make.top.equalTo(self.stickerButton.snp_bottom).offset(5)
        }
        
        self.countDownLabel.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
        
        slowerButton.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.right.equalTo(slowButton.snp.left)
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        slowButton.snp.makeConstraints { (make) in
            make.right.equalTo(normalButton.snp.left)
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.width.equalTo(slowerButton)
        }
        
        normalButton.snp.makeConstraints { (make) in
            make.right.equalTo(fastButton.snp.left)
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.width.equalTo(slowerButton)
        }
        
        fastButton.snp.makeConstraints { (make) in
            make.right.equalTo(fasterButton.snp.left)
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.width.equalTo(slowerButton)
        }
        
        fasterButton.snp.makeConstraints { (make) in
            make.right.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.width.equalTo(slowerButton)
        }
        
        self.speedContainerView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-154)
            make.width.equalTo(285)
            make.height.equalTo(35)
        }
        
        self.hintLabel.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.height.equalTo(24)
        }
    }
    
    func startRecording() {
        guard let recorder = self.recorder else {
            ShowAlert(title: NSLocalizedString("MDRecorderViewController.error", comment: ""), message: NSLocalizedString("MDRecorderViewController.norecorder", comment: ""), action: NSLocalizedString("MDRecorderViewController.ok", comment: ""), controller: self)
            return
        }
        if self.recordType == .video {
            if recorder.recordedClipsRealDuration / TimeInterval(self.speed) >= MaxRecordDuration {
                self.ShowEditorViewController(draft: recorder.draft)
                return
            }
            let configuration = MSVClipConfiguration()
            configuration.speed = CGFloat(self.speed)
            do {
                try recorder.startRecording(with: configuration)
            } catch {
                ShowErrorAlert(error: error, controller: self)
                return
            }
            self.duetVideoPlayer.rate = 1.0 / self.speed
            DispatchQueue.main.async {
                self.progressBar.beginSegment()
                
                self.recordButton.isSelected = true
                
                self.speedContainerView.isHidden = true
                
                self.backButton.isHidden = true
                
                self.discardButton.isHidden = true
                self.doneButton.isHidden = true
                
                self.recordTypeView.isHidden = true
                self.importButton.isHidden = true
                self.importLabel.isHidden = true
                
                self.speedAdjustButton.isHidden = true
                self.speedAdjustLabel.isHidden = true
                self.countdownButton.isHidden = true
                self.countdownLabel.isHidden = true
                
                self.musicView.alpha = 0.5
                self.musicView.isUserInteractionEnabled = false
            }
        } else {
            recorder.snapshot { (image, error) in
                if let error = error {
                    ShowErrorAlert(error: error, controller: self)
                    return
                }
                DispatchQueue.main.async {
                    let vc = MDImageEditorViewController()
                    vc.image = image
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
    }
    
    func stopRecording(completion: (() -> Void)?) {
        self.view.isUserInteractionEnabled = false
        self.recorder?.finishRecording(completionHandler: { (clip, error) in
            DispatchQueue.main.async {
                self.recordButton.isSelected = false
                
                self.discardButton.isHidden = false
                self.doneButton.isHidden = false
                
                self.backButton.isHidden = false
                
                self.speedAdjustButton.isHidden = false
                self.speedAdjustLabel.isHidden = false
                self.countdownButton.isHidden = false
                self.countdownLabel.isHidden = false
                
                self.view.isUserInteractionEnabled = true
            }
            if let error = error {
                ShowErrorAlert(error: error, controller: self)
                return
            }
            guard let clip = clip else {
                ShowAlert(title: NSLocalizedString("MDRecorderViewController.error", comment: ""), message: NSLocalizedString("MDRecorderViewController.noclip", comment: ""), action: NSLocalizedString("MDRecorderViewController.ok", comment: ""), controller: self)
                return
            }
            self.progressBar.updateProgress(progress: Float(clip.durationAtMainTrack / MaxRecordDuration))
            self.progressBar.finishSegment()
            if let completion = completion {
                completion()
            }
        })
        self.duetVideoPlayer.pause()
    }
    
    func ShowEditorViewController(draft: MSVDraft) {
        self.duetVideoPlayer.pause()
        SVProgressHUD.show(withStatus: NSLocalizedString("MDRecorderViewController.loading", comment: ""))
        if self.currentSelectedMusic != nil {
            for clip in draft.mainTrackClips {
                if clip.type == .AV {
                    clip.volume = 0
                }
            }
        }
        if let duetVideoPath = self.duetVideoPath {
            do {
                for clip in draft.mainTrackClips {
                    clip.destDisplayFrame = .init(x: 0, y: 0, width: RecorderVideoWidth, height: RecorderVideoHeight)
                    clip.scalingMode = .fill
                    if clip.type == .AV {
                        clip.volume = 0
                    }
                }
                let mixTrackClip = try MSVMixTrackClip(type: .AV, path: duetVideoPath)
                mixTrackClip.destDisplayFrame = .init(x: RecorderVideoWidth, y: 0, width: RecorderVideoWidth, height: RecorderVideoHeight)
                mixTrackClip.scalingMode = .fill
                try draft.update(mixTrackClips: [mixTrackClip])
                try draft.update(videoSize: .init(width: 2 * RecorderVideoWidth, height: RecorderVideoHeight))
            } catch {
                ShowErrorAlert(error: error, controller: self)
            }
        }
        let exporter = MSVExporter(draft: draft)
        exporter.progressHandler = { progress in
            SVProgressHUD.showProgress(progress, status: NSLocalizedString("MDRecorderViewController.loading", comment: ""))
        }
        exporter.failureHandler = { error in
            ShowErrorAlert(error: error, controller: self)
        }
        exporter.completionHandler = { path in
            SVProgressHUD.dismiss(completion: {
                do {
                    let draft = try MSVDraft(avPath: path)
                    DispatchQueue.main.async {
                        let editorViewController = MDVideoEditorViewController()
                        editorViewController.draft = draft
                        editorViewController.recorderMusic = self.currentSelectedMusic
                        self.navigationController?.pushViewController(editorViewController, animated: true)
                    }
                } catch {
                    ShowErrorAlert(error: error, controller: self)
                }
            })
        }
        exporter.startExport()
    }
    
    func animateCountDown(remaining: Int) {
        if remaining == 0 {
            self.view.isUserInteractionEnabled = true
            self.startRecording()
        } else {
            self.countDownLabel.text = "\(remaining)"
            let fontSize = self.countDownLabel.font.pointSize
            self.countDownLabel.transform = .init(scaleX: 1.0 / fontSize, y: 1.0 / fontSize)
            UIView.animate(withDuration: 0.2, animations: {
                self.countDownLabel.transform = .identity
            }) { (finished) in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6, execute: {
                    UIView.animate(withDuration: 0.2, animations: {
                        self.countDownLabel.transform = .init(scaleX: 1.0 / fontSize, y: 1.0 / fontSize)
                    }, completion: { (finished) in
                        self.animateCountDown(remaining: remaining - 1)
                    })
                })
            }
        }
    }
    
    func generateSpeedButton(titleKey: String) -> UIButton {
        let button = UIButton(type: .custom)
        button.setBackgroundImage(.from(color: .init(r: 0, g: 0, b: 0, a: 0.64)), for: .normal)
        button.setBackgroundImage(.from(color: .white), for: .selected)
        button.layer.masksToBounds = true
        button.setAttributedTitle(NSAttributedString(string: NSLocalizedString(titleKey, comment: ""), attributes: [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.white]), for: .normal)
        button.setAttributedTitle(NSAttributedString(string: NSLocalizedString(titleKey, comment: ""), attributes: [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.black]), for: .selected)
        self.speedContainerView.addSubview(button)
        return button
    }
    
    func fillImportButtonImage() {
        PHPhotoLibrary.requestAuthorization { (status) in
            if status == .authorized {
                let fetchOptions = PHFetchOptions()
                fetchOptions.sortDescriptors = [NSSortDescriptor(key: "modificationDate", ascending: false), NSSortDescriptor(key: "creationDate", ascending: false)]
                let fetchResult = PHAsset.fetchAssets(with: .video, options: fetchOptions)
                if fetchResult.count > 0 {
                    PHImageManager.default().requestImage(for: fetchResult[0], targetSize: self.importButton.frame.size, contentMode: .aspectFill, options: nil, resultHandler: { (result, info) in
                        DispatchQueue.main.async {
                            if let result = result {
                                self.importButton.setImage(result, for: .normal)
                            }
                        }
                    })
                }
            }
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

extension MDRecorderViewController: MDRecorderMusicViewControllerDelegate {
    func controller(_ controller: MDRecorderMusicViewController, didSelect music: MDMusic) {
        self.musicLabel.text = music.name
        self.currentSelectedMusic = music
        do {
            let configuration = try MSVRecorderBackgroundAudioConfiguration(path: music.localPath!)
            try self.recorder?.setBackgroundAudioWith(configuration)
        } catch {
            ShowErrorAlert(error: error, controller: self)
        }
    }
}

extension MDRecorderViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let view = touch.view else {
            return true
        }
        if view.isDescendant(of: self.stickerView) || view.isDescendant(of: self.beautifyView) {
            return false
        }
        return true
    }
}

extension MDRecorderViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let recorder = self.recorder else {
            return
        }
        let mediaType = info[.mediaType]! as! String
        if mediaType == kUTTypeImage as String {
            var theImage: UIImage!
            if picker.allowsEditing {
                theImage = (info[.editedImage] as! UIImage)
            } else {
                theImage = (info[.originalImage] as! UIImage)
            }
            let vc = MDImageEditorViewController()
            vc.image = theImage
            picker.dismiss(animated: true, completion: nil)
            self.navigationController?.pushViewController(vc, animated: true)
        } else if mediaType == kUTTypeMovie as String {
            do {
                let draft = recorder.draft.copy() as! MSVDraft
                var clip: MSVMainTrackClip?
                clip = try MSVMainTrackClip(type: .AV, path: (info[.mediaURL] as! URL).path)
                if self.duetVideoPath != nil {
                    clip?.scalingMode = .aspectFill
                    clip?.destDisplayFrame = .init(x: 0, y: 0, width: 360, height: 640)
                    if clip!.type == .AV {
                        clip?.volume = 0
                    }
                }
                try draft.update(mainTrackClips: [clip!])
                picker.dismiss(animated: true, completion: nil)
                self.ShowEditorViewController(draft: draft)
            } catch {
                ShowErrorAlert(error: error, controller: self)
                return
            }
        }
    }
}

extension MDRecorderViewController: MSVRecorderDelegate {
    func recorder(_ recorder: MSVRecorder, currentClipDurationDidUpdated currentClipDuration: TimeInterval) {
        self.progressBar.updateProgress(progress: Float(currentClipDuration / MaxRecordDuration) / self.speed)
        if recorder.recordedClipsRealDuration + currentClipDuration / TimeInterval(self.speed) >= MaxRecordDuration {
            self.stopRecording {
                self.ShowEditorViewController(draft: recorder.draft)
            }
        }
    }
    
    func recorder(_ recorder: MSVRecorder, didErrorOccurred error: Error) {
        ShowErrorAlert(error: error, controller: self)
    }
}

extension MDRecorderViewController: FUAPIDemoBarDelegate {
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
    }
    
    func restDefaultValue(_ type: Int32) {
        if (type == 1) {//美肤
            FUManager.share()?.setBeautyDefaultParameters(.skin)
        }
        
        if (type == 2) {
            FUManager.share()?.setBeautyDefaultParameters(.shape)
        }
        self.demoBarSetBeautyDefultParams()
    }
}

extension MDRecorderViewController: FUMakeUpViewDelegate {
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

extension MDRecorderViewController: MDRecordTypeSelectViewDelegate {
    func recordTypeSelectView(recordTypeSelectView: MDRecordTypeSelectView, didSelectRecordType type: MDRecordTypeSelectView.RecordType) {
        self.recordType = type
    }
}


protocol MDRecordTypeSelectViewDelegate: NSObjectProtocol {
    func recordTypeSelectView(recordTypeSelectView: MDRecordTypeSelectView, didSelectRecordType type: MDRecordTypeSelectView.RecordType)
}

class MDRecordTypeSelectView: UIView {
    let scrollView = UIScrollView()
    let photoButton = UIButton(type: .custom)
    let videoButton = UIButton(type: .custom)
    let buttonMargin = CGFloat(20)
    weak var delegate: MDRecordTypeSelectViewDelegate?
    enum RecordType {
        case photo
        case video
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let recordTypeIndicator = UIView()
        recordTypeIndicator.backgroundColor = .white
        recordTypeIndicator.layer.cornerRadius = 3
        self.addSubview(recordTypeIndicator)
        
        self.scrollView.delegate = self
        self.scrollView.decelerationRate = .fast
        self.scrollView.showsHorizontalScrollIndicator = false
        self.scrollView.showsVerticalScrollIndicator = false
        self.addSubview(self.scrollView)
        
        self.photoButton.setTitleColor(.lightGray, for: .normal)
        self.photoButton.setTitleColor(.white, for: .selected)
        self.photoButton.setTitle(NSLocalizedString("MDRecordTypeSelectView.photo", comment: ""), for: .normal)
        self.photoButton.addTarget(self, action: #selector(photoButtonPressed(sender:)), for: .touchUpInside)
        self.scrollView.addSubview(photoButton)
        
        self.videoButton.setTitleColor(.lightGray, for: .normal)
        self.videoButton.setTitleColor(.white, for: .selected)
        self.videoButton.setTitle(NSLocalizedString("MDRecordTypeSelectView.video", comment: ""), for: .normal)
        self.videoButton.addTarget(self, action: #selector(videoButtonPressed(sender:)), for: .touchUpInside)
        self.scrollView.addSubview(videoButton)
        
        self.scrollView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalTo(recordTypeIndicator).offset(-10)
        }
        
        self.photoButton.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.scrollView.snp.left).offset(self.frame.size.width / 2)
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        self.videoButton.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.scrollView.snp.right).offset(-self.frame.size.width / 2)
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.left.equalTo(self.photoButton.snp.right).offset(self.buttonMargin)
        }
        
        recordTypeIndicator.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-5)
            make.size.equalTo(6)
        }
        
        self.videoButtonPressed(sender: self.videoButton)
    }
    
    override func layoutSubviews() {
        self.photoButton.snp.updateConstraints { (make) in
            make.centerX.equalTo(self.scrollView.snp.left).offset(self.frame.size.width / 2)
        }
        
        self.videoButton.snp.updateConstraints { (make) in
            make.centerX.equalTo(self.scrollView.snp.right).offset(-self.frame.size.width / 2)
        }
        self.videoButtonPressed(sender: self.videoButton)
    }
    
    @objc func photoButtonPressed(sender: UIButton) {
        self.scrollView.setContentOffset(.init(x: 0, y: 0), animated: true)
        self.photoButton.isSelected = true
        self.videoButton.isSelected = false
        if let delegate = self.delegate {
            delegate.recordTypeSelectView(recordTypeSelectView: self, didSelectRecordType: .photo)
        }
    }
    
    @objc func videoButtonPressed(sender: UIButton) {
        self.scrollView.setContentOffset(.init(x: self.photoButton.frame.size.width / 2 + self.buttonMargin + self.videoButton.frame.size.width / 2, y: 0), animated: true)
        self.photoButton.isSelected = false
        self.videoButton.isSelected = true
        if let delegate = self.delegate {
            delegate.recordTypeSelectView(recordTypeSelectView: self, didSelectRecordType: .video)
        }
    }
}

extension MDRecordTypeSelectView: UIScrollViewDelegate {
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let offset = targetContentOffset.pointee
        if offset.x <= self.photoButton.frame.size.width / 2  + self.buttonMargin / 2 {
            targetContentOffset.initialize(to: .init(x: 0, y: 0))
            self.photoButton.isSelected = true
            self.videoButton.isSelected = false
            if let delegate = self.delegate {
                delegate.recordTypeSelectView(recordTypeSelectView: self, didSelectRecordType: .photo)
            }
        } else {
            targetContentOffset.initialize(to: .init(x: self.photoButton.frame.size.width / 2 + self.buttonMargin + self.videoButton.frame.size.width / 2, y: 0))
            self.photoButton.isSelected = false
            self.videoButton.isSelected = true
            if let delegate = self.delegate {
                delegate.recordTypeSelectView(recordTypeSelectView: self, didSelectRecordType: .video)
            }
        }
    }
}
