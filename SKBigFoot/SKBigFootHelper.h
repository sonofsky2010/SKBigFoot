//
//  SKBigFootHelper.h
//  SKBigFoot
//
//  Created by li shunnian on 13-10-5.
//
//

#import <Foundation/Foundation.h>

@interface SKBigFootHelper : NSObject
+ (BOOL)downloadFileFrom:(NSURL *)srcUrl to:(NSURL *)dstUrl;
+ (BOOL)downloadZFileFrom:(NSURL *)srcUrl to:(NSURL *)dstUrl;
@end
