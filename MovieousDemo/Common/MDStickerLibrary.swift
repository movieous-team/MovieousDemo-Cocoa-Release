//
//  MDStickerLibrary.swift
//  MovieousDemo
//
//  Created by Chris Wang on 2019/7/5.
//  Copyright © 2019 Movieous Team. All rights reserved.
//

import UIKit
import SSZipArchive

extension NSNotification.Name {
    public static let MDStickerLibraryRefreshDone: NSNotification.Name = .init("MDStickerLibraryRefreshDone")
    public static let MDStickerLibraryRefreshError: NSNotification.Name = .init("MDStickerLibraryRefreshError")
    public static let MDStickerDidUpdated: NSNotification.Name = .init("MDStickerDidUpdated")
}

let localStickerDir = "\(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])/movieous/stickers"

let MDStickerLibraryRefreshDoneKey = "MDStickerLibraryRefreshDoneKey"
let MDStickerLibraryRefreshErrorKey = "MDStickerLibraryRefreshErrorKey"
let MDStickerDidUpdatedKey = "MDStickerDidUpdatedKey"

class MDSticker: NSObject, URLSessionDownloadDelegate {
    enum StickerType: Int {
        case image  = 0b001
        case gif    = 0b010
        case images = 0b100
        case all    = 0b111
    }
    let sourceURL: URL
    let thumbnailURL: URL
    var type: StickerType
    var localPaths: [String]?
    var isDownLoading: Bool = false
    var progress: CGFloat = 0
    
    lazy var session: URLSession = {
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
        return session
    }()
    
    init(sourceURL: URL, thumbnailURL: URL, type: StickerType,  localPaths: [String]?) {
        self.sourceURL = sourceURL
        self.thumbnailURL = thumbnailURL
        self.type = type
        self.localPaths = localPaths
    }
    
    func download() {
        self.session.downloadTask(with: self.sourceURL).resume()
        self.isDownLoading = true
        NotificationCenter.default.post(name: .MDStickerDidUpdated, object: self, userInfo: [MDStickerDidUpdatedKey: self])
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        if self.type == .images {
            self.localPaths = []
            SSZipArchive.unzipFile(atPath: location.path, toDestination: "\(localStickerDir)/\(self.sourceURL.lastPathComponent)", delegate: self)
            self.localPaths = sortImagePaths(imagePaths: self.localPaths!)
            self.isDownLoading = false
            NotificationCenter.default.post(name: .MDStickerDidUpdated, object: self, userInfo: [MDStickerDidUpdatedKey: self])
        } else {
            do {
                let localPath = "\(localStickerDir)/\(self.sourceURL.lastPathComponent)"
                try FileManager.default.moveItem(atPath: location.path, toPath: localPath)
                self.localPaths = [localPath]
                self.isDownLoading = false
                NotificationCenter.default.post(name: .MDStickerDidUpdated, object: self, userInfo: [MDStickerDidUpdatedKey: self])
            } catch {
                ShowAlert(title: String(format: NSLocalizedString("MDStickerLibrary.moveformat", comment: ""), location.absoluteString, location.absoluteString), message: "", action: NSLocalizedString("MDStickerLibrary.ok", comment: ""), controller: UIApplication.shared.keyWindow!.rootViewController!)
                self.isDownLoading = false
                return
            }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        self.progress = CGFloat(totalBytesWritten) / CGFloat(totalBytesExpectedToWrite)
        NotificationCenter.default.post(name: .MDStickerDidUpdated, object: self, userInfo: [MDStickerDidUpdatedKey: self])
    }
}

extension MDSticker: SSZipArchiveDelegate {
    func zipArchiveDidUnzipFile(at fileIndex: Int, totalFiles: Int, archivePath: String, unzippedFilePath: String) {
        self.localPaths?.append(unzippedFilePath)
    }
}

class MDStickerLibrary: NSObject {
    static var stickers: [MDSticker] = []
    
