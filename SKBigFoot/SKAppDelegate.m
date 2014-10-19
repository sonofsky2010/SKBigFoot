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
#import "SKBigFootHelper.h"
#import "SKConfigure.h"

NSString *bigfootUrl = @"http://bfupdatedx.178.com/BigFoot/Interface/3.1/";
@implementation SKAppDelegate






- (void)alertMessage:(NSString *)message
{
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = message;
    [alert runModal];
}



- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
//    self.applicationSupportDirectory = [[NSFileManager defaultManager] applicationSupportDirectory];
//    if (!applicationSupportDirectory) {
//        [self alertMessage:@"创建Application Support下的文件夹失败"];
//        exit(1);
//    }
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:[SKConfigure sharedInstance].wowPath]) {
        [self.mainWindowController chooseWowPath];
    }
    [self.mainWindowController loadAddonInfos];

    [self.window makeKeyAndOrderFront:nil];

}
//
//- (NSDictionary *)newFileDict
//{
//    return [self fileDictFromFileList:[applicationSupportDirectory stringByAppendingPathComponent:@"filelist.xml"]];
//}
//
//- (NSDictionary *)oldFileDict
//{
//    return [self fileDictFromFileList:[applicationSupportDirectory stringByAppendingPathComponent:@"filelist-bak.xml"]];
//}
//

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag
{
    [self.window makeKeyAndOrderFront:nil];
    return YES;
}

@end
