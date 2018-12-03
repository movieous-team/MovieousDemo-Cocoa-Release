//
//  UFileAPI+Private.h
//  ufilesdk
//
//  Created by wu shauk on 12/11/15.
//  Copyright © 2015 ucloud. All rights reserved.
//

#ifndef UFileAPI_Private_h
#define UFileAPI_Private_h

#import <Foundation/Foundation.h>
/**
 * Error dommains
 */
/**
 * API错误
 * code既是API的RetCode
 * userInfo {@"ErrMsg": 服务器返回的错误码, @"x-session": X-Session-ID}
 */
FOUNDATION_EXPORT NSString * _Nonnull const kUFileSDKAPIErrorDomain;

/**
 * 网络错误
 * code是原始错误的code
 * userInfo是原始的错误
 */
FOUNDATION_EXPORT NSString * _Nonnull const kUFileSDKHttpErrorDomain;

/**
 * UFile SDK的option的定义
 */
/**
 * 上传文件的File Type(Content-Type), 例如application/jpeg
 */
FOUNDATION_EXPORT NSString * _Nonnull const kUFileSDKOptionFileType;
/**
 * 下载文件时候指定的Range, 例如 1-100
 */
FOUNDATION_EXPORT NSString * _Nonnull const kUFileSDKOptionRange;
/**
 * 下载文件时候查看的时间戳
 */
FOUNDATION_EXPORT NSString * _Nonnull const kUFileSDKOptionModifiedSince;
/**
 * 上传文件的MD5值
 */
FOUNDATION_EXPORT NSString * _Nonnull const kUFileSDKOptionMD5;
/**
 * 上传文件的Timeout Interval
 * 具体含义参见 NSURLRequest的timeout inteval，默认为60s
 */
FOUNDATION_EXPORT NSString * _Nonnull const kUFileSDKOptionTimeoutInterval;


/**
 * UFile SDK的结果的参数
 */

/**
 * 文件类型
 */
FOUNDATION_EXPORT NSString * _Nonnull const kUFileRespFileType;
/**
 * ETAG
 */
FOUNDATION_EXPORT NSString * _Nonnull const kUFileRespETag;
/**
 * 文件大小
 */
FOUNDATION_EXPORT NSString * _Nonnull const kUFileRespLength;

/**
 * 分段上传的ID
 */
FOUNDATION_EXPORT NSString* _Nonnull const kUFileRespUploadId;
/**
 * 分段上传的Block Size
 */
FOUNDATION_EXPORT NSString* _Nonnull const kUFileRespBlockSize;
/**
 * 分段上传的bucket名字
 */
FOUNDATION_EXPORT NSString* _Nonnull const kUFileRespBucketName;
/**
 * 分段上传的key
 */
FOUNDATION_EXPORT NSString* _Nonnull const kUFileRespKeyName;
/**
 * 错误内容
 */
FOUNDATION_EXPORT NSString* _Nonnull const kUFileRespErrMsg;
/**
 * Http Code
 */
FOUNDATION_EXPORT NSString* _Nonnull const kUFileRespHttpStatusCode;
/**
 * X-Session
 */
FOUNDATION_EXPORT NSString* _Nonnull const kUFileRespXSession;


typedef void (^ UFileProgressCallback)(NSProgress * _Nonnull);
typedef void (^ UFileUploadDoneCallback)(NSDictionary* _Nonnull response);
typedef void (^ UFileDownloadDoneCallback)(NSDictionary* _Nonnull response, id _Nonnull responseObject);
typedef void (^ UFileOpDoneCallback)(NSDictionary* _Nonnull response);
typedef void (^ UFileOpFailCallback)(NSError * _Nonnull error);

@interface UFileAPI : NSObject

/**
 * 初始化UFILE API
 * 需要传入对应bucket
 * 使用默认的API接口，http://{bucket}.ufilesec.ucloud.cn
 */
- (nonnull instancetype)initWithBucket:(NSString* _Nonnull)bucket;

- (nonnull instancetype)initWithBucket:(nonnull NSString *)bucket url:(nonnull NSString*)url;

/**
 * 上传文件到指定的key
 * @param key UFILE中的key值
 * @param authorization 签名
 * @param option 一些可选的参数，支持kUFileSDKOptionFileType, kUFileSDKOptionMD5
 * @param data 数据
 * @param progress 进度回调
 * @param success 成功回调, 回调函数的参数里面包含kUFileRespETag
 * @param failure 失败回调，回调函数的参数里面包含kUFileRespXSession
 */
