//
//  SKConfigure.h
//  SKBigFoot
//
//  Created by li shunnian on 13-10-5.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, SKBigFootLine) {
    SKBigFootLineTelecom,
    SKBigFootLineUnicom,
};

@interface SKConfigure : NSObject
@property (strong, nonatomic) NSString *wowPath;
@property (nonatomic, assign) SKBigFootLine line;
- (NSString *)bigfootUrl;
- (NSString *)bigFootPath:(NSString *)fileName;
- (NSString *)fileInLocalPath:(NSString *)fileName;
- (BOOL)notUpdateFlagForAddonName:(NSString *)name;
- (void)setAddonName:(NSString *)name notUpdateFlag:(BOOL)notUpdateFlag;

+ (instancetype)sharedInstance;

@end
