//
//  MultipartSession.swift
//  ufile sdk demo
//
//  Created by wu shauk on 12/16/15.
//  Copyright © 2015 ucloud. All rights reserved.
//

import Foundation

class MultipartSession {
    var uploadId: String
    var blockSize: UInt
    var fileHandle: FileHandle?
    var key: String
    var fileSize: UInt
    var partsCount: UInt
    var etags: [String]
    
    init(uploadId: String, blockSize: UInt, filePath: String, key: String) {
        self.uploadId = uploadId
        self.blockSize = blockSize
        self.fileHandle = FileHandle(forReadingAtPath: filePath)
        self.key = key
        let attr = try! FileManager.default.attributesOfItem(atPath: filePath)
        self.fileSize = UInt((attr[FileAttributeKey.size] as! NSNumber).intValue)
        self.partsCount = (fileSize + blockSize - 1) / blockSize
        self.etags = [String](repeating: "", count: Int(partsCount))
    }
    
    deinit {
        fileHandle?.closeFile()
    }
    
    func getDataForPart(_ partNumber: UInt) -> Data? {
        if partNumber >= partsCount {
            return nil
        }
        let loc = partNumber * blockSize
        var length = blockSize
        let end = loc + length
        if end > fileSize {
            length = fileSize - loc
        }
        fileHandle?.seek(toFileOffset: UInt64(loc))
        return fileHandle?.readData(ofLength: Int(length))
    }
    
    func addEtag(_ partNumber: UInt, etag: String) {
        etags[Int(partNumber)] = etag
    }
 
    func outputEtags() -> String {
        return etags.joined(separator: ",")
    }
}