- (NSURLSessionDataTask * _Nullable ) putFile:(NSString* _Nonnull)key
                                authorization:(NSString* _Nonnull)authorization
                                       option:(NSDictionary* _Nullable)option
                                         data:(NSData* _Nonnull)data
                                     progress:(UFileProgressCallback _Nullable)uploadProgress
                                      success:(UFileUploadDoneCallback _Nonnull)success
                                      failure:(UFileOpFailCallback _Nonnull)failure;


/**
 * 快速上传文件
 * @param key UFILE中的key值
 * @param authorization 签名
 * @param fileSize 文件大小
 * @param fileHash 文件的etag值
 * @param success 成功回调, 回调函数的参数里面包含kUFileRespETag
 * @param failure 失败回调，回调函数的参数里面包含kUFileRespXSession
 */
- (NSURLSessionDataTask * _Nullable ) uploadHit:(NSString* _Nonnull)key
                                  authorization:(NSString* _Nonnull)authorization
                                       fileSize:(NSInteger)fileSize
                                       fileHash:(NSString* _Nonnull)fileHash
                                        success:(UFileUploadDoneCallback _Nonnull)success
                                        failure:(UFileOpFailCallback _Nonnull)failure;

/**
 * 下载对应Key的文件
 * @param key UFILE中的key值
 * @param authorization 签名
 * @param option 一些可选的参数，支持kUFileSDKOptionModifiedSince, kUFileSDKOptionRange
 * @param progress 进度回调
 * @param success 成功回调, 回调函数的参数里面包含kUFileRespETag
 * @param failure 失败回调，回调函数的参数里面包含kUFileRespXSession
 */
- (NSURLSessionDataTask * _Nullable ) getFile:(NSString* _Nonnull)key
                                authorization:(NSString* _Nonnull)authorization
                                       option:(NSDictionary* _Nullable)option
                                     progress:(UFileProgressCallback _Nullable)downloadProgress
                                      success:(UFileDownloadDoneCallback _Nonnull)success
                                      failure:(UFileOpFailCallback _Nonnull)failure;


/**
 * 下载对应Key的文件
 * @param key UFILE中的key值
 * @param fileName 保存到的本地的文件路径
 * @param authorization 签名
 * @param option 一些可选的参数，支持kUFileSDKOptionModifiedSince, kUFileSDKOptionRange
 * @param progress 进度回调
 * @param success 成功回调, 回调函数的参数里面包含kUFileRespETag
 * @param failure 失败回调，回调函数的参数里面包含kUFileRespXSession
 */
- (NSURLSessionDataTask * _Nullable) getFile:(NSString* _Nonnull)key
                                      toFile:(NSString* _Nonnull)fileName
                               authorization:(NSString* _Nonnull)authorization
                                      option:(NSDictionary* _Nullable)option
                                    progress:(UFileProgressCallback _Nullable)downloadProgress
                                     success:(UFileDownloadDoneCallback _Nonnull)success
                                     failure:(UFileOpFailCallback _Nonnull)failure;



/**
 * 上传文件到指定的key
 * @param key UFILE中的key值
 * @param fromFile 需要上传的本地文件路径
 * @param authorization 签名
 * @param option 一些可选的参数，支持kUFileSDKOptionFileType, kUFileSDKOptionMD5
 * @param progress 进度回调
 * @param success 成功回调, 回调函数的参数里面包含kUFileRespETag
 * @param failure 失败回调，回调函数的参数里面包含kUFileRespXSession
 */
- (NSURLSessionDataTask * _Nullable ) putFile:(NSString* _Nonnull)key
                                     fromFile:(NSString* _Nonnull)fileName
                                authorization:(NSString* _Nonnull)authorization
                                       option:(NSDictionary* _Nullable)option
                                     progress:(UFileProgressCallback _Nullable)uploadProgress
                                      success:(UFileUploadDoneCallback _Nonnull)success
                                      failure:(UFileOpFailCallback _Nonnull)failure;


/**
 * 获取文件的描述信息
 * @param key UFILE中的key值
 * @param authorization 签名
 * @param success 成功回调, 回调函数的参数里面包含kUFileRespFileType, kUFileRespLength, kUFileRespETag
 * @param failure 失败回调，回调函数的参数里面包含kUFileRespXSession
 */
- (NSURLSessionDataTask * _Nullable ) headFile:(NSString* _Nonnull)key
                                 authorization:(NSString* _Nonnull)authorization
                                       success:(UFileUploadDoneCallback _Nonnull)success
                                       failure:(UFileOpFailCallback _Nonnull)failure;

/**
 * 删除指定的文件
 * @param key UFILE中的key值
 * @param authorization 签名
 * @param success 成功回调, 回调函数的参数无内容
 * @param failure 失败回调，回调函数的参数里面包含kUFileRespXSession
 */
