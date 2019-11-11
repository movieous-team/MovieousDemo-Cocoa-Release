//
//  MDUtils.swift
//  MovieousDemo
//
//  Created by Chris Wang on 2019/4/9.
//  Copyright © 2019 Movieous Team. All rights reserved.
//

import UIKit
import MovieousShortVideo

extension UIImage {
    static func from(color: UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context!.setFillColor(color.cgColor)
        context!.fill(rect)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img!
    }
    
    func createPixelBuffer() -> CVPixelBuffer? {
        let image = self.cgImage!
        let frameSize = CGSize(width: image.width, height: image.height)
        
        var pixelBuffer:CVPixelBuffer? = nil
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(frameSize.width), Int(frameSize.height), kCVPixelFormatType_32BGRA , nil, &pixelBuffer)
        
        if status != kCVReturnSuccess {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags.init(rawValue: 0))
        let data = CVPixelBufferGetBaseAddress(pixelBuffer!)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue)
        let context = CGContext(data: data, width: Int(frameSize.width), height: Int(frameSize.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: bitmapInfo.rawValue)
        
        
        context?.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        return pixelBuffer
    }
}

extension UIView {
    func snapshot() -> UIImage {
        return self.snapshot(with: self.frame.size)
    }
    
    func snapshot(with size: CGSize) -> UIImage {
        // 避免因为 hidden 导致截到空的图片
        let hidden = self.isHidden;
        let frame = self.frame
        self.isHidden = false;
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        self.frame = CGRect(origin: .zero, size: size)
        self.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        self.isHidden = hidden
        self.frame = frame
        return image
    }
}

extension UIColor {
    convenience init(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        self.init(red: r / 255.0, green: g / 255.0, blue: b / 255.0, alpha: a)
    }
}

extension CVPixelBuffer {
    func createCIImage() -> CIImage {
        return CIImage(cvPixelBuffer: self)
    }
}

extension UINavigationController {
    func setTransparent(transparent: Bool) {
        if transparent {
            self.navigationBar.setBackgroundImage(UIImage(), for: .default)
            self.navigationBar.shadowImage = UIImage()
            self.navigationBar.isTranslucent = true
            self.view.backgroundColor = .clear
        } else {
            self.navigationBar.setBackgroundImage(nil, for: .default)
            self.navigationBar.shadowImage = nil
            self.navigationBar.isTranslucent = false
            self.view.backgroundColor = nil
        }
    }
}

func ShowAlert(title: String, message: String, action: String, controller: UIViewController) {
    DispatchQueue.main.async {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: action, style: .default, handler: nil))
        controller.present(alertController, animated: true, completion: nil)
    }
}

func ShowErrorAlert(error: Error, controller: UIViewController) {
    ShowAlert(title: NSLocalizedString("global.error", comment: ""), message: error.localizedDescription, action: NSLocalizedString("global.ok", comment: ""), controller: controller)
}

func createThumbImage(with diameter: CGFloat, color: UIColor) -> UIImage {
    UIGraphicsBeginImageContextWithOptions(.init(width: diameter, height: diameter), false, UIScreen.main.scale)
    let context = UIGraphicsGetCurrentContext()
    context?.setFillColor(UIColor.lightGray.cgColor)
    context?.fillEllipse(in: .init(x: 0, y: 0, width: diameter, height: diameter))
    context?.setFillColor(color.cgColor)
    context?.fillEllipse(in: .init(x: 1, y: 1, width: diameter - 2, height: diameter - 2))
    let image = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()
    return image
}

func resize(image: UIImage, to size: CGSize) -> UIImage {
    UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
    image.draw(in: .init(x: 0, y: 0, width: size.width, height: size.height))
    let retImage = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()
    return retImage
}

func place(image: CIImage, to rect: CGRect, rotation: CGFloat) -> CIImage {
    let extent = image.extent
    var transform = CGAffineTransform(translationX: -extent.midX, y: -extent.midY)
    transform = transform.concatenating(.init(scaleX: rect.size.width / extent.size.width, y: rect.size.height / extent.size.height))
    transform = transform.concatenating(.init(rotationAngle: -rotation))
    transform = transform.concatenating(.init(translationX: rect.midX, y: rect.midY))
    return image.transformed(by: transform)
}

func sortImagePaths(imagePaths: [String]) -> [String] {
    imagePaths.sorted { (imagePath1, imagePath2) -> Bool in
        return getImageIndex(imagePath1) < getImageIndex(imagePath2)
    }
}

func getImageIndex(_ imagePath: String) -> Int {
    let segments1 = imagePath.split(separator: "_")
    if segments1.count < 2 {
        return 0
    }
    let segments2 = segments1[1].split(separator: ".")
    if segments2.count < 2 {
        return 0
    }
    return (segments2[0] as NSString).integerValue
}
