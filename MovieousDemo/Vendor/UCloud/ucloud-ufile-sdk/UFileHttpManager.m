//
//  UFileHttpManager.m
//  ufilesdk
//
//  Created by wu shauk on 12/11/15.
//  Copyright © 2015 ucloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UFileHttpManager.h"
#import "version.h"

/**
 steal from the AfNetwork
 */


#ifndef NSFoundationVersionNumber_iOS_8_0
#define NSFoundationVersionNumber_With_Fixed_5871104061079552_bug 1140.11
#else
#define NSFoundationVersionNumber_With_Fixed_5871104061079552_bug NSFoundationVersionNumber_iOS_8_0
#endif

static dispatch_queue_t url_session_manager_creation_queue() {
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue =
            dispatch_queue_create("com.ucloud.mobile.ufilesdk.session.manager.creation", DISPATCH_QUEUE_SERIAL);
    });
    
    return queue;
}

static void url_session_manager_create_task_safely(dispatch_block_t block) {
    if (NSFoundationVersionNumber < NSFoundationVersionNumber_With_Fixed_5871104061079552_bug) {
        // Fix of bug
        // Open Radar:http://openradar.appspot.com/radar?id=5871104061079552 (status: Fixed in iOS8)
        // Issue about:https://github.com/AFNetworking/AFNetworking/issues/2093
        dispatch_sync(url_session_manager_creation_queue(), block);
    } else {
        block();
    }
}

static dispatch_queue_t url_session_manager_processing_queue() {
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("com.ucloud.mobile.ufilesdk.session.manager.processing", DISPATCH_QUEUE_CONCURRENT);
    });
    
    return queue;
}

static dispatch_group_t url_session_manager_completion_group() {
    static dispatch_group_t queueGroup;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queueGroup = dispatch_group_create();
    });
    
    return queueGroup;
}


typedef NSURL * (^AFURLSessionDownloadTaskDidFinishDownloadingBlock)(NSURLSession *session, NSURLSessionDownloadTask *downloadTask, NSURL *location);
typedef void (^AFURLSessionDownloadTaskDidWriteDataBlock)(NSURLSession *session, NSURLSessionDownloadTask *downloadTask, int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite);
typedef void (^AFURLSessionDownloadTaskDidResumeBlock)(NSURLSession *session, NSURLSessionDownloadTask *downloadTask, int64_t fileOffset, int64_t expectedTotalBytes);
typedef void (^AFURLSessionTaskProgressBlock)(NSProgress *);

typedef void (^AFURLSessionTaskCompletionHandler)(NSURLResponse *response, id responseObject, NSError *error);

@interface UFileSDKHttpTaskDelegate : NSObject <NSURLSessionTaskDelegate, NSURLSessionDataDelegate, NSURLSessionDownloadDelegate>
@property (nonatomic, weak) UFileHttpManager *manager;
@property (nonatomic, strong) NSMutableData *mutableData;
@property (nonatomic, strong) NSProgress *uploadProgress;
@property (nonatomic, strong) NSProgress *downloadProgress;
@property (nonatomic, copy) NSURL *downloadFileURL;
@property (nonatomic, copy) AFURLSessionDownloadTaskDidFinishDownloadingBlock downloadTaskDidFinishDownloading;
@property (nonatomic, copy) AFURLSessionTaskProgressBlock uploadProgressBlock;
@property (nonatomic, copy) AFURLSessionTaskProgressBlock downloadProgressBlock;
@property (nonatomic, copy) AFURLSessionTaskCompletionHandler completionHandler;
@end

@implementation UFileSDKHttpTaskDelegate

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.mutableData = [NSMutableData data];
    self.uploadProgress = [[NSProgress alloc] initWithParent:nil userInfo:nil];
    self.uploadProgress.totalUnitCount = NSURLSessionTransferSizeUnknown;
    
    self.downloadProgress = [[NSProgress alloc] initWithParent:nil userInfo:nil];
    self.downloadProgress.totalUnitCount = NSURLSessionTransferSizeUnknown;
    return self;
}

#pragma mark - NSProgress Tracking

