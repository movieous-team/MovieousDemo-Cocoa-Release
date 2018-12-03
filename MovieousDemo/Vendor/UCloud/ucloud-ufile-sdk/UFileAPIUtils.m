//
//  UFileAPIUtils.m
//  ufilesdk
//
//  Created by wu shauk on 4/21/16.
//  Copyright © 2016 ucloud. All rights reserved.
//

#import "UFileAPIUtils.h"

#import <CommonCrypto/CommonDigest.h>


static const NSUInteger kFileBlockSize = 8 * 1024;

@implementation UFileAPIUtils

+ (NSString*) calcMD5ForData:(NSData *)data
{
    const char* original_str = (const char *)[data bytes];
    NSUInteger len = [data length];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5(original_str, (uint)len, digest);
    return [UFileAPIUtils encodeFromBuf:digest];
}

+ (NSString*) calcMD5ForPath:(NSString *)path
{
    NSFileHandle* aHandle = [NSFileHandle fileHandleForReadingAtPath:path];
    if (aHandle == nil) {
        return nil;
    }
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5_CTX ctx;
    CC_MD5_Init(&ctx);
    while (true) {
        NSData* data = [aHandle readDataOfLength:kFileBlockSize];
        if (data) {
            CC_MD5_Update(&ctx, [data bytes], (unsigned int)data.length);
        }
        if (!data || data.length != kFileBlockSize) {
            break;
        }
    }
    CC_MD5_Final(digest, &ctx);
    return [UFileAPIUtils encodeFromBuf:digest];
}

+ (NSString*) encodeFromBuf:(const unsigned char *) buf
{
    NSMutableString* res = [NSMutableString stringWithCapacity:32];
    for(int  i =0; i<CC_MD5_DIGEST_LENGTH;i++){
        [res appendFormat:@"%02x",buf[i]];
    }
    return res;
}

@end

