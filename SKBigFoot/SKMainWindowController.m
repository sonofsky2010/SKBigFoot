//
//  SKMainWindowController.m
//  SKBigFoot
//
//  Created by li shunnian on 14/10/19.
//
//

#import "SKMainWindowController.h"
#import "SKAddOn.h"
#import "SKConfigure.h"
#import "SKBigFootHelper.h"

@interface SKMainWindowController ()<NSTableViewDataSource, NSTableViewDelegate>
{
    NSString *tempDirectoryPath;
    NSMutableArray *_addons;
    NSString *_fileListPath;
}
@property (weak) IBOutlet NSTableView *addonsTableView;

@end

@implementation SKMainWindowController

- (void)awakeFromNib
{
    [self.updateProgress startAnimation:self];
    [self.updateProgress setMinValue:0.0f];
    [self.updateProgress setMaxValue:1.0f];
    [self.updateProgress setDoubleValue:0.0];
    
    [self.updateButton setEnabled:NO];
    [self.settingButton setEnabled:NO];
}

- (void)loadAddonInfos
{
    self.updateInfo = @"获取插件信息...";
    tempDirectoryPath = NSTemporaryDirectory();
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if ([self getFileList]) {
        }
        _addons = [self addonsFromFileList:_fileListPath];
        [self updateAddonsState];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.addonsTableView reloadData];
        });
        self.updateInfo = @"";
        [self.updateButton setEnabled:YES];
        [self.settingButton setEnabled:YES];
    });
}

- (void)updateAddonsState
{
    SKConfigure *configure = [SKConfigure sharedInstance];
    for (SKAddOn *addon in _addons) {
        BOOL notUpdateFlag = [configure notUpdateFlagForAddonName:addon.addonName];
        addon.notUpdateFlag = notUpdateFlag;
    }

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
        NSArray *updateAddons = [self checkUpdateAddons];
        NSUInteger updateCount = 0;
        for (SKAddOn *addOn in updateAddons) {
            updateCount += [addOn updateFilesCount];
        }
        
        [self.updateProgress setMaxValue:updateCount];
        [self.updateProgress setDoubleValue:0.0f];
        
        [self downloadAddons:updateAddons];
        [sender setEnabled:YES];
    });
}

- (void)downloadAddons:(NSArray *)addons
{
    __block NSUInteger fileCount = 0;
    for (SKAddOn *addOn in addons) {
        if (![addOn downloadAddonWithUpdateBlock:^(NSString *downloadName) {
            fileCount ++;
            [self.updateProgress setDoubleValue:fileCount];
            self.updateInfo = downloadName;
        }]) {
            self.updateInfo = @"更新失败";
            [self.updateButton setEnabled:YES];
            [self.settingButton setEnabled:YES];
            return;
        };
    }
    
    [self.updateButton setEnabled:YES];
    [self.settingButton setEnabled:YES];
    
    self.updateInfo = @"更新完成";
            
}

- (NSArray *)checkUpdateAddons
{

    
    NSMutableArray *needUpdateAddons = [NSMutableArray array];
    for (SKAddOn *addOn in _addons) {
        if ([addOn needUpdate]) {
            [needUpdateAddons addObject:addOn];
        }
    }
    
    return needUpdateAddons;
}


- (BOOL)chooseWowPath
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanChooseFiles:NO];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setMessage:@"请选择魔兽世界所在文件夹"];
    if ([openPanel runModal] == NSFileHandlingPanelOKButton) {
         NSString *wowPath = [[openPanel URL] path];
        if ([wowPath length] > 0) {
            [[SKConfigure sharedInstance] setWowPath:wowPath];
        }
        return YES;
    }
    return NO;
}

- (BOOL)getFileList
{
    NSString *bigFootPath = [[SKConfigure sharedInstance] bigfootUrl];
    NSString *fileListUrlStr = [bigFootPath stringByAppendingString:@"filelist.xml"];
    NSString *fileListLocalPath = [tempDirectoryPath stringByAppendingPathComponent:@"filelist.xml"];
    _fileListPath = fileListLocalPath;
    return [SKBigFootHelper downloadFileFrom:[NSURL URLWithString:fileListUrlStr] to:[NSURL fileURLWithPath:fileListLocalPath]];
}

