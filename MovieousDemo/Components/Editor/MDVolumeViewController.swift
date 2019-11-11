//
//  MDVolumeViewController.swift
//  MovieousDemo
//
//  Created by Chris Wang on 2019/6/26.
//  Copyright © 2019 Movieous Team. All rights reserved.
//

import UIKit
import MovieousShortVideo

class MDVolumeViewController: UIViewController {
    var editor: MSVEditor!
    var recorderMusic: MDMusic?

    let originalLabel = UILabel()
    let originalSlider = MDSlider()
    let originalButton = MDButton()
    let musicLabel = UILabel()
    let musicSlider = MDSlider()
    let musicButton = MDButton()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.buildUI()
    }
    
    @objc func originalSliderValueChanged(sender: UISlider) {
        guard let mainTrackClip = self.editor.draft.mainTrackClips.first else { return }
        mainTrackClip.volume = sender.value
    }
    
    @objc func originalButtonPressed(sender: UIButton) {
        self.originalSlider.value = 0
        self.originalSliderValueChanged(sender: self.originalSlider)
    }
    
    @objc func musicSliderValueChanged(sender: UISlider) {
        guard let mainTrackClip = self.editor.draft.mainTrackClips.first else { return }
        if let clip = self.editor.draft.mixTrackClips.first {
            clip.volume = sender.value
        } else if self.recorderMusic != nil {
            mainTrackClip.volume = sender.value
        }
    }
    
    @objc func musicButtonPressed(sender: UIButton) {
        self.musicSlider.value = 0
        self.musicSliderValueChanged(sender: self.musicSlider)
    }
    
    func buildUI() {
        guard let mainTrackClip = self.editor.draft.mainTrackClips.first else {
            ShowAlert(title: NSLocalizedString("MDVolumeViewController.error", comment: ""), message: NSLocalizedString("MDVolumeViewController.nomain.error", comment: ""), action: NSLocalizedString("MDVolumeViewController.ok", comment: ""), controller: self)
            return
        }
        self.title = NSLocalizedString("MDVolumeViewController.volume", comment: "")
        
        self.view.backgroundColor = .black
        
        self.originalLabel.text = NSLocalizedString("MDVolumeViewController.original", comment: "")
        self.originalLabel.textColor = .white
        self.originalLabel.font = .systemFont(ofSize: 12)
        self.view.addSubview(self.originalLabel)
        
        self.originalSlider.minimumValue = 0
        self.originalSlider.maximumValue = 3
        self.originalSlider.addTarget(self, action: #selector(originalSliderValueChanged(sender:)), for: .valueChanged)
        self.view.addSubview(self.originalSlider)
        
        self.originalButton.titleLabel?.font = .systemFont(ofSize: 9)
        self.originalButton.setTitle(NSLocalizedString("MDVolumeViewController.mute", comment: ""), for: .normal)
        self.originalButton.addTarget(self, action: #selector(originalButtonPressed(sender:)), for: .touchUpInside)
        self.view.addSubview(self.originalButton)
        
        if self.recorderMusic == nil {
            self.originalLabel.isEnabled = true
            self.originalSlider.isEnabled = true
            self.originalButton.isEnabled = true
            self.originalSlider.value = mainTrackClip.volume
        } else {
            self.originalLabel.isEnabled = false
            self.originalSlider.isEnabled = false
            self.originalButton.isEnabled = false
            self.originalSlider.value = 0
        }
        
        self.musicLabel.text = NSLocalizedString("MDVolumeViewController.music", comment: "")
        self.musicLabel.textColor = .white
        self.musicLabel.font = .systemFont(ofSize: 12)
        self.view.addSubview(self.musicLabel)
        
        self.musicSlider.minimumValue = 0
        self.musicSlider.maximumValue = 3
        self.musicSlider.value = 0.5
        self.musicSlider.addTarget(self, action: #selector(musicSliderValueChanged(sender:)), for: .valueChanged)
        self.view.addSubview(self.musicSlider)
        
        self.musicButton.titleLabel?.font = .systemFont(ofSize: 9)
        self.musicButton.setTitle(NSLocalizedString("MDVolumeViewController.mute", comment: ""), for: .normal)
        self.musicButton.addTarget(self, action: #selector(musicButtonPressed(sender:)), for: .touchUpInside)
        self.view.addSubview(self.musicButton)
        
        if let clip = self.editor.draft.mixTrackClips.first {
            self.musicLabel.isEnabled = true
            self.musicSlider.isEnabled = true
            self.musicButton.isEnabled = true
            self.musicSlider.value = clip.volume
        } else if self.recorderMusic != nil {
            self.musicLabel.isEnabled = true
            self.musicSlider.isEnabled = true
            self.musicButton.isEnabled = true
            self.musicSlider.value = mainTrackClip.volume
        } else {
            self.musicLabel.isEnabled = false
            self.musicSlider.isEnabled = false
            self.musicButton.isEnabled = false
            self.musicSlider.value = 0
        }
        
        self.originalLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview().offset(-40)
            make.left.equalToSuperview().offset(15)
        }
        
        self.originalButton.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-15)
            make.centerY.equalTo(self.originalLabel)
        }
        
        self.originalSlider.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.originalLabel)
            make.centerX.equalToSuperview()
            make.width.greaterThanOrEqualTo(200)
        }
        
        self.musicLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview().offset(40)
            make.left.equalTo(self.originalLabel)
        }
        
        self.musicButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.musicLabel)
            make.right.equalTo(self.originalButton)
        }
        
        self.musicSlider.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.musicLabel)
            make.left.equalTo(self.originalSlider)
            make.right.equalTo(self.originalSlider)
            make.left.greaterThanOrEqualTo(self.musicLabel.snp.right).offset(15)
            make.right.lessThanOrEqualTo(self.musicButton.snp.left).offset(-15)
        }
    }
}