- (void)setupProgressForTask:(NSURLSessionTask *)task {
    __weak __typeof__(task) weakTask = task;
    
    self.uploadProgress.totalUnitCount = task.countOfBytesExpectedToSend;
    self.downloadProgress.totalUnitCount = task.countOfBytesExpectedToReceive;
    [self.uploadProgress setCancellable:YES];
    [self.uploadProgress setCancellationHandler:^{
        __typeof__(weakTask) strongTask = weakTask;
        [strongTask cancel];
    }];
    [self.uploadProgress setPausable:YES];
    [self.uploadProgress setPausingHandler:^{
        __typeof__(weakTask) strongTask = weakTask;
        [strongTask suspend];
    }];
    if ([self.uploadProgress respondsToSelector:@selector(setResumingHandler:)]) {
        [self.uploadProgress setResumingHandler:^{
            __typeof__(weakTask) strongTask = weakTask;
            [strongTask resume];
        }];
    }
    
    [self.downloadProgress setCancellable:YES];
    [self.downloadProgress setCancellationHandler:^{
        __typeof__(weakTask) strongTask = weakTask;
        [strongTask cancel];
    }];
    [self.downloadProgress setPausable:YES];
    [self.downloadProgress setPausingHandler:^{
        __typeof__(weakTask) strongTask = weakTask;
        [strongTask suspend];
    }];
    
    if ([self.downloadProgress respondsToSelector:@selector(setResumingHandler:)]) {
        [self.downloadProgress setResumingHandler:^{
            __typeof__(weakTask) strongTask = weakTask;
            [strongTask resume];
        }];
    }
    
    [task addObserver:self
           forKeyPath:NSStringFromSelector(@selector(countOfBytesReceived))
              options:NSKeyValueObservingOptionNew
              context:NULL];
    [task addObserver:self
           forKeyPath:NSStringFromSelector(@selector(countOfBytesExpectedToReceive))
              options:NSKeyValueObservingOptionNew
              context:NULL];
    
    [task addObserver:self
           forKeyPath:NSStringFromSelector(@selector(countOfBytesSent))
              options:NSKeyValueObservingOptionNew
              context:NULL];
    [task addObserver:self
           forKeyPath:NSStringFromSelector(@selector(countOfBytesExpectedToSend))
              options:NSKeyValueObservingOptionNew
              context:NULL];
    
    [self.downloadProgress addObserver:self
                            forKeyPath:NSStringFromSelector(@selector(fractionCompleted))
                               options:NSKeyValueObservingOptionNew
                               context:NULL];
    [self.uploadProgress addObserver:self
                          forKeyPath:NSStringFromSelector(@selector(fractionCompleted))
                             options:NSKeyValueObservingOptionNew
                             context:NULL];
}

- (void)cleanUpProgressForTask:(NSURLSessionTask *)task {
    [task removeObserver:self forKeyPath:NSStringFromSelector(@selector(countOfBytesReceived))];
    [task removeObserver:self forKeyPath:NSStringFromSelector(@selector(countOfBytesExpectedToReceive))];
    [task removeObserver:self forKeyPath:NSStringFromSelector(@selector(countOfBytesSent))];
    [task removeObserver:self forKeyPath:NSStringFromSelector(@selector(countOfBytesExpectedToSend))];
    [self.downloadProgress removeObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted))];
    [self.uploadProgress removeObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted))];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if ([object isKindOfClass:[NSURLSessionTask class]]) {
        if ([keyPath isEqualToString:NSStringFromSelector(@selector(countOfBytesReceived))]) {
            self.downloadProgress.completedUnitCount = [change[@"new"] longLongValue];
        } else if ([keyPath isEqualToString:NSStringFromSelector(@selector(countOfBytesExpectedToReceive))]) {
            self.downloadProgress.totalUnitCount = [change[@"new"] longLongValue];
        } else if ([keyPath isEqualToString:NSStringFromSelector(@selector(countOfBytesSent))]) {
            self.uploadProgress.completedUnitCount = [change[@"new"] longLongValue];
        } else if ([keyPath isEqualToString:NSStringFromSelector(@selector(countOfBytesExpectedToSend))]) {
            self.uploadProgress.totalUnitCount = [change[@"new"] longLongValue];
        }
    }
    else if ([object isEqual:self.downloadProgress]) {
        if (self.downloadProgressBlock) {
            self.downloadProgressBlock(object);
        }
    }
    else if ([object isEqual:self.uploadProgress]) {
        if (self.uploadProgressBlock) {
            self.uploadProgressBlock(object);
        }
    }
}

