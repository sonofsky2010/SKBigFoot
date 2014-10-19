//
//  SKAddOn.h
//  SKBigFoot
//
//  Created by li shunnian on 12-9-28.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^SKAddonDownloadBlock)(NSString *downloadFileName);

@interface SKAddOn : NSObject
@property (copy) NSString *addonName;
@property (copy) NSString *title;
@property (strong) NSMutableArray *files;
@property (strong) NSString *notes;
@property (nonatomic, assign) BOOL notUpdateFlag;

- (BOOL)downloadAddonWithUpdateBlock:(SKAddonDownloadBlock)block;
- (NSUInteger)updateFilesCount;
- (BOOL)needUpdate;
@end

@interface SKAddOnFile : NSObject
@property (copy) NSString *fileName;
@property (copy) NSString *hashString;
@property (weak) SKAddOn *addon;

@end

