//
//  SKMainWindowController.h
//  SKBigFoot
//
//  Created by li shunnian on 14/10/19.
//
//

#import <Cocoa/Cocoa.h>

@interface SKMainWindowController : NSWindowController
@property (strong) IBOutlet NSProgressIndicator *updateProgress;
@property (strong) IBOutlet NSWindow *chooseServerWindow;
@property (strong) IBOutlet NSButton *settingButton;
@property (strong) IBOutlet NSButton *updateButton;
@property (copy) NSString *updateInfo;
@property (weak) IBOutlet NSWindow *settingWindow;
@property (weak) IBOutlet NSTextField *pathTextField;
@property (weak) IBOutlet NSPopUpButton *linePopUpButton;

- (BOOL)chooseWowPath;
- (void)loadAddonInfos;
@end