#pragma mark - NSURLSessionTaskDelegate

- (void)URLSession:(__unused NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgnu"
    __strong UFileHttpManager *manager = self.manager;
    
    __block id responseObject = nil;
    
    //Performance Improvement from #2672
    if (self.mutableData) {
        responseObject = [self.mutableData copy];
        //We no longer need the reference, so nil it out to gain back some memory.
        self.mutableData = nil;
    }
    
    if (error) {
        
        dispatch_group_async(manager.completionGroup ?: url_session_manager_completion_group(), manager.completionQueue ?: dispatch_get_main_queue(), ^{
            if (self.completionHandler) {
                self.completionHandler(task.response, responseObject, error);
            }
        });
    } else {
        dispatch_async(url_session_manager_processing_queue(), ^{
            
            if (self.downloadFileURL) {
                responseObject = self.downloadFileURL;
            }
            
            dispatch_group_async(manager.completionGroup ?: url_session_manager_completion_group(), manager.completionQueue ?: dispatch_get_main_queue(), ^{
                if (self.completionHandler) {
                    self.completionHandler(task.response, responseObject, nil);
                }
            });
        });
    }
#pragma clang diagnostic pop
}

#pragma mark - NSURLSessionDataTaskDelegate

- (void)URLSession:(__unused NSURLSession *)session
          dataTask:(__unused NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
    [self.mutableData appendData:data];
}

#pragma mark - NSURLSessionDownloadTaskDelegate

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location
{
    NSError *fileManagerError = nil;
    self.downloadFileURL = nil;
    
    if (self.downloadTaskDidFinishDownloading) {
        self.downloadFileURL = self.downloadTaskDidFinishDownloading(session, downloadTask, location);
        if (self.downloadFileURL) {
            [[NSFileManager defaultManager] moveItemAtURL:location toURL:self.downloadFileURL error:&fileManagerError];
        }
    }
}

@end


@interface UFileHttpManager ()

@property (readwrite, nonatomic, strong) NSURLSessionConfiguration *sessionConfiguration;
@property (readwrite, nonatomic, strong) NSOperationQueue *operationQueue;
@property (readwrite, nonatomic, strong) NSMutableDictionary *mutableTaskDelegatesKeyedByTaskIdentifier;
@property (readonly, nonatomic, copy) NSString *taskDescriptionForSessionTasks;
@property (readwrite, nonatomic, strong) NSLock *lock;

@property (readonly, nonatomic, strong) NSURLSession * defaultSession;
@property (readonly, nonatomic, strong) NSURLSession * downloadSession;
@end


@implementation UFileHttpManager

-(instancetype)init
{
    self.operationQueue = [[NSOperationQueue alloc] init];
    self.operationQueue.maxConcurrentOperationCount = 1;
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    config.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    _defaultSession = [NSURLSession sessionWithConfiguration:config
                                                    delegate:self
                                               delegateQueue:self.operationQueue];
    
    self.mutableTaskDelegatesKeyedByTaskIdentifier = [[NSMutableDictionary alloc] init];
    return self;
}


- (NSString *)taskDescriptionForSessionTasks {
    return [NSString stringWithFormat:@"%p", self];
}

