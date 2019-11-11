//
//  MDMusicLibrary.swift
//  MovieousDemo
//
//  Created by Chris Wang on 2019/7/5.
//  Copyright © 2019 Movieous Team. All rights reserved.
//

import UIKit

extension NSNotification.Name {
    public static let MDMusicLibraryRefreshDone: NSNotification.Name = .init("MDMusicLibraryRefreshDone")
    public static let MDMusicLibraryRefreshError: NSNotification.Name = .init("MDMusicLibraryRefreshError")
    public static let MDMusicDidUpdated: NSNotification.Name = .init("MDMusicDidUpdated")
}

let localMusicDir = "\(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])/movieous/musics"

let MDMusicLibraryRefreshDoneKey = "MDMusicLibraryRefreshDoneKey"
let MDMusicLibraryRefreshErrorKey = "MDMusicLibraryRefreshErrorKey"
let MDMusicDidUpdatedKey = "MDMusicDidUpdatedKey"

class MDMusic: NSObject, URLSessionDownloadDelegate {
    let sourceURL: URL
    let coverURL: URL
    let name: String
    let author: String
    var localPath: String?
    var isDownLoading: Bool = false
    var progress: CGFloat = 0
    
    lazy var session: URLSession = {
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
        return session
    }()
    
    init(sourceURL: URL, coverURL: URL, name: String, author: String, localPath: String?) {
        self.sourceURL = sourceURL
        self.coverURL = coverURL
        self.name = name
        self.author = author
        self.localPath = localPath
    }
    
    func download() {
        if self.localPath == nil {
            self.session.downloadTask(with: self.sourceURL).resume()
            self.isDownLoading = true
        }
        NotificationCenter.default.post(name: .MDMusicDidUpdated, object: self, userInfo: [MDMusicDidUpdatedKey: self])
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let localPath = "\(localMusicDir)/\(self.sourceURL.lastPathComponent)"
        do {
            try FileManager.default.moveItem(atPath: location.path, toPath: localPath)
            self.localPath = localPath
            self.isDownLoading = false
            NotificationCenter.default.post(name: .MDMusicDidUpdated, object: self, userInfo: [MDMusicDidUpdatedKey: self])
        } catch {
            self.isDownLoading = false
            return
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        self.progress = CGFloat(totalBytesWritten) / CGFloat(totalBytesExpectedToWrite)
        NotificationCenter.default.post(name: .MDMusicDidUpdated, object: self, userInfo: [MDMusicDidUpdatedKey: self])
    }
}

class MDMusicLibrary: NSObject {
    static var musics: [MDMusic] = []
    
    static func refreshMusics() {
        let serverURL = URL(string: "\(MDServerHost)/api/demo/musics")!
        URLSession.shared.dataTask(with: serverURL) { (data: Data?, response: URLResponse?, error: Error?) in
            if let error = error {
                NotificationCenter.default.post(name: .MDMusicLibraryRefreshError, object: self, userInfo: [MDMusicLibraryRefreshErrorKey: error])
                return
            }
            if (response as! HTTPURLResponse).statusCode != 200 {
                NotificationCenter.default.post(name: .MDMusicLibraryRefreshError, object: self, userInfo: [MDMusicLibraryRefreshErrorKey: MDAudienceError.serverResponseError(desc: "\(NSLocalizedString("MDMusicLibrary.list.status.error", comment: ""))\((response as! HTTPURLResponse).statusCode)")])
                return
            }
            guard let data = data else {
                NotificationCenter.default.post(name: .MDMusicLibraryRefreshError, object: self, userInfo: [MDMusicLibraryRefreshErrorKey: MDAudienceError.serverResponseError(desc: NSLocalizedString("MDMusicLibrary.list.nodata.error", comment: ""))])
                return
            }
            
            do {
                let obj = try JSONSerialization.jsonObject(with: data) as? Array<Dictionary<String, String>>
                guard let array = obj else {
                    throw MDAudienceError.serverResponseError(desc: NSLocalizedString("MDMusicLibrary.list.invaliddata.error", comment: ""))
                }
                let fileManager = FileManager.default
                try fileManager.createDirectory(atPath: localMusicDir, withIntermediateDirectories: true, attributes: nil)
                let files = Set(try fileManager.contentsOfDirectory(atPath: localMusicDir))
                for element in array {
                    guard let sourceURLString = element["sourceURL"] else {
                        throw MDAudienceError.serverResponseError(desc: NSLocalizedString("MDMusicLibrary.list.invaliddata.error", comment: ""))
                    }
                    guard let sourceURL = URL(string: sourceURLString) else {
                        throw MDAudienceError.serverResponseError(desc: NSLocalizedString("MDMusicLibrary.list.invaliddata.error", comment: ""))
                    }
                    guard let coverURLString = element["coverURL"] else {
                        throw MDAudienceError.serverResponseError(desc: NSLocalizedString("MDMusicLibrary.list.invaliddata.error", comment: ""))
                    }
                    guard let coverURL = URL(string: coverURLString) else {
                        throw MDAudienceError.serverResponseError(desc: NSLocalizedString("MDMusicLibrary.list.invaliddata.error", comment: ""))
                    }
                    guard let name = element["name"] else {
                        throw MDAudienceError.serverResponseError(desc: NSLocalizedString("MDMusicLibrary.list.invaliddata.error", comment: ""))
                    }
                    guard let author = element["author"] else {
                        throw MDAudienceError.serverResponseError(desc: NSLocalizedString("MDMusicLibrary.list.invaliddata.error", comment: ""))
                    }
                    var found = false
                    for music in self.musics {
                        if music.sourceURL.absoluteString == sourceURLString && music.name == name && music.author == author {
                            found = true
                        }
                    }
                    if found {
                        continue
                    }
                    var localPath: String?
                    if files.contains(sourceURL.lastPathComponent) {
                        localPath = "\(localMusicDir)/\(sourceURL.lastPathComponent)"
                    }
                    let music = MDMusic(sourceURL: sourceURL, coverURL: coverURL, name: name, author: author, localPath: localPath)
                    self.musics.append(music)
                }
            } catch {
                NotificationCenter.default.post(name: .MDMusicLibraryRefreshError, object: self, userInfo: [MDMusicLibraryRefreshErrorKey: error])
                return
            }
            NotificationCenter.default.post(name: .MDMusicLibraryRefreshDone, object: self, userInfo: [MDMusicLibraryRefreshDoneKey: musics])
            }.resume()
    }
}
