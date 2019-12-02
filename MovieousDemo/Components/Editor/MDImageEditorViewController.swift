//
//  MDImageEditorViewController.swift
//  MovieousDemo
//
//  Created by Chris Wang on 2019/8/24.
//  Copyright © 2019 Movieous Team. All rights reserved.
//

import UIKit
import MovieousShortVideo
import CoreImage

class MDImageSticker: NSObject {
    enum ImageStickerType {
        case sticker
        case graffiti
    }
    var image: UIImage
    var destRect: CGRect
    var rotation: CGFloat
    var type: ImageStickerType
    
    init(image: UIImage, destRect: CGRect, rotation: CGFloat, type: ImageStickerType) {
        self.image = image
        self.destRect = destRect
        self.rotation = rotation
        self.type = type
    }
}

class MDImageEditorViewController: UIViewController {
    var image: UIImage!
    let tools = [
        ["MDVideoEditorViewController.sticker", "sticker"],
        ["MDVideoEditorViewController.beauty", "face_beauty_set"],
        ["MDVideoEditorViewController.scrawl", "pencil"],
    ]
    var toolboxNavigationController: UINavigationController!
    let frameView = MDFrameView()
    let deleteStickerButton = UIButton(type: .custom)
    lazy var tapGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped(sender:)))
    lazy var panGestureRecognizer: UIPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panned(sender:)))
    lazy var pinchGestureRecognizer: UIPinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinched(sender:)))
    lazy var rotationGestureRecognizer: UIRotationGestureRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(rotated(sender:)))
    var lastTranslation: CGPoint?
    var lastScale: CGFloat?
    var lastRotation: CGFloat?
    var graffitiView = MSVGraffitiView()
    let imageView = UIImageView()
    var contentFrame: CGRect {
        get {
            let imageSize = self.image.size
            let viewAspect = self.imageView.frame.size.width / self.imageView.frame.size.height
            let contentAspect = imageSize.width / imageSize.height
            if contentAspect > viewAspect {
                let width = self.imageView.frame.size.width
                let height = width / contentAspect
                return CGRect(x: 0, y: (self.imageView.frame.size.height - height) / 2, width: width, height: height)
            } else {
                let height = self.imageView.frame.size.height
                let width = height * contentAspect
                return CGRect(x: (self.imageView.frame.size.width - width) / 2, y: 0, width: width, height: height)
            }
        }
    }
    var imageStickers: [MDImageSticker] = []
    var previeousSelectedStickerIndex: Int = -1
    var previeousGraffitiIndex: Int = -1
    var selectedImageView = UIImageView()
    var selectedImageSticker: MDImageSticker?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.buildUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = false
        self.navigationController?.setTransparent(transparent: true)
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        self.updateImageView()
    }
    
    func buildUI() {
        self.view.backgroundColor = .black
        self.navigationController?.navigationBar.tintColor = .white
        
        let nextButton = MDButton()
        nextButton.titleLabel?.font = .systemFont(ofSize: 12)
        nextButton.addTarget(self, action: #selector(nextButtonPressed(sender:)), for: .touchUpInside)
        nextButton.frame = CGRect(x: 0, y: 0, width: 63, height: 26)
        nextButton.setTitle(NSLocalizedString("MDVideoEditorViewController.next", comment: ""), for: .normal)
        
        self.navigationItem.rightBarButtonItem = .init(customView: nextButton)
        
        let toolboxViewController = MDEditorToolboxViewController()
        toolboxViewController.delegate = self
        toolboxViewController.tools = self.tools
        self.toolboxNavigationController = UINavigationController(rootViewController: toolboxViewController)
        self.toolboxNavigationController?.interactivePopGestureRecognizer?.isEnabled = false
        self.toolboxNavigationController.navigationBar.tintColor = .white
        self.toolboxNavigationController.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        self.toolboxNavigationController.setTransparent(transparent: true)
        self.toolboxNavigationController.delegate = self
        self.view.addSubview(self.toolboxNavigationController.view)
        
        self.imageView.isUserInteractionEnabled = true
        self.imageView.contentMode = .scaleAspectFit
        self.view.addSubview(self.imageView)
        
        self.graffitiView.brush = .init(lineWidth: 10, lineColor: .white)
        self.graffitiView.isHidden = true
        self.imageView.addSubview(self.graffitiView)
        
        self.frameView.isHidden = true
        self.frameView.frameWidth = 2
        self.frameView.margin = MDDeleteButtonWidth / 2
        self.imageView.addSubview(self.frameView)
        
        self.deleteStickerButton.bounds = .init(x: 0, y: 0, width: MDDeleteButtonWidth, height: MDDeleteButtonWidth)
        self.deleteStickerButton.setImage(UIImage(named: "delete"), for: .normal)
        self.deleteStickerButton.addTarget(self, action: #selector(deleteStickerButtonPressed(sender:)), for: .touchUpInside)
        self.frameView.addSubview(self.deleteStickerButton)
        
        self.selectedImageView.contentMode = .scaleAspectFit
        self.imageView.addSubview(self.selectedImageView)
        
        self.tapGestureRecognizer.delegate = self
        self.tapGestureRecognizer.cancelsTouchesInView = false
        self.imageView.addGestureRecognizer(self.tapGestureRecognizer)
        
        self.panGestureRecognizer.delegate = self
        self.panGestureRecognizer.cancelsTouchesInView = false
        self.imageView.addGestureRecognizer(self.panGestureRecognizer)
        
        self.pinchGestureRecognizer.delegate = self
        self.pinchGestureRecognizer.cancelsTouchesInView = false
        self.imageView.addGestureRecognizer(self.pinchGestureRecognizer)
        
        self.rotationGestureRecognizer.delegate = self
        self.rotationGestureRecognizer.cancelsTouchesInView = false
        self.imageView.addGestureRecognizer(self.rotationGestureRecognizer)
        
        self.toolboxNavigationController.view.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(240)
        }
        
        self.imageView.snp.makeConstraints { (make) in
            make.top.equalTo(topLayoutGuide.snp.bottom)
            make.bottom.equalTo(self.toolboxNavigationController.view.snp_top)
            make.right.equalToSuperview()
            make.left.equalToSuperview()
        }
        
        // contentFrame 与 editor.preview 的 frame 有关，因此需要等到 self.editor.preview 的 frame 初始化完成之后再获取
        DispatchQueue.main.async {
            let contentFrame = self.contentFrame
            
            self.graffitiView.snp.makeConstraints { (make) in
                make.left.equalToSuperview().offset(contentFrame.origin.x)
                make.top.equalToSuperview().offset(contentFrame.origin.y)
                make.width.equalTo(contentFrame.size.width)
                make.height.equalTo(contentFrame.size.height)
            }
        }
    }
    
    @objc func nextButtonPressed(sender: UIBarButtonItem) {
        let vc = MDExporterViewController()
        var image = self.imageView.image!
        if let ciImage = image.ciImage {
            let context = CIContext(options: nil)
            image = UIImage(cgImage: context.createCGImage(ciImage, from: .init(origin: .zero, size: self.image.size))!)
        }
        vc.image = image
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func tapped(sender: UITapGestureRecognizer) {
        // 进入相应的工具箱才能调整相关的
        if !self.toolboxNavigationController.topViewController!.isKind(of: MDStickerViewController.self) {
            return
        }
        let location = sender.location(in: self.imageView)
        if self.frameView.convert(self.deleteStickerButton.frame, to: self.imageView).contains(location) {
            return
        }
        let imageSize = self.image.size
        let contentFrame = self.contentFrame
        if self.imageStickers.count > 0 {
            for var i in (0...self.imageStickers.count - 1).reversed() {
                var destRect: CGRect!
                var rotation: CGFloat!
                let imageSticker = self.imageStickers[i]
                if imageSticker.type != .sticker {
                    continue
                }
                destRect = imageSticker.destRect
                rotation = imageSticker.rotation

                let imageStickerFrame = CGRect(x: contentFrame.origin.x + destRect.origin.x / imageSize.width * contentFrame.size.width, y: contentFrame.origin.y + destRect.origin.y / imageSize.width * contentFrame.size.width, width: destRect.size.width / imageSize.width * contentFrame.size.width, height: destRect.size.height / imageSize.height * contentFrame.size.height)
                if imageStickerFrame.contains(location) {
                    // 将贴纸移除图像渲染
                    self.imageStickers.remove(at: i)
                    // 处理之前选择过贴纸的情况下当前选中贴纸切换的逻辑
                    if self.previeousSelectedStickerIndex >= 0 {
                        if self.previeousSelectedStickerIndex > i {
                            self.previeousSelectedStickerIndex -= 1
                        } else {
                            i += 1
                        }
                    }
                    self.syncToImageSticker(imageSize: imageSize)
                    self.previeousSelectedStickerIndex = i
                    self.selectedImageSticker = imageSticker
                    self.selectedImageView.image = imageSticker.image
                    self.selectedImageView.bounds = .init(x: 0, y: 0, width: imageStickerFrame.size.width, height: imageStickerFrame.size.height)
                    self.selectedImageView.center = .init(x: imageStickerFrame.midX, y: imageStickerFrame.midY)
                    self.selectedImageView.transform = CGAffineTransform(rotationAngle: rotation)
                    self.selectedImageView.isHidden = false
                    self.frameView.bounds = .init(x: 0, y: 0, width: imageStickerFrame.size.width + 2 * MDFrameViewMargin + self.frameView.margin, height: imageStickerFrame.size.height + 2 * MDFrameViewMargin + self.frameView.margin)
                    self.frameView.center = .init(x: imageStickerFrame.midX, y: imageStickerFrame.midY)
                    self.frameView.transform = CGAffineTransform(rotationAngle: rotation)
                    self.frameView.isHidden = false
                    self.deleteStickerButton.center = .init(x: self.frameView.bounds.size.width - self.frameView.margin - self.frameView.frameWidth / 2, y: self.frameView.margin + self.frameView.frameWidth / 2)
                    return
                }
            }
        }
        self.syncToImageSticker(imageSize: imageSize)
        self.previeousSelectedStickerIndex = -1
        self.selectedImageView.isHidden = true
        self.selectedImageSticker = nil
        self.frameView.isHidden = true
    }
    
    // 将当前选中的图片贴纸同步到贴纸渲染管线当中
    func syncToImageSticker(imageSize: CGSize) {
        if let selectedImageSticker = self.selectedImageSticker {
            let center = self.selectedImageView.center
            let size = self.selectedImageView.bounds.size
            selectedImageSticker.destRect = .init(x: (center.x - contentFrame.origin.x - size.width / 2) / contentFrame.size.width * imageSize.width, y: (center.y - contentFrame.origin.y - size.height / 2) / contentFrame.size.height * imageSize.height, width: size.width / contentFrame.size.width * imageSize.width, height: size.height / contentFrame.size.height * imageSize.height)
            selectedImageSticker.rotation = atan2(self.selectedImageView.transform.b, self.selectedImageView.transform.a)
            self.imageStickers.insert(selectedImageSticker, at: self.previeousSelectedStickerIndex)
        }
        self.updateImageView()
    }
    
    @objc func panned(sender: UIPanGestureRecognizer) {
        if self.selectedImageSticker == nil {
            return
        }
        let location = sender.location(in: self.imageView)
        if sender.state == .began {
            if self.frameView.frame.contains(location) {
                self.lastTranslation = sender.translation(in: self.imageView)
            } else {
                self.lastTranslation = nil
            }
        } else {
            guard let lastTranslation = self.lastTranslation else {
                return
            }
            let translation = sender.translation(in: self.imageView)
            let translationDelta = CGPoint(x: translation.x - lastTranslation.x, y: translation.y - lastTranslation.y)
            self.lastTranslation = translation
            self.selectedImageView.center = .init(x: self.frameView.center.x + translationDelta.x, y: self.frameView.center.y + translationDelta.y)
            self.frameView.center = .init(x: self.frameView.center.x + translationDelta.x, y: self.frameView.center.y + translationDelta.y)
            self.deleteStickerButton.center = .init(x: self.frameView.bounds.size.width - self.frameView.margin - self.frameView.frameWidth / 2, y: self.frameView.margin + self.frameView.frameWidth / 2)
        }
    }
    
    @objc func pinched(sender: UIPinchGestureRecognizer) {
        if self.selectedImageSticker == nil {
            return
        }
        if sender.state == .began {
            self.lastScale = 1
        } else {
            guard let lastScale = self.lastScale else {
                return
            }
            let deltaScale = sender.scale / lastScale
            self.lastScale = sender.scale
            let frameMargin = 2 * MDFrameViewMargin + self.frameView.margin
            self.frameView.bounds = .init(x: 0, y: 0, width: (self.frameView.bounds.size.width - frameMargin) * deltaScale + frameMargin, height: (self.frameView.bounds.size.height - frameMargin) * deltaScale + frameMargin)
            self.selectedImageView.bounds = .init(x: 0, y: 0, width: self.selectedImageView.bounds.size.width * deltaScale, height: self.selectedImageView.bounds.size.height * deltaScale)
            self.deleteStickerButton.center = .init(x: self.frameView.bounds.size.width - self.frameView.margin - self.frameView.frameWidth / 2, y: self.frameView.margin + self.frameView.frameWidth / 2)
        }
    }
    
    @objc func rotated(sender: UIRotationGestureRecognizer) {
        if self.selectedImageSticker == nil {
            return
        }
        if sender.state == .began {
            self.lastRotation = 0
        } else {
            guard let lastRotation = self.lastRotation else {
                return
            }
            let deltaRotation = sender.rotation - lastRotation
            self.lastRotation = sender.rotation
            self.frameView.transform = self.frameView.transform.concatenating(CGAffineTransform(rotationAngle: deltaRotation))
            self.selectedImageView.transform = self.frameView.transform.concatenating(CGAffineTransform(rotationAngle: deltaRotation))
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    @objc func deleteStickerButtonPressed(sender: UIButton) {
        self.selectedImageView.isHidden = true
        self.selectedImageSticker = nil
        self.frameView.isHidden = true
    }
    
    func updateImageView() {
        var ciImage = CIImage(cgImage: self.image.cgImage!)
        for imageSticker in self.imageStickers {
            var stickerImage = CIImage(cgImage: imageSticker.image.cgImage!)
            let destRect = CGRect(origin: .init(x: imageSticker.destRect.origin.x, y: self.image.size.height - imageSticker.destRect.origin.y - imageSticker.destRect.size.height), size: imageSticker.destRect.size)
            stickerImage = place(image: stickerImage, to: destRect, rotation: imageSticker.rotation)
            let filter = CIFilter(name: "CISourceOverCompositing", parameters: [
                "inputImage": stickerImage,
                "inputBackgroundImage": ciImage
                ])!
            ciImage = filter.outputImage!
        }
        ciImage = ciImage.cropped(to: .init(origin: .zero, size: self.image.size))
        let uiImage = UIImage(ciImage: ciImage)
        self.imageView.image = uiImage
    }
}

extension MDImageEditorViewController: MDEditorToolboxViewControllerDelegate {
    func editorToolboxViewController(editorToolboxViewController: MDEditorToolboxViewController, didSelectedItemAt index: Int) {
        switch index {
        case 0:
            let viewController = MDStickerViewController()
            viewController.delegate = self
            viewController.stickerType = .image
            self.toolboxNavigationController.pushViewController(viewController, animated: true)
        case 1:
            ShowAlert(title: NSLocalizedString("global.alert", comment: ""), message: NSLocalizedString("global.vendornobeauty", comment: ""), action: NSLocalizedString("global.ok", comment: ""), controller: self)
        case 2:
            self.previeousGraffitiIndex = -1
            for i in 0 ..< self.imageStickers.count {
                let sticker = self.imageStickers[i]
                if sticker.type == .graffiti {
                    self.previeousGraffitiIndex = i
                }
            }
            if self.previeousGraffitiIndex >= 0 {
                self.imageStickers.remove(at: self.previeousGraffitiIndex)
            }
            self.updateImageView()
            let viewController = MDImageGraffitiViewController()
            viewController.delegate = self
            viewController.graffitiView = self.graffitiView
            viewController.snapshotSize = self.image.size
            self.toolboxNavigationController.pushViewController(viewController, animated: true)
        default:
            break
        }
    }
}

extension MDImageEditorViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

extension MDImageEditorViewController: MDStickerViewControllerDelegate {
    func stickerViewController(stickerViewController: MDStickerViewController, didSelectSticker sticker: MDSticker) {
        let image = UIImage(contentsOfFile: sticker.localPaths![0])!
        let sticker = MDImageSticker(image: image, destRect: .init(x: self.image.size.width - image.size.width, y: 0, width: image.size.width, height: image.size.height), rotation: 0, type: .sticker)
        self.imageStickers.append(sticker)
        self.updateImageView()
    }
}

extension MDImageEditorViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        if !viewController.isKind(of: MDStickerViewController.self) {
            self.syncToImageSticker(imageSize: self.image.size)
            self.selectedImageSticker = nil
            self.selectedImageView.isHidden = true
            self.frameView.isHidden = true
        }
    }
}

extension MDImageEditorViewController: MDImageGraffitiViewControllerDelegate {
    func graffitiViewController(graffitiViewController: MDImageGraffitiViewController, didGetGraffiti snapshot: UIImage) {
        let sticker = MDImageSticker(image: snapshot, destRect: .init(x: 0, y: 0, width: self.image.size.width, height: self.image.size.height), rotation: 0, type: .graffiti)
        if self.previeousGraffitiIndex >= 0 {
            self.imageStickers.insert(sticker, at: self.previeousGraffitiIndex)
        } else {
            self.imageStickers.append(sticker)
        }
        self.updateImageView()
    }
}

extension MDImageEditorViewController: MDBeautyFilterViewControllerDelegate {
    func beautyFilterViewController(beautyParamDidChange beautyFilterViewController: MDBeautyFilterViewController) {
        self.updateImageView()
    }
}
