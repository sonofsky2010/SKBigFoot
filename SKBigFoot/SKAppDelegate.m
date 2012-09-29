//
//  SKAppDelegate.m
//  SKBigFoot
//
//  Created by li shunnian on 12-9-28.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "SKAppDelegate.h"
#import "NSFileManager+DirectoryLocations.h"
#include <zlib.h>

NSString *bigfootUrl = @"http://bfupdatedx.178.com/BigFoot/Interface/3.1/";
@implementation SKAppDelegate

@synthesize window = _window;
@synthesize applicationSupportDirectory;
@synthesize wowPath;
@synthesize updateFiles;
@synthesize updateInfo;
@synthesize updateProgress;
- (void)dealloc
{
    self.applicationSupportDirectory = nil;
    self.wowPath = nil;
    self.updateFiles = nil;
    self.updateProgress = nil;
    self.updateInfo = nil;
    [super dealloc];
}

- (void)unZipFile:(NSURL *)srcFileUrl to:(NSURL *)toFileUrl
{
    
}

-(BOOL)uncompressZippedData:(NSData *)compressedData toUrl:(NSString *)srcPath
{  
    NSString *tmpPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[srcPath lastPathComponent]];
    [compressedData writeToFile:tmpPath atomically:YES];
    NSTask *unZipTask = [[NSTask alloc] init];
    [unZipTask setLaunchPath:@"/usr/bin/unzip"];
    NSArray *arguments = [NSArray arrayWithObjects:tmpPath, nil];
    [unZipTask setArguments:arguments];
    [unZipTask setCurrentDirectoryPath:[srcPath stringByDeletingLastPathComponent]];
    [unZipTask launch];
    return YES;
}

- (BOOL)getFileList
{
    NSString *fileListUrlStr = [bigfootUrl stringByAppendingPathComponent:@"filelist.xml"];
    NSString *fileListLocalPath = [applicationSupportDirectory stringByAppendingPathComponent:@"filelist.xml"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:fileListLocalPath]) {
        NSString *fileListBackUpPath = [applicationSupportDirectory stringByAppendingPathComponent:@"filelist-bak.xml"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:fileListBackUpPath]) {
            [[NSFileManager defaultManager] removeItemAtPath:fileListBackUpPath error:NULL];
        }
        [[NSFileManager defaultManager] moveItemAtPath:fileListLocalPath toPath:fileListBackUpPath error:NULL];
    }
    return [self downloadFileFrom:[NSURL URLWithString:fileListUrlStr] to:[NSURL fileURLWithPath:fileListLocalPath]];
}

- (BOOL)downloadFileFrom:(NSURL *)srcUrl to:(NSURL *)dstUrl
{
    NSData *data = [NSData dataWithContentsOfURL:srcUrl];
    NSString *dstDirectory = [[dstUrl path] stringByDeletingLastPathComponent];
    if (![[NSFileManager defaultManager] fileExistsAtPath:dstDirectory]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:dstDirectory withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    return [data writeToURL:dstUrl atomically:YES];
}


- (BOOL)downloadZFileFrom:(NSURL *)srcUrl to:(NSURL *)dstUrl
{
    if (!srcUrl) {
        NSLog(@"nil");
        return NO;
    }
    NSString *srcPath = [srcUrl absoluteString];
    srcPath = [srcPath stringByAppendingFormat:@"%@.z", srcPath];
    NSURL *nowSrcUrl = [NSURL URLWithString:srcPath];
    NSData *zdata = [NSData dataWithContentsOfURL:nowSrcUrl];
    NSString *dstDirectory = [[dstUrl path] stringByDeletingLastPathComponent];
    if (![[NSFileManager defaultManager] fileExistsAtPath:dstDirectory]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:dstDirectory withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    
     BOOL ret = [zdata writeToFile:[dstUrl path] atomically:YES];//[self uncompressZippedData:zdata toUrl:[dstUrl path]];
    if (!ret) {
        NSLog(@"%@", nowSrcUrl);
    }
    return ret;
}
- (void)alertMessage:(NSString *)message
{
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    alert.messageText = message;
    [alert runModal];
}

- (BOOL)chooseWowPath
{
    NSString *configPath = [applicationSupportDirectory stringByAppendingPathComponent:@"config.pxlist"];
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanChooseFiles:NO];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setMessage:@"请选择魔兽世界所在文件夹"];
    if ([openPanel runModal] == NSFileHandlingPanelOKButton) {
        self.wowPath = [[openPanel URL] path];
        NSDictionary *dict = [NSDictionary dictionaryWithObject:wowPath forKey:@"wowpath"];
        [dict writeToFile:configPath atomically:YES];
        return YES;
    }
    return NO;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    self.applicationSupportDirectory = [[NSFileManager defaultManager] applicationSupportDirectory];
    if (!applicationSupportDirectory) {
        [self alertMessage:@"创建Application Support下的文件夹失败"];
        exit(1);
    }
    
    NSString *configPath = [applicationSupportDirectory stringByAppendingPathComponent:@"config.pxlist"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:configPath]) {
        if (![self chooseWowPath]) {
            [self alertMessage:@"没有选择目录"];
            exit(1);
        }
    } else {
        NSDictionary *configDict = [NSDictionary dictionaryWithContentsOfFile:configPath];
        if (!configPath || 
            !(self.wowPath = [configDict objectForKey:@"wowpath"], wowPath) ||
            ![[NSFileManager defaultManager] fileExistsAtPath:wowPath]) {
            if (![self chooseWowPath]) {
                [self alertMessage:@"没有选择目录"];
                exit(1);
            }
        }
    }
    [self.window makeKeyAndOrderFront:nil];
    self.updateInfo = @"";

    [self.updateProgress startAnimation:self];
    [self.updateProgress setMinValue:0.0f];
    [self.updateProgress setMaxValue:1.0f];
    [self.updateProgress setDoubleValue:0.0];
}

