//
//  SKAddOn.h
//  SKBigFoot
//
//  Created by li shunnian on 12-9-28.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@interface SKAddOnFile : NSObject
@property (copy) NSString *fileName;
@property (copy) NSString *hashString;
@end
@interface SKAddOn : NSObject
@property (copy) NSString *addonName;
@property (retain) NSMutableArray *files;
@end