- (NSURLSessionDataTask *)Post:(NSURL *)URL
                  headerParams:(NSArray*)headerParams
               timeoutInterval:(NSNumber*)timeoutInterval
                          body:(NSData*)body
                      progress:(void (^)(NSProgress * _Nonnull))uploadProgress
                       success:(void (^)(NSURLSessionDataTask * _Nonnull, id _Nullable))success
                       failure:(void (^)(NSURLSessionDataTask * _Nullable, NSError * _Nonnull))failure
{
    NSMutableURLRequest *request =
        [[NSMutableURLRequest alloc]
         initWithURL:URL];
    if (timeoutInterval != nil) {
        request.timeoutInterval = [timeoutInterval doubleValue];
    }
    request.HTTPMethod = @"POST";
    
    for (NSArray* item in headerParams) {
        [request addValue:item[1] forHTTPHeaderField:item[0]];
    }
    [request addValue:[NSString stringWithFormat:@"UFile iOS/%@", @(UFILE_IOS_SDK_VERSION)] forHTTPHeaderField:@"UserAgent"];
    [request setHTTPBody:body];
    __block NSURLSessionDataTask *dataTask =
    [self dataTaskWithRequest:request
               uploadProgress:uploadProgress
             downloadProgress:nil
            completionHandler:^(NSURLResponse * __unused response, id responseObject, NSError *error) {
                if (error) {
                    if (failure) {
                        failure(dataTask, error);
                    }
                } else {
                    if (success) {
                        success(dataTask, responseObject);
                    }
                }
            }];
    
    [dataTask resume];
    
    return dataTask;
}


- (NSURLSessionDataTask *) Put:(NSURL *)URL
                  headerParams:(NSArray*)headerParams
               timeoutInterval:(NSNumber*)timeoutInterval
                          body:(NSData*)body
                      progress:(void (^)(NSProgress * _Nonnull))uploadProgress
                       success:(void (^)(NSURLSessionDataTask * _Nonnull, id _Nullable))success
                       failure:(void (^)(NSURLSessionDataTask * _Nullable, NSError * _Nonnull))failure
{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:URL];
    if (timeoutInterval != nil) {
        request.timeoutInterval = [timeoutInterval doubleValue];
    }
    request.HTTPMethod = @"PUT";
    
    for (NSArray* item in headerParams) {
        [request addValue:item[1] forHTTPHeaderField:item[0]];
    }
    [request addValue:[NSString stringWithFormat:@"UFile iOS/%@", @(UFILE_IOS_SDK_VERSION)] forHTTPHeaderField:@"UserAgent"];
    [request setHTTPBody:body];
    __block NSURLSessionDataTask *dataTask =
    [self dataTaskWithRequest:request
               uploadProgress:uploadProgress
             downloadProgress:nil
            completionHandler:^(NSURLResponse * __unused response, id responseObject, NSError *error) {
                if (error) {
                    if (failure) {
                        failure(dataTask, error);
                    }
                } else {
                    if (success) {
                        success(dataTask, responseObject);
                    }
                }
            }];
    
    [dataTask resume];
    
    return dataTask;
}

-(NSURLSessionDataTask*) Get:(NSURL *)URL
                headerParams:(NSArray *)headerParams
             timeoutInterval:(NSNumber*)timeoutInterval
                     queries:(NSArray *)queries
                    progress:(void (^)(NSProgress * _Nonnull))downloadProgress
                     success:(void (^)(NSURLSessionDataTask * _Nonnull, id _Nullable))success
                     failure:(void (^)(NSURLSessionDataTask * _Nullable, NSError * _Nonnull))failure
{
    NSMutableURLRequest *request =
    [[NSMutableURLRequest alloc]
     initWithURL:URL];
    if (timeoutInterval != nil) {
        request.timeoutInterval = [timeoutInterval doubleValue];
    }
    request.HTTPMethod = @"GET";
    
    for (NSArray* item in headerParams) {
        [request addValue:item[1] forHTTPHeaderField:item[0]];
    }
    [request addValue:[NSString stringWithFormat:@"UFile iOS/%@", @(UFILE_IOS_SDK_VERSION)] forHTTPHeaderField:@"UserAgent"];
    if (queries) {
        NSString * qs = nil;
        NSMutableString *queryString = [NSMutableString stringWithString:@"?"];
        for (NSArray* item in queries) {
            [queryString appendFormat:@"%@=%@&", item[0],UFilePercentEscapedStringFromString(item[1])];
        }
        qs = [queryString substringToIndex:([queryString length]-1)];
        URL = [NSURL URLWithString:[[URL path] stringByAppendingString:qs]];
    }
    
    
    __block NSURLSessionDataTask *dataTask =
    [self dataTaskWithRequest:request
               uploadProgress:nil
             downloadProgress:downloadProgress
            completionHandler:^(NSURLResponse * __unused response, id responseObject, NSError *error) {
                if (error) {
                    if (failure) {
                        failure(dataTask, error);
                    }
                } else {
                    if (success) {
                        success(dataTask, responseObject);
                    }
                }
            }];
    
    [dataTask resume];
    
    return dataTask;
}