- (IBAction)updateAddOn:(id)sender
{
    [sender setEnabled:NO];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        [self.updateProgress setMinValue:0.0];
        self.updateInfo = @"正在下载更新列表";
        if (![self getFileList]) {
            self.updateInfo = @"下载插件目录失败!";
            return;
        }
        
        self.updateFiles = [self mergerUpdateFiles];
        [self.updateProgress setMaxValue:[updateFiles count]];
        [self.updateProgress setDoubleValue:0.0f];
    
        [self downloadFileList:updateFiles];
        [sender setEnabled:YES];
    });
}
- (void)downloadFileList:(NSArray *)fileLists
{
    for (NSString *fileName in fileLists) {
        self.updateInfo = fileName;
        NSString *bfPath = [self bigFootPath:fileName];
        NSString *localPath = [self fileInLocalPath:fileName];
        if (![self downloadZFileFrom:[NSURL URLWithString:[bfPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] to:[NSURL fileURLWithPath:localPath]]) {
            self.updateInfo = [NSString stringWithFormat:@"下载 %@ 失败", fileName];
            return;
        } else {
            [self.updateProgress incrementBy:1.0];
        }
    }
    self.updateInfo = @"更新完成";
}

- (NSString *)bigFootPath:(NSString *)fileName
{
    return [bigfootUrl stringByAppendingFormat:@"/Interfaces/AddOns/%@", fileName];
}
- (NSString *)fileInLocalPath:(NSString *)fileName
{
    return [wowPath stringByAppendingFormat:@"/Interfaces/AddOns/%@", fileName];
}
- (NSMutableArray *)mergerUpdateFiles
{
    NSDictionary *newFildDict = [self newFileDict];
    NSDictionary *oldFileDict = [self oldFileDict];
    NSMutableArray *retArray = [NSMutableArray array];
    for (NSString *key in [newFildDict allKeys]) {
        NSMutableDictionary *newAddon = [newFildDict objectForKey:key];
        NSMutableDictionary *oldAddon = [oldFileDict objectForKey:key];
        if (!oldAddon) {
            [retArray addObjectsFromArray:[newAddon allKeys]];
        } else {
            for (NSString *oneNewFile in newAddon) {
                NSString *newCheckSum = [newAddon objectForKey:oneNewFile];
                NSString *oldCheckSum = [oldAddon objectForKey:oneNewFile];
                if (!oldCheckSum || ![newCheckSum isEqualToString:oldCheckSum]) {
                    [retArray addObject:oneNewFile];
                } else {
                    NSString *filePath = [wowPath stringByAppendingFormat:@"/Interfaces/AddOns/%@", oneNewFile];
                    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
                        [retArray addObject:oneNewFile];
                    }
                }
            }
        }
    }
    return retArray;
}

- (NSDictionary *)newFileDict
{
    return [self fileDictFromFileList:[applicationSupportDirectory stringByAppendingPathComponent:@"filelist.xml"]];
}

- (NSDictionary *)oldFileDict
{
    return [self fileDictFromFileList:[applicationSupportDirectory stringByAppendingPathComponent:@"filelist-bak.xml"]];
}

- (NSDictionary *)fileDictFromFileList:(NSString *)fileListPath
{
    NSError *error = nil;
    NSXMLDocument *doc = [[NSXMLDocument alloc] initWithContentsOfURL:[NSURL fileURLWithPath:fileListPath] options:0 error:&error];
    if (!doc) {
        return nil;
    }
    if (error) {
        NSLog(@"%@", error);
    }
    
    NSMutableDictionary *retDict = [NSMutableDictionary dictionary];
    NSXMLElement *rootElement = [doc rootElement];
    NSArray *addons = [rootElement children];
    for (NSXMLElement *element in addons) {
        NSString *addOnName = [[element attributeForName:@"name"] stringValue];
        NSMutableDictionary *fileDict = [NSMutableDictionary dictionary];
        for (NSXMLElement *oneFileElement in [element children]) {
            NSString *filePath = [[oneFileElement attributeForName:@"path"] stringValue];
            NSString *checkSum = [[oneFileElement attributeForName:@"checksum"] stringValue];
            if (filePath && checkSum) {
                NSString *nowPath = [addOnName stringByAppendingPathComponent:filePath];
                nowPath = [nowPath stringByReplacingOccurrencesOfString:@"\\" withString:@"/"];
                [fileDict setObject:checkSum forKey:nowPath];
                [retDict setObject:fileDict forKey:addOnName];
            }
        }
    }
    return retDict;
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag
{
    [self.window makeKeyAndOrderFront:nil];
}
@end
