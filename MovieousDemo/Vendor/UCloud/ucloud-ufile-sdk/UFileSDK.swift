//
//  UFileSDK.swift
//  ufile sdk demo
//
//  Created by wu shauk on 12/14/15.
//  Copyright © 2015 ucloud. All rights reserved.
//

import Foundation
import CommonCrypto

class UFileSDK {
    
    var ufileAPI: UFileAPI
    var bucket: String
    var publicKey: String
    var privateKey: String
    var session: MultipartSession?
    var isUploadError = false
    var uploadTasks = [URLSessionDataTask]()
    var progresses = [Double]()
    
    init(publicKey: String, privateKey: String, bucket: String) {
        //单区域空间上传域名，对应下载地址 http://{bucketname}.ufile.ucloud.cn/{filename}
        self.ufileAPI = UFileAPI(bucket:bucket, url:"http://ufile.ucloud.cn")
        //全球化空间上传域名，对应下载地址 http://{bucketname}.dl.ufileos.com/{filename}
        //self.ufileSDK = UFileAPI(bucket:bucket, url:"http://up.ufileos.com")
        self.bucket = bucket
        self.publicKey = publicKey;
        self.privateKey = privateKey;
    }
    
    func calcKey(_ httpMethod: String, key: String, contentMd5: String?, contentType: String?) -> String {
        var s = httpMethod + "\n";
        if let type = contentMd5 {
            s += type;
        }
        s += "\n";
        if let md5s = contentType {
            s += md5s;
        }
        s += "\n";
        // date
        s += "\n";
        // ucloud header
        s += "";
        s += "/" + bucket + "/" + key;
        return sha1Sum(privateKey, s: s)
    }
    
    func multipartUpload(URL: URL, contentType: String, progressHandler:((Double) -> Void)?, completionHandler:((String) -> Void)?, failureHandler:((Error) -> Void)?) {
        if let fileName = URL.pathComponents.last {
            let auth = calcKey("POST", key: fileName, contentMd5: nil, contentType: nil)
            weak var wSelf = self
            ufileAPI.multipartUploadStart(fileName, authorization: auth, success: {(result: [AnyHashable : Any]) in
                if let strongSelf = wSelf {
                    strongSelf.session = MultipartSession(uploadId: result[kUFileRespUploadId] as! String, blockSize: result[kUFileRespBlockSize] as! UInt, filePath: URL.path, key: fileName)
                    let auth = strongSelf.calcKey("PUT", key: strongSelf.session!.key, contentMd5: nil, contentType: contentType)
                    let option = [
                        kUFileSDKOptionTimeoutInterval: NSNumber(value: 5.0 as Double)
                    ]
                    var completionCount = 0
                    for i in 0..<strongSelf.session!.partsCount {
                        strongSelf.progresses.append(0)
                        let task = strongSelf.ufileAPI.multipartUploadPart(strongSelf.session!.key, uploadId: strongSelf.session!.uploadId, partNumber: Int(i), contentType: contentType, data: strongSelf.session!.getDataForPart(i)!, option: option, authorization: auth, progress: { (progress: Progress) in
                            strongSelf.progresses[Int(i)] = progress.fractionCompleted
                            if let handler = progressHandler {
                                let sum = strongSelf.progresses.reduce(Double(0), { (agg:Double, item:Double) -> Double in
                                    return agg + item
                                })
                                handler(sum / Double(strongSelf.session!.partsCount))
                            }
                        }, success: { (result: [AnyHashable : Any]) in
                            self.session!.addEtag(UInt(i), etag: result[kUFileRespETag] as! String)
                            completionCount += 1
                            if completionCount == strongSelf.session!.partsCount {
                                strongSelf.reset()
                                let auth = strongSelf.calcKey("POST", key: fileName, contentMd5: nil, contentType: contentType)
                                strongSelf.ufileAPI.multipartUploadFinish(strongSelf.session!.key, uploadId: strongSelf.session!.uploadId, newKey: strongSelf.session!.key, etags: strongSelf.session!.etags, contentType: contentType, authorization: auth, success: { (result: [AnyHashable : Any]) in
                                    if let completion = completionHandler {
                                        completion(fileName)
                                    }
                                }, failure: { (error: Error) in
                                    if let failure = failureHandler {
                                        failure(error)
                                    }
                                })
                            }
                        }, failure: { (error: Error) in
                            strongSelf.isUploadError = true
                            if strongSelf.isUploadError {
                                return
                            }
                            if let failure = failureHandler {
                                failure(error)
                            }
                            for task in strongSelf.uploadTasks {
                                task.cancel()
                            }
                            let auth = strongSelf.calcKey("DELETE", key: fileName, contentMd5: nil, contentType: nil)
                            strongSelf.ufileAPI.multipartUploadAbort(fileName, uploadId: strongSelf.session!.uploadId, authorization: auth, success: { (result: [AnyHashable : Any]) in
                                print("abort success");
                            }, failure: { (error: Error) in
                                print("abort fail");
                            })
                            strongSelf.reset()
                        })
                        strongSelf.uploadTasks.append(task!)
                    }
                }
            }, failure: { (error: Error) in
                if let failure = failureHandler {
                    failure(error)
                }
            })
        }
    }
    
    func reset() {
        isUploadError = false;
        uploadTasks.removeAll()
    }
    
    fileprivate func sha1Sum(_ key: String, s: String) -> String {
        let str = s.cString(using: String.Encoding.utf8)
        let strLen = Int(s.lengthOfBytes(using: String.Encoding.utf8))
        let digestLen = Int(CC_SHA1_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLen)
        let keyStr = key.cString(using: String.Encoding.utf8)
        let keyLen = Int(key.lengthOfBytes(using: String.Encoding.utf8))
        
        CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA1), keyStr!, keyLen, str!, strLen, result)
        
        let digest = stringFromResult(result, length: digestLen)
        
        result.deallocate()
        
        return "UCloud " + self.publicKey + ":" + digest;
    }
    
    fileprivate func stringFromResult(_ result: UnsafeMutablePointer<CUnsignedChar>, length: Int) -> String {
        let hash = Data(bytes: UnsafePointer<UInt8>(result), count: length);
        return hash.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
    }
}