-(NSURLSessionDataTask*) Head:(NSURL *)URL
                headerParams:(NSArray *)headerParams
              timeoutInterval:(NSNumber*)timeoutInterval
                     success:(void (^)(NSURLSessionDataTask * _Nonnull, id _Nullable))success
                     failure:(void (^)(NSURLSessionDataTask * _Nullable, NSError * _Nonnull))failure
{
    NSMutableURLRequest *request =
    [[NSMutableURLRequest alloc]
     initWithURL:URL];
    request.HTTPMethod = @"HEAD";
    if (timeoutInterval != nil) {
        request.timeoutInterval = [timeoutInterval doubleValue];
    }
    for (NSArray* item in headerParams) {
        [request addValue:item[1] forHTTPHeaderField:item[0]];
    }
    [request addValue:[NSString stringWithFormat:@"UFile iOS/%@", @(UFILE_IOS_SDK_VERSION)] forHTTPHeaderField:@"UserAgent"];
    __block NSURLSessionDataTask *dataTask =
    [self dataTaskWithRequest:request
               uploadProgress:nil
             downloadProgress:nil
            completionHandler:^(NSURLResponse * __unused response, id responseObject, NSError *error) {
                if (error) {
                    if (failure) {
                        failure(dataTask, error);
                    }
                } else {
                    if (success) {
                        success(dataTask, responseObject);
                    }
                }
            }];
    
    [dataTask resume];
    
    return dataTask;
}


-(NSURLSessionDataTask*) Delete:(NSURL *)URL
                 headerParams:(NSArray *)headerParams
                timeoutInterval:(NSNumber*)timeoutInterval
                      success:(void (^)(NSURLSessionDataTask * _Nonnull, id _Nullable))success
                      failure:(void (^)(NSURLSessionDataTask * _Nullable, NSError * _Nonnull))failure
{
    NSMutableURLRequest *request =
    [[NSMutableURLRequest alloc]
     initWithURL:URL];
    request.HTTPMethod = @"DELETE";
    if (timeoutInterval != nil) {
        request.timeoutInterval = [timeoutInterval doubleValue];
    }
    
    for (NSArray* item in headerParams) {
        [request addValue:item[1] forHTTPHeaderField:item[0]];
    }
    [request addValue:[NSString stringWithFormat:@"UFile iOS/%@", @(UFILE_IOS_SDK_VERSION)] forHTTPHeaderField:@"UserAgent"];
    __block NSURLSessionDataTask *dataTask =
    [self dataTaskWithRequest:request
               uploadProgress:nil
             downloadProgress:nil
            completionHandler:^(NSURLResponse * __unused response, id responseObject, NSError *error) {
                if (error) {
                    if (failure) {
                        failure(dataTask, error);
                    }
                } else {
                    if (success) {
                        success(dataTask, responseObject);
                    }
                }
            }];
    
    [dataTask resume];
    
    return dataTask;
}

- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request
                                         fromFile:(NSURL *)fileURL
                                         progress:(void (^)(NSProgress *uploadProgress)) uploadProgressBlock
                                completionHandler:(void (^)(NSURLResponse *response, id responseObject, NSError *error))completionHandler
{
    __block NSURLSessionUploadTask *uploadTask = nil;
    url_session_manager_create_task_safely(^{
        uploadTask = [self.defaultSession uploadTaskWithRequest:request fromFile:fileURL];
    });
    
    
    if (!uploadTask) {
        return nil;
    }
    [self addDelegateForUploadTask:uploadTask progress:uploadProgressBlock completionHandler:completionHandler];
    
    return uploadTask;
}

