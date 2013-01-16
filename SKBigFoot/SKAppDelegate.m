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
#import "ASIHTTPRequest.h"
#import "ASIDataDecompressor.h"
#import "ZipArchive.h"
#import "NSData+MD5.h"
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
    ZipArchive *anZiper = [[[ZipArchive alloc] init] autorelease];
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

- (BOOL)getFileList
{
    NSString *fileListUrlStr = [bigfootUrl stringByAppendingString:@"filelist.xml"];
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


- (BOOL)downloadZFileFrom:(NSURL *)srcUrl to:(NSURL *)dstUrl
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
        
        self.updateInfo = @"检查哪些插件需要更新";
        self.updateFiles = [self mergerUpdateFiles];
        [self.updateProgress setMaxValue:[updateFiles count]];
        [self.updateProgress setDoubleValue:0.0f];
        NSLog(@"%@", updateFiles);
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
    return [bigfootUrl stringByAppendingFormat:@"/Interface/AddOns/%@", fileName];
}
- (NSString *)fileInLocalPath:(NSString *)fileName
{
    return [wowPath stringByAppendingFormat:@"/Interface/AddOns/%@", fileName];
}
- (NSMutableArray *)mergerUpdateFiles
{
    NSDictionary *newFildDict = [self newFileDict];
    NSMutableArray *retArray = [NSMutableArray array];
    for (NSString *key in [newFildDict allKeys]) {
        NSMutableDictionary *newAddon = [newFildDict objectForKey:key];
        for (NSString *fileKey in [newAddon allKeys]) {
            NSString *filePath = [wowPath stringByAppendingFormat:@"/Interface/AddOns/%@", fileKey];
            if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
                [retArray addObject:fileKey];
                
            } else {
                NSString *md5String = [NSData MD5StringOfFilePath:filePath];
                NSString *checkSum = [newAddon objectForKey:fileKey];
                if (![md5String isEqualToString:checkSum]) {
                    [retArray addObject:fileKey];
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
        NSString *title = [[element attributeForName:@"Title-zhCN"] stringValue];
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