- (NSMutableArray *)addonsFromFileList:(NSString *)fileListPath
{
    NSError *error = nil;
    NSXMLDocument *doc = [[NSXMLDocument alloc] initWithContentsOfURL:[NSURL fileURLWithPath:fileListPath] options:0 error:&error];
    if (!doc) {
        return nil;
    }
    if (error) {
        NSLog(@"%@", error);
    }
    
    NSXMLElement *rootElement = [doc rootElement];
    NSArray *addons = [rootElement children];
    NSMutableArray *allAddons = [NSMutableArray array];
    
    for (NSXMLElement *element in addons) {
        SKAddOn *addOn = [[SKAddOn alloc] init];
        NSString *addOnName = [[element attributeForName:@"name"] stringValue];
        NSString *title = [[element attributeForName:@"Title-zhCN"] stringValue];
        
        addOn.addonName = addOnName;
        addOn.title = title;
        NSMutableString *notes = [[[element attributeForName:@"Notes-zhCN"] stringValue] mutableCopy];
        [notes replaceOccurrencesOfString:@"\n" withString:@"; " options:0 range:NSMakeRange(0, notes.length)];
        
        addOn.notes = notes;
        
        [allAddons addObject:addOn];
        
        for (NSXMLElement *oneFileElement in [element children]) {
            
            
            NSString *filePath = [[oneFileElement attributeForName:@"path"] stringValue];
            NSString *checkSum = [[oneFileElement attributeForName:@"checksum"] stringValue];
            if (filePath && checkSum) {
                filePath = [filePath stringByReplacingOccurrencesOfString:@"\\" withString:@"/"];
                
                SKAddOnFile *file = [[SKAddOnFile alloc] init];
                file.fileName = filePath;
                file.hashString = checkSum;
                file.addon = addOn;
                [addOn.files addObject:file];
            }
        }
    }
    return allAddons;
}
- (IBAction)allSelect:(id)sender {
    for (SKAddOn *addOn in _addons) {
        addOn.notUpdateFlag = NO;
        [[SKConfigure sharedInstance] setAddonName:addOn.addonName notUpdateFlag:NO];
    }
    [self.addonsTableView reloadData];
}
- (IBAction)allDeselect:(id)sender {
    for (SKAddOn *addOn in _addons) {
        addOn.notUpdateFlag = YES;
        [[SKConfigure sharedInstance] setAddonName:addOn.addonName notUpdateFlag:YES];
    }
    [self.addonsTableView reloadData];
}

- (IBAction)showSetting:(id)sender {
    
    SKConfigure *configure = [SKConfigure sharedInstance];
    [self.linePopUpButton selectItemAtIndex:configure.line];
    self.pathTextField.stringValue = configure.wowPath;
    
    [NSApp beginSheet:self.settingWindow
       modalForWindow:self.window
        modalDelegate:nil
       didEndSelector:nil
          contextInfo:NULL];
}

- (IBAction)cancelSheet:(id)sender {
    [NSApp endSheet:self.settingWindow];
    [self.settingWindow orderOut:sender];
}

- (IBAction)chooseWowPath:(id)sender {
    [self chooseWowPath];
    self.pathTextField.stringValue = [SKConfigure sharedInstance].wowPath;
}
- (IBAction)selectedIndex:(id)sender {
    [SKConfigure sharedInstance].line = self.linePopUpButton.indexOfSelectedItem;
}

#pragma mark tableview datasource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [_addons count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    SKAddOn *addOn = [_addons objectAtIndex:row];
    if ([tableColumn.identifier isEqualToString:@"checkbox"]) {
        return @(!addOn.notUpdateFlag);
    } else if ([tableColumn.identifier isEqualToString:@"name"]) {
        return addOn.title;
    } else if ([tableColumn.identifier isEqualToString:@"notes"]) {
        return addOn.notes;
    }
    
    return nil;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    if ([tableColumn.identifier isEqualToString:@"checkbox"]) {
        SKAddOn *addOn = [_addons objectAtIndex:row];
        addOn.notUpdateFlag = ![object boolValue];
        [[SKConfigure sharedInstance] setAddonName:addOn.addonName notUpdateFlag:addOn.notUpdateFlag];
    }
}

@end
