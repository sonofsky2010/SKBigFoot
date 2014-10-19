//
//  SKAddOn.m
//  SKBigFoot
//
//  Created by li shunnian on 12-9-28.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "SKAddOn.h"
#import "SKConfigure.h"
#import "NSData+MD5.h"
#import "SKBigFootHelper.h"
@interface SKAddOn ()
{
    NSMutableArray *_needUpdateFiles;
}

@end

@interface SKAddOnFile ()

- (BOOL)needUpdate;

- (BOOL)download;

@end

@implementation SKAddOn

- (BOOL)needUpdate
{
    BOOL ret = NO;
    
    if (_notUpdateFlag) {
        return NO;
    }
    
    _needUpdateFiles = [NSMutableArray array];
    
    for (SKAddOnFile *addOnFile in _files) {
        if ([addOnFile needUpdate]) {
            ret = YES;
            [_needUpdateFiles addObject:addOnFile];
        }
    }
    
    return ret;
}

- (BOOL)downloadAddonWithUpdateBlock:(SKAddonDownloadBlock)block
{
    NSString *wowPath = [SKConfigure sharedInstance].wowPath;
    NSString *nowAddonPath = [wowPath stringByAppendingFormat:@"Interface/AddOns/%@", _addonName];
    
    NSString *backupPath = [wowPath stringByAppendingPathComponent:@"/Interface/.AddOns"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:backupPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:backupPath withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    
    NSString *backupAddonName = [backupPath stringByAppendingPathComponent:_addonName];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:backupAddonName]) {
        [[NSFileManager defaultManager] removeItemAtPath:backupAddonName error:NULL];
    }
    
    [[NSFileManager defaultManager] copyItemAtPath:nowAddonPath toPath:backupAddonName error:NULL];
    
    for (SKAddOnFile *addOnFile in _needUpdateFiles) {
        if (block) {
            block(addOnFile.fileName);
        }
        
        if (![addOnFile download]) {
            [[NSFileManager defaultManager] removeItemAtPath:nowAddonPath error:NULL];
            [[NSFileManager defaultManager] copyItemAtPath:backupAddonName toPath:nowAddonPath error:NULL];
            
            return NO;
        }
    }
    
    return YES;
}

- (NSUInteger)updateFilesCount
{
    return [_needUpdateFiles count];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _files = [NSMutableArray array];
    }
    return self;
}

@end



@implementation SKAddOnFile

- (BOOL)needUpdate
{
        
    NSString *wowPath = [SKConfigure sharedInstance].wowPath;
    
    NSString *filePath = [wowPath stringByAppendingFormat:@"/Interface/AddOns/%@/%@", _addon.addonName, _fileName];
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        return YES;
    }
    
    NSString *md5String = [NSData MD5StringOfFilePath:filePath];
    if (![md5String isEqualToString:_hashString]) {
        return YES;
    }
    
    return NO;
}

- (BOOL)download
{
    NSString *filePath = [NSString stringWithFormat:@"%@/%@", _addon.addonName, _fileName];
    NSString *bfPath = [[SKConfigure sharedInstance] bigFootPath:filePath];
    NSString *localPath = [[SKConfigure sharedInstance] fileInLocalPath:filePath];
    if (![SKBigFootHelper downloadZFileFrom:[NSURL URLWithString:[bfPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] to:[NSURL fileURLWithPath:localPath]]) {
        return NO;
    }
    
    return YES;
}

@end