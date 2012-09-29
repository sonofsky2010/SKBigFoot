//
//  SKAppDelegate.h
//  SKBigFoot
//
//  Created by li shunnian on 12-9-28.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SKAppDelegate : NSObject <NSApplicationDelegate, NSURLDownloadDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (copy) NSString *applicationSupportDirectory;
@property (copy) NSString *wowPath;
@property (retain) NSMutableArray *updateFiles;
@property (retain) IBOutlet NSProgressIndicator *updateProgress;
@property (copy) NSString *updateInfo;
@property (retain) IBOutlet NSWindow *chooseServerWindow;
@end
