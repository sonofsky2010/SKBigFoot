//
//  SKAppDelegate.h
//  SKBigFoot
//
//  Created by li shunnian on 12-9-28.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SKConfigure.h"
#import "SKMainWindowController.h"
#import "SKMainMenuController.h"

@interface SKAppDelegate : NSObject <NSApplicationDelegate, NSURLDownloadDelegate>

@property (weak) IBOutlet NSWindow *window;
@property (strong) SKConfigure *configure;
@property (strong) NSMutableDictionary *filterList;

@property (weak) IBOutlet SKMainWindowController *mainWindowController;
@property (weak) IBOutlet SKMainMenuController *mainMenuWindowController;
@end
