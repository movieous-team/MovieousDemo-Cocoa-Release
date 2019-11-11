//
//  MDVideoGraffitiViewController.swift
//  MovieousDemo
//
//  Created by Chris Wang on 2019/6/27.
//  Copyright © 2019 Movieous Team. All rights reserved.
//

import UIKit
import MovieousShortVideo

protocol MDVideoGraffitiViewControllerDelegate: NSObjectProtocol {
    func graffitiManagerController(graffitiManagerController: MDVideoGraffitiViewController, didGetGraffiti imageStickerEditorEffect: MSVImageStickerEditorEffect)
}

class MDVideoGraffitiViewController: UIViewController {
    var graffitiManager: MSVGraffitiManager!
    let brushColors: [UIColor] = [.init(r: 0, g: 0, b: 0, a: 1), .init(r: 255, g: 255, b: 255, a: 1), .init(r: 255, g: 0, b: 0, a: 1), .init(r: 0, g: 255, b: 0, a: 1), .init(r: 0, g: 0, b: 255, a: 1), .init(r: 159, g: 0, b: 82, a: 1), .init(r: 235, g: 97, b: 111, a: 1), .init(r: 252, g: 226, b:196, a: 1), .init(r: 192, g: 220, b: 151, a: 1), .init(r: 65, g: 178, b: 102, a: 1)]
    var brushSizeSlider = MDSlider()
    let undoButton = MDButton(cornerRadius: 0)
    let redoButton = MDButton(cornerRadius: 0)
    let resetButton = MDButton(cornerRadius: 0)
    let clearAllButton = MDButton(cornerRadius: 0)
    var snapshotSize: CGSize!
    weak var delegate: MDVideoGraffitiViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.view.backgroundColor = .black
        
        self.graffitiManager.delegate = self
        self.graffitiManager.hideGraffitiView = false
        