    static func refreshStickers() {
        let serverURL = URL(string: "\(MDServerHost)/api/demo/stickers")!
        URLSession.shared.dataTask(with: serverURL) { (data: Data?, response: URLResponse?, error: Error?) in
            if let error = error {
                NotificationCenter.default.post(name: .MDStickerLibraryRefreshError, object: self, userInfo: [MDStickerLibraryRefreshErrorKey: error])
                return
            }
            if (response as! HTTPURLResponse).statusCode != 200 {
                NotificationCenter.default.post(name: .MDStickerLibraryRefreshError, object: self, userInfo: [MDStickerLibraryRefreshErrorKey: MDAudienceError.serverResponseError(desc: "\(NSLocalizedString("MDStickerLibrary.list.status.error", comment: ""))\((response as! HTTPURLResponse).statusCode)")])
                return
            }
            guard let data = data else {
                NotificationCenter.default.post(name: .MDStickerLibraryRefreshError, object: self, userInfo: [MDStickerLibraryRefreshErrorKey: MDAudienceError.serverResponseError(desc: NSLocalizedString("MDStickerLibrary.list.nodata.error", comment: ""))])
                return
            }
            
            do {
                let obj = try JSONSerialization.jsonObject(with: data) as? Array<Dictionary<String, String>>
                guard let array = obj else {
                    throw MDAudienceError.serverResponseError(desc: NSLocalizedString("MDStickerLibrary.list.invaliddata.error", comment: ""))
                }
                let fileManager = FileManager.default
                try fileManager.createDirectory(atPath: localStickerDir, withIntermediateDirectories: true, attributes: nil)
                let files = Set(try fileManager.contentsOfDirectory(atPath: localStickerDir))
                for element in array {
                    guard let sourceURLString = element["sourceURL"] else {
                        throw MDAudienceError.serverResponseError(desc: NSLocalizedString("MDStickerLibrary.list.invaliddata.error", comment: ""))
                    }
                    guard let sourceURL = URL(string: sourceURLString) else {
                        throw MDAudienceError.serverResponseError(desc: NSLocalizedString("MDStickerLibrary.list.invaliddata.error", comment: ""))
                    }
                    guard let thumbnailURLString = element["thumbnailURL"] else {
                        throw MDAudienceError.serverResponseError(desc: NSLocalizedString("MDStickerLibrary.list.invaliddata.error", comment: ""))
                    }
                    guard let thumbnailURL = URL(string: thumbnailURLString) else {
                        throw MDAudienceError.serverResponseError(desc: NSLocalizedString("MDStickerLibrary.list.invaliddata.error", comment: ""))
                    }
                    var type = MDSticker.StickerType.image
                    if let typeString = element["type"] {
                        if typeString == "gif" {
                            type = .gif
                        } else if typeString == "image" {
                            type = .image
                        } else if typeString == "images" {
                            type = .images
                        }
                    }
                    var found = false
                    for sticker in self.stickers {
                        if sticker.sourceURL.absoluteString == sourceURLString && sticker.thumbnailURL.absoluteString == thumbnailURLString {
                            found = true
                        }
                    }
                    if found {
                        continue
                    }
                    var localPaths: [String]?
                    if files.contains(sourceURL.lastPathComponent) {
                        if type == .images {
                            localPaths = sortImagePaths(imagePaths: try fileManager.contentsOfDirectory(atPath: "\(localStickerDir)/\(sourceURL.lastPathComponent)").map({ (original) -> String in
                                return "\(localStickerDir)/\(sourceURL.lastPathComponent)/\(original)"
                            }))
                        } else {
                            localPaths = ["\(localStickerDir)/\(sourceURL.lastPathComponent)"]
                        }
                    }
                    let sticker = MDSticker(sourceURL: sourceURL, thumbnailURL: thumbnailURL, type: type,  localPaths: localPaths)
                    self.stickers.append(sticker)
                }
            } catch {
                NotificationCenter.default.post(name: .MDStickerLibraryRefreshError, object: self, userInfo: [MDStickerLibraryRefreshErrorKey: error])
                return
            }
            NotificationCenter.default.post(name: .MDStickerLibraryRefreshDone, object: self, userInfo: [MDStickerLibraryRefreshDoneKey: stickers])
        }.resume()
    }
}