- (NSURLSessionDownloadTask *)downloadTaskWithRequest:(NSURLRequest *)request
                                             progress:(void (^)(NSProgress *downloadProgress)) downloadProgressBlock
                                          destination:(NSURL * (^)(NSURL *targetPath, NSURLResponse *response))destination
                                    completionHandler:(void (^)(NSURLResponse *response, NSURL *filePath, NSError *error))completionHandler
{
    __block NSURLSessionDownloadTask *downloadTask = nil;
    url_session_manager_create_task_safely(^{
        downloadTask = [self.defaultSession downloadTaskWithRequest:request];
    });
    
    [self addDelegateForDownloadTask:downloadTask progress:downloadProgressBlock destination:destination completionHandler:completionHandler];
    
    return downloadTask;
}

- (void) finishTasksAndInvalidate {
    [_defaultSession finishTasksAndInvalidate];
}

- (void)setDelegate:(UFileSDKHttpTaskDelegate *)delegate
            forTask:(NSURLSessionTask *)task
{
    NSParameterAssert(task);
    NSParameterAssert(delegate);
    [self.lock lock];
    self.mutableTaskDelegatesKeyedByTaskIdentifier[@(task.taskIdentifier)] = delegate;
    [delegate setupProgressForTask:task];
    [self.lock unlock];
}


- (UFileSDKHttpTaskDelegate *)delegateForTask:(NSURLSessionTask *)task {
    NSParameterAssert(task);
    
    UFileSDKHttpTaskDelegate *delegate = nil;
    [self.lock lock];
    delegate = self.mutableTaskDelegatesKeyedByTaskIdentifier[@(task.taskIdentifier)];
    [self.lock unlock];
    
    return delegate;
}



- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                               uploadProgress:(nullable void (^)(NSProgress *uploadProgress)) uploadProgressBlock
                             downloadProgress:(nullable void (^)(NSProgress *downloadProgress)) downloadProgressBlock
                            completionHandler:(nullable void (^)(NSURLResponse *response, id _Nullable responseObject,  NSError * _Nullable error))completionHandler {
    
    __block NSURLSessionDataTask *dataTask = nil;
    url_session_manager_create_task_safely(^{
        dataTask = [self.defaultSession dataTaskWithRequest:request];
        NSLog(@"%@", dataTask);
    });
    
    [self addDelegateForDataTask:dataTask uploadProgress:uploadProgressBlock downloadProgress:downloadProgressBlock completionHandler:completionHandler];
    
    return dataTask;
}

- (void)addDelegateForDataTask:(NSURLSessionDataTask *)dataTask
                uploadProgress:(nullable void (^)(NSProgress *uploadProgress)) uploadProgressBlock
              downloadProgress:(nullable void (^)(NSProgress *downloadProgress)) downloadProgressBlock
             completionHandler:(void (^)(NSURLResponse *response, id responseObject, NSError *error))completionHandler
{
    UFileSDKHttpTaskDelegate *delegate = [[UFileSDKHttpTaskDelegate alloc] init];
    delegate.manager = self;
    delegate.completionHandler = completionHandler;
    
    dataTask.taskDescription = self.taskDescriptionForSessionTasks;
    [self setDelegate:delegate forTask:dataTask];
    
    delegate.uploadProgressBlock = uploadProgressBlock;
    delegate.downloadProgressBlock = downloadProgressBlock;
}

- (void)addDelegateForUploadTask:(NSURLSessionUploadTask *)uploadTask
                        progress:(void (^)(NSProgress *uploadProgress)) uploadProgressBlock
               completionHandler:(void (^)(NSURLResponse *response, id responseObject, NSError *error))completionHandler
{
    UFileSDKHttpTaskDelegate *delegate = [[UFileSDKHttpTaskDelegate alloc] init];
    delegate.manager = self;
    delegate.completionHandler = completionHandler;
    
    uploadTask.taskDescription = self.taskDescriptionForSessionTasks;
    
    [self setDelegate:delegate forTask:uploadTask];
    
    delegate.uploadProgressBlock = uploadProgressBlock;
}

