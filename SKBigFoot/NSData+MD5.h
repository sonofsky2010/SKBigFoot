//
//  NSData+MD5.h
//  SKBigFoot
//
//  Created by li shunnian on 12-10-14.
//
//

#import <Foundation/Foundation.h>

@interface NSData (MD5)
+(NSData *)MD5Digest:(NSData *)input;
-(NSData *)MD5Digest;

+(NSString *)MD5String:(NSData *)input;
-(NSString *)MD5String;

+(NSString *)MD5StringOfFilePath:(NSString *)filePath;
@end
