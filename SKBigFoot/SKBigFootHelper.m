//
//  SKBigFootHelper.m
//  SKBigFoot
//
//  Created by li shunnian on 13-10-5.
//
//

#import "SKBigFootHelper.h"
#import "NSFileManager+DirectoryLocations.h"
#include <zlib.h>
#import "ASIHTTPRequest.h"
#import "ASIDataDecompressor.h"
#import "ZipArchive.h"
#import "NSData+MD5.h"

@implementation SKBigFootHelper
+ (BOOL)downloadFileFrom:(NSURL *)srcUrl to:(NSURL *)dstUrl
{
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:srcUrl];
    [request startSynchronous];
    NSError *error = [request error];
    if (error) {
        NSLog(@"%@", error);
        return NO;
    }
    int statuscode = [request responseStatusCode];
    if (statuscode != 200) {
        NSLog(@"download \"%@\" with http code %d", srcUrl, statuscode);
        return NO;
    }
    NSData *data = [request responseData];
    NSString *dstDirectory = [[dstUrl path] stringByDeletingLastPathComponent];
    if (![[NSFileManager defaultManager] fileExistsAtPath:dstDirectory]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:dstDirectory withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    return [data writeToURL:dstUrl atomically:YES];
}

+ (BOOL)downloadZFileFrom:(NSURL *)srcUrl to:(NSURL *)dstUrl
{
    if (!srcUrl) {
        NSLog(@"nil");
        return NO;
    }
    NSError *error = nil;
    NSString *srcPath = [srcUrl absoluteString];
    srcPath = [srcPath stringByAppendingString:@".z"];
    NSURL *nowSrcUrl = [NSURL URLWithString:srcPath];
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:nowSrcUrl];
    [request startSynchronous];
    error = [request error];
    if (error) {
        NSLog(@"%@", error);
        return NO;
    }
    int statusCode = [request responseStatusCode];
    if (statusCode != 200) {
        NSLog(@"download \"%@\" with http code %d", nowSrcUrl, statusCode);
        return NO;
    }
    
    if (![[request originalURL] isEqualTo:[request url]]) {
        NSLog(@"download wrong url %@", [request url]);
        return NO;
    }
    
    NSData *zdata = [request responseData];
    NSString *dstDirectory = [[dstUrl path] stringByDeletingLastPathComponent];
    if (![[NSFileManager defaultManager] fileExistsAtPath:dstDirectory]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:dstDirectory withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    
    BOOL ret = [self uncompressZippedData:zdata toUrl:[dstUrl path]];
    if (!ret) {
        NSLog(@"%@", nowSrcUrl);
    }
    return ret;
}

+ (BOOL)uncompressZippedData:(NSData *)compressedData toUrl:(NSString *)srcPath
{
    NSString *tmpPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[srcPath lastPathComponent]];
    [compressedData writeToFile:tmpPath atomically:YES];
    ZipArchive *anZiper = [[ZipArchive alloc] init];
    if (![anZiper UnzipOpenFile:tmpPath]) {
        NSLog(@"open zip file %@ failed!", tmpPath);
        return NO;
    }
    BOOL ret = [anZiper UnzipFileTo:[srcPath stringByDeletingLastPathComponent] overWrite:YES];
    
    if (!ret) {
        NSLog(@"unzip file %@ failed!", tmpPath);
    }
    
    [anZiper UnzipCloseFile];
    
    return ret;
}

@end