- (void)addDelegateForDownloadTask:(NSURLSessionDownloadTask *)downloadTask
                          progress:(void (^)(NSProgress *downloadProgress)) downloadProgressBlock
                       destination:(NSURL * (^)(NSURL *targetPath, NSURLResponse *response))destination
                 completionHandler:(void (^)(NSURLResponse *response, NSURL *filePath, NSError *error))completionHandler
{
    UFileSDKHttpTaskDelegate *delegate = [[UFileSDKHttpTaskDelegate alloc] init];
    delegate.manager = self;
    delegate.completionHandler = completionHandler;
    
    if (destination) {
        delegate.downloadTaskDidFinishDownloading = ^NSURL * (NSURLSession * __unused session, NSURLSessionDownloadTask *task, NSURL *location) {
            return destination(location, task.response);
        };
    }
    
    downloadTask.taskDescription = self.taskDescriptionForSessionTasks;
    
    [self setDelegate:delegate forTask:downloadTask];
    
    delegate.downloadProgressBlock = downloadProgressBlock;
}

- (void)removeDelegateForTask:(NSURLSessionTask *)task {
    NSParameterAssert(task);
    
    UFileSDKHttpTaskDelegate *delegate = [self delegateForTask:task];
    [self.lock lock];
    [delegate cleanUpProgressForTask:task];
    [self.mutableTaskDelegatesKeyedByTaskIdentifier removeObjectForKey:@(task.taskIdentifier)];
    [self.lock unlock];
}


#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
    NSURLSessionResponseDisposition disposition = NSURLSessionResponseAllow;
    
    if (completionHandler) {
        completionHandler(disposition);
    }
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didBecomeDownloadTask:(NSURLSessionDownloadTask *)downloadTask
{
    UFileSDKHttpTaskDelegate *delegate = [self delegateForTask:dataTask];
    if (delegate) {
        [self removeDelegateForTask:dataTask];
        [self setDelegate:delegate forTask:downloadTask];
    }
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
    
    UFileSDKHttpTaskDelegate *delegate = [self delegateForTask:dataTask];
    [delegate URLSession:session dataTask:dataTask didReceiveData:data];
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
 willCacheResponse:(NSCachedURLResponse *)proposedResponse
 completionHandler:(void (^)(NSCachedURLResponse *cachedResponse))completionHandler
{
    if (completionHandler) {
        completionHandler(nil);
    }
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error
{
    UFileSDKHttpTaskDelegate *delegate = [self delegateForTask:task];
    
    // delegate may be nil when completing a task in the background
    if (delegate) {
        [delegate URLSession:session task:task didCompleteWithError:error];
        
        [self removeDelegateForTask:task];
    }
    
}



- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
}




#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location
{
    UFileSDKHttpTaskDelegate *delegate = [self delegateForTask:downloadTask];
    if (delegate) {
        [delegate URLSession:session downloadTask:downloadTask didFinishDownloadingToURL:location];
    }
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{

}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes
{
    UFileSDKHttpTaskDelegate *delegate = [self delegateForTask:downloadTask];
    [delegate URLSession:session downloadTask:downloadTask didResumeAtOffset:fileOffset expectedTotalBytes:expectedTotalBytes];
}

#pragma mark - NSURLSessionDelegate


@end


NSString * UFilePercentEscapedStringFromString(NSString *string) {
    static NSString * const kAFCharactersGeneralDelimitersToEncode = @":#[]@?/"; // does not include "?" or "/" due to RFC 3986 - Section 3.4
    static NSString * const kAFCharactersSubDelimitersToEncode = @"!$&'()*+,;=";
    
    NSMutableCharacterSet * allowedCharacterSet = [[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy];
    [allowedCharacterSet removeCharactersInString:[kAFCharactersGeneralDelimitersToEncode stringByAppendingString:kAFCharactersSubDelimitersToEncode]];
    
    return [string stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacterSet];
}