- (NSURLSessionDataTask * _Nullable ) deleteFile:(NSString* _Nonnull)key
                                   authorization:(NSString* _Nonnull)authorization
                                         success:(UFileUploadDoneCallback _Nonnull)success
                                         failure:(UFileOpFailCallback _Nonnull)failure;



/**
 *  开始分片上传
 * @param key UFILE中的key值
 * @param authorization 签名
 * @param success 成功回调, 回调函数的参数包括 kUFileRespUploadId, kUFileRespBlockSize, kUFileRespBucketName, kUFileRespKeyName
 * @param failure 失败回调
 */
- (NSURLSessionDataTask * _Nullable ) multipartUploadStart:(NSString* _Nonnull)key
                                             authorization:(NSString* _Nonnull)authorization
                                                   success:(UFileOpDoneCallback _Nonnull)success
                                                   failure:(UFileOpFailCallback _Nonnull)failure;

/**
 * 上传某个分片
 * @param key UFILE中的key值
 * @param uploadId 上传的uploadId
 * @param partNumber 分片序号
 * @param contentType 文件类型，HTTP中的Content-Type，例如 application/json
 * @param data 数据块
 * @param option 支持kUFileSDKOptionTimeoutInterval
 * @param authorization 签名
 * @param progress 进度回调
 * @param success 成功回调, 回调函数的参数包括 kUFileRespETag
 * @param failure 失败回调
 */
- (NSURLSessionDataTask * _Nullable ) multipartUploadPart:(NSString* _Nonnull)key
                                                 uploadId:(NSString* _Nonnull)uploadId
                                               partNumber:(NSInteger)partNumber
                                              contentType:(NSString* _Nonnull)contentType
                                                     data:(NSData* _Nonnull)data
                                                   option:(NSDictionary* _Nullable)option
                                            authorization:(NSString* _Nonnull)authorization
                                                 progress:(UFileProgressCallback _Nullable)uploadProgress
                                                  success:(UFileUploadDoneCallback _Nonnull)success
                                                  failure:(UFileOpFailCallback _Nonnull)failure;


/**
 * 上传某个分片
 * @param key UFILE中的key值
 * @param uploadId 上传的uploadId
 * @param partNumber 分片序号
 * @param contentType 文件类型，HTTP中的Content-Type，例如 application/json
 * @param data 数据块
 * @param authorization 签名
 * @param progress 进度回调
 * @param success 成功回调, 回调函数的参数包括 kUFileRespETag
 * @param failure 失败回调
 */
- (NSURLSessionDataTask * _Nullable ) multipartUploadPart:(NSString* _Nonnull)key
                                                 uploadId:(NSString* _Nonnull)uploadId
                                               partNumber:(NSInteger)partNumber
                                              contentType:(NSString* _Nonnull)contentType
                                                     data:(NSData* _Nonnull)data
                                            authorization:(NSString* _Nonnull)authorization
                                                 progress:(UFileProgressCallback _Nullable)uploadProgress
                                                  success:(UFileUploadDoneCallback _Nonnull)success
                                                  failure:(UFileOpFailCallback _Nonnull)failure;

/**
 * 结束分片上传
 * @param key UFILE中的key值
 * @param uploadId 上传的uploadId
 * @param newKey 参见API文档中的newKey定义
 * @param etags 之前各分片上传之后的etag的值，必须保证按顺序传
 * @param contentType 文件类型，HTTP中的Content-Type，例如 application/json
 * @param authorization 签名
 * @param success 成功回调, 回调函数的参数包括 kUFileRespUploadId, kUFileRespBlockSize, kUFileRespBucketName, kUFileRespKeyName
 * @param failure 失败回调
 */
- (NSURLSessionDataTask * _Nullable ) multipartUploadFinish:(NSString* _Nonnull)key
                                                   uploadId:(NSString* _Nonnull)uploadId
                                                     newKey:(NSString* _Nonnull)newKey
                                                      etags:(NSArray* _Nonnull)etags
                                                contentType:(NSString* _Nonnull)contentType
                                              authorization:(NSString* _Nonnull)authorization
                                                    success:(UFileUploadDoneCallback _Nonnull)success
                                                    failure:(UFileOpFailCallback _Nonnull)failure;

/**
 * 取消分片上传
 * @param key UFILE中的key值
 * @param uploadId 上传的uploadId
 * @param authorization 签名
 * @param success 成功回调
 * @param failure 失败回调
 */
- (NSURLSessionDataTask * _Nullable ) multipartUploadAbort:(NSString* _Nonnull)key
                                                  uploadId:(NSString* _Nonnull)uploadId
                                             authorization:(NSString* _Nonnull)authorization
                                                   success:(UFileUploadDoneCallback _Nonnull)success
                                                   failure:(UFileOpFailCallback _Nonnull)failure;


@end

#endif /* UFileAPI_Private_h */
