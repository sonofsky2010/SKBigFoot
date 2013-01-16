//
//  NSData+MD5.m
//  SKBigFoot
//
//  Created by li shunnian on 12-10-14.
//
//

#import "NSData+MD5.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSData (MD5)

+(NSData *)MD5Digest:(NSData *)input {
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    
    CC_MD5(input.bytes, input.length, result);
    return [[NSData alloc] initWithBytes:result length:CC_MD5_DIGEST_LENGTH];
}

-(NSData *)MD5Digest {
    return [NSData MD5Digest:self];
}

+(NSString *)MD5String:(NSData *)input {
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    
    CC_MD5(input.bytes, input.length, result);
    NSMutableString *ret = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH*2];
    for (int i = 0; i<CC_MD5_DIGEST_LENGTH; i++) {
        [ret appendFormat:@"%02x",result[i]];
    }
    return ret;
}

-(NSString *)MD5String {
    return [NSData MD5String:self];
}


+(NSString *)MD5StringOfFilePath:(NSString *)filePath
{
    NSData *fileData = [NSData dataWithContentsOfFile:filePath];
    return [fileData MD5String];
}
@end
