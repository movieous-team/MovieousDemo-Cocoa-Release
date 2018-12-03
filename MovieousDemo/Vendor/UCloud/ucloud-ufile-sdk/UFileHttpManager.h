//
//  UFileHttpManager.h
//  ufilesdk
//
//  Created by wu shauk on 12/11/15.
//  Copyright © 2015 ucloud. All rights reserved.
//

#ifndef UFileHttpManager_h
#define UFileHttpManager_h


extern NSString* _Nullable UFilePercentEscapedStringFromString(NSString* _Nonnull);

@interface UFileHttpManager : NSObject<NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate, NSURLSessionDownloadDelegate>



/**
 The dispatch queue for `completionBlock`. If `NULL` (default), the main queue is used.
 */
@property (nonatomic, strong, nullable) dispatch_queue_t completionQueue;
/**
 The dispatch group for `completionBlock`. If `NULL` (default), a private dispatch group is used.
 */
@property (nonatomic, strong, nullable) dispatch_group_t completionGroup;

- (_Nonnull instancetype)init;

- (NSURLSessionDataTask * _Nullable )Put:(NSURL  * _Nonnull)URL
                            headerParams:(NSArray  * _Nonnull)headerParams
                         timeoutInterval:(NSNumber*)timeoutInterval
                                    body:(NSData * _Nonnull)body
                                progress:(void (^ _Nullable)(NSProgress * _Nonnull))uploadProgress
                                 success:(void (^ _Nullable)(NSURLSessionDataTask * _Nonnull, id _Nullable))success
                                 failure:(void (^ _Nullable)(NSURLSessionDataTask * _Nullable, NSError * _Nonnull))failure;

- (NSURLSessionDataTask * _Nullable)Get:(NSURL * _Nonnull)URL
                           headerParams:(NSArray * _Nonnull)headerParams
                        timeoutInterval:(NSNumber*)timeoutInterval
                                queries:(NSArray* _Nullable)queries
                               progress:(void (^ _Nullable)(NSProgress * _Nonnull))uploadProgress
                                success:(void (^ _Nullable)(NSURLSessionDataTask * _Nonnull, id _Nullable))success
                                failure:(void (^ _Nullable)(NSURLSessionDataTask * _Nullable, NSError * _Nonnull))failure;

- (NSURLSessionDataTask* _Nullable)Head:(NSURL * _Nonnull)URL
                           headerParams:(NSArray * _Nonnull)headerParams
                        timeoutInterval:(NSNumber*)timeoutInterval
                                success:(void (^ _Nullable)(NSURLSessionDataTask * _Nonnull, id _Nullable))success
                                failure:(void (^ _Nullable)(NSURLSessionDataTask * _Nullable, NSError * _Nonnull))failure;

- (NSURLSessionDataTask* _Nullable)Delete:(NSURL * _Nonnull)URL
                           headerParams:(NSArray * _Nonnull)headerParams
                          timeoutInterval:(NSNumber*)timeoutInterval
                                success:(void (^ _Nullable)(NSURLSessionDataTask * _Nonnull, id _Nullable))success
                                failure:(void (^ _Nullable)(NSURLSessionDataTask * _Nullable, NSError * _Nonnull))failure;

- (NSURLSessionDataTask * _Nullable )Post:(NSURL  * _Nonnull)URL
                            headerParams:(NSArray  * _Nonnull)headerParams
                          timeoutInterval:(NSNumber*)timeoutInterval
                                    body:(NSData * _Nullable)body
                                progress:(void (^ _Nullable)(NSProgress * _Nonnull))uploadProgress
                                 success:(void (^ _Nullable)(NSURLSessionDataTask * _Nonnull, id _Nullable))success
                                 failure:(void (^ _Nullable)(NSURLSessionDataTask * _Nullable, NSError * _Nonnull))failure;


- (NSURLSessionUploadTask* _Nullable)uploadTaskWithRequest:(nonnull NSURLRequest*)request
                                                  fromFile:(nonnull NSURL*)fileURL
                                                  progress:(void (^ _Nullable)(NSProgress* _Nonnull)) uploadProgressBlock
                                         completionHandler:(void (^ _Nullable)(NSURLResponse* _Nonnull response, id _Nullable responseObject, NSError  * _Nullable error))completionHandler;


- (NSURLSessionDownloadTask* _Nullable)downloadTaskWithRequest:(NSURLRequest* _Nonnull)request
                                                      progress:(nullable void (^)(NSProgress* _Nonnull downloadProgress)) downloadProgressBlock
                                                   destination:(NSURL* _Nonnull (^ _Nonnull)(NSURL* _Nonnull targetPath, NSURLResponse* _Nonnull response))destination
                                             completionHandler:(nullable void (^)(NSURLResponse* _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error))completionHandler;

- (NSURLSessionDataTask* _Nullable)dataTaskWithRequest:(NSURLRequest* _Nonnull)request
                               uploadProgress:(nullable void (^)(NSProgress* _Nonnull uploadProgress)) uploadProgressBlock
                             downloadProgress:(nullable void (^)(NSProgress* _Nonnull downloadProgress)) downloadProgressBlock
                            completionHandler:(nullable void (^)(NSURLResponse* _Nonnull response, id _Nullable responseObject,  NSError * _Nullable error))completionHandler;



- (void) finishTasksAndInvalidate;

@end



#endif /* UFileHttpManager_h */