        let brushSizeLabel = UILabel()
        brushSizeLabel.textColor = UIColor.white.withAlphaComponent(0.59)
        brushSizeLabel.font = .systemFont(ofSize: 11)
        brushSizeLabel.text = NSLocalizedString("MDGraffitiViewController.size", comment: "")
        self.view.addSubview(brushSizeLabel)
        brushSizeLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(20)
            make.top.equalTo(topLayoutGuide.snp.bottom).offset(10)
        }
        
        self.brushSizeSlider.minimumValue = 5
        self.brushSizeSlider.maximumValue = 30
        self.brushSizeSlider.value = Float(self.graffitiManager.brush.lineWidth)
        self.sliderValueChanged(sender: self.brushSizeSlider)
        self.brushSizeSlider.addTarget(self, action: #selector(sliderValueChanged(sender:)), for: .valueChanged)
        self.view.addSubview(self.brushSizeSlider)
        self.brushSizeSlider.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.top.equalTo(brushSizeLabel.snp.bottom).offset(10)
        }

        let brushColorLabel = UILabel()
        brushColorLabel.textColor = UIColor.white.withAlphaComponent(0.59)
        brushColorLabel.font = .systemFont(ofSize: 11)
        brushColorLabel.text = NSLocalizedString("MDGraffitiViewController.color", comment: "")
        self.view.addSubview(brushColorLabel)
        brushColorLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(20)
            make.top.equalTo(brushSizeSlider.snp.bottom).offset(10)
            make.height.equalTo(brushSizeLabel)
        }

        let brushColorCollectionViewLayout = UICollectionViewFlowLayout()
        brushColorCollectionViewLayout.itemSize = .init(width: 50, height: 50)
        brushColorCollectionViewLayout.minimumInteritemSpacing = 10
        brushColorCollectionViewLayout.minimumLineSpacing = 10
        brushColorCollectionViewLayout.scrollDirection = .horizontal
        let brushColorCollectionView = UICollectionView(frame: .zero, collectionViewLayout: brushColorCollectionViewLayout)
        brushColorCollectionView.showsHorizontalScrollIndicator = false
        brushColorCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
        self.view.addSubview(brushColorCollectionView)
        brushColorCollectionView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.top.equalTo(brushColorLabel.snp.bottom).offset(10)
            make.height.equalTo(50)
        }
        brushColorCollectionView.delegate = self
        brushColorCollectionView.dataSource = self

        self.undoButton.setTitle(NSLocalizedString("MDGraffitiViewController.undo", comment: ""), for: .normal)
        self.undoButton.addTarget(self, action: #selector(undoButtonPressed(sender:)), for: .touchUpInside)
        self.view.addSubview(self.undoButton)

        self.redoButton.setTitle(NSLocalizedString("MDGraffitiViewController.redo", comment: ""), for: .normal)
        self.redoButton.addTarget(self, action: #selector(redoButtonPressed(sender:)), for: .touchUpInside)
        self.view.addSubview(self.redoButton)

        self.resetButton.setTitle(NSLocalizedString("MDGraffitiViewController.reset", comment: ""), for: .normal)
        self.resetButton.addTarget(self, action: #selector(resetButtonPressed(sender:)), for: .touchUpInside)
        self.view.addSubview(self.resetButton)

        self.clearAllButton.setTitle(NSLocalizedString("MDGraffitiViewController.clearall", comment: ""), for: .normal)
        self.clearAllButton.addTarget(self, action: #selector(clearButtonPressed(sender:)), for: .touchUpInside)
        self.view.addSubview(self.clearAllButton)

        self.undoButton.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.bottom.equalToSuperview()
            make.top.equalTo(brushColorCollectionView.snp.bottom).offset(20)
            make.right.equalTo(self.redoButton.snp.left).offset(-1)
            make.height.greaterThanOrEqualTo(40)
        }

        self.redoButton.snp.makeConstraints { (make) in
            make.width.equalTo(self.undoButton)
            make.right.equalTo(self.resetButton.snp.left).offset(-1)
            make.bottom.equalToSuperview()
            make.height.equalTo(self.undoButton)
        }

        self.resetButton.snp.makeConstraints { (make) in
            make.width.equalTo(self.undoButton)
            make.right.equalTo(self.clearAllButton.snp.left).offset(-1)
            make.bottom.equalToSuperview()
            make.height.equalTo(self.undoButton)
        }

        self.clearAllButton.snp.makeConstraints { (make) in
            make.width.equalTo(self.undoButton)
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(self.undoButton)
        }
        
        if self.graffitiManager.canUndo() {
            self.undoButton.isEnabled = true
        } else {
            self.undoButton.isEnabled = false
        }
        if self.graffitiManager.canRedo() {
            self.redoButton.isEnabled = true
        } else {
            self.redoButton.isEnabled = false
        }
    }
    
    deinit {
        self.graffitiManager.hideGraffitiView = true
        if let delegate = self.delegate {
            delegate.graffitiManagerController(graffitiManagerController: self, didGetGraffiti: self.graffitiManager.exportAsImageStickerEditorEffect())
        }
    }
    
    @objc func sliderValueChanged(sender: UISlider) {
        self.graffitiManager.brush.lineWidth = CGFloat(sender.value)
        if self.graffitiManager.brush.lineColor == .clear {
            let image = resize(image: UIImage(named: "eraser")!, to: .init(width: self.graffitiManager.brush.lineWidth, height: self.graffitiManager.brush.lineWidth))
            self.brushSizeSlider.setThumbImage(image, for: .normal)
            self.brushSizeSlider.setThumbImage(image, for: .highlighted)
        } else {
            let image = createThumbImage(with: self.graffitiManager.brush.lineWidth, color: self.graffitiManager.brush.lineColor)
            self.brushSizeSlider.setThumbImage(image, for: .normal)
            self.brushSizeSlider.setThumbImage(image, for: .highlighted)
        }
    }
    
    @objc func undoButtonPressed(sender: UIButton) {
        self.graffitiManager.undo()
    }
    
    @objc func redoButtonPressed(sender: UIButton) {
        self.graffitiManager.redo()
    }
    
    @objc func resetButtonPressed(sender: UIButton) {
        self.graffitiManager.reset()
    }
    
    @objc func clearButtonPressed(sender: UIButton) {
        self.graffitiManager.clear()
    }
}

extension MDVideoGraffitiViewController: MSVGraffitiManagerDelegate {
    func graffitiManagerUndoRedoStatusChanged(_ graffitiManager: MSVGraffitiManager) {
        if graffitiManager.canUndo() {
            self.undoButton.isEnabled = true
        } else {
            self.undoButton.isEnabled = false
        }
        if graffitiManager.canRedo() {
            self.redoButton.isEnabled = true
        } else {
            self.redoButton.isEnabled = false
        }
    }
}

extension MDVideoGraffitiViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.brushColors.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
        if indexPath.item == 0 {
            cell.backgroundColor = .clear
            cell.backgroundView = UIImageView(image: UIImage(named: "eraser"))
            cell.backgroundView?.frame = cell.bounds
        } else {
            cell.backgroundView = nil
            cell.backgroundColor = self.brushColors[indexPath.row - 1]
        }
        cell.layer.borderWidth = 1
        cell.layer.borderColor = UIColor.lightGray.cgColor
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            self.graffitiManager.brush.lineColor = .clear
            let image = resize(image: UIImage(named: "eraser")!, to: .init(width: self.graffitiManager.brush.lineWidth, height: self.graffitiManager.brush.lineWidth))
            self.brushSizeSlider.setThumbImage(image, for: .normal)
            self.brushSizeSlider.setThumbImage(image, for: .highlighted)
        } else {
            self.graffitiManager.brush.lineColor = self.brushColors[indexPath.row - 1]
            let image = createThumbImage(with: self.graffitiManager.brush.lineWidth, color: self.graffitiManager.brush.lineColor)
            self.brushSizeSlider.setThumbImage(image, for: .normal)
            self.brushSizeSlider.setThumbImage(image, for: .highlighted)
        }
    }
}

