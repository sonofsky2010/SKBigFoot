//
//  SKConfigure.m
//  SKBigFoot
//
//  Created by li shunnian on 13-10-5.
//
//

#import "SKConfigure.h"

@interface SKConfigure ()
{
    NSMutableDictionary *_updateInfos;
}
@end

@implementation SKConfigure

+ (instancetype)sharedInstance
{
    static SKConfigure * instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[SKConfigure alloc] init];
    });
    
    return instance;
}

- (id)init
{
    self = [super init];
    if (self) {
        _wowPath = [[NSUserDefaults standardUserDefaults] objectForKey:@"wowPath"];
        _line = [[[NSUserDefaults standardUserDefaults] objectForKey:@"line"] integerValue];
    }
    
    return self;
}

- (void)setWowPath:(NSString *)wowPath
{
    _wowPath = wowPath;
    [[NSUserDefaults standardUserDefaults] setObject:wowPath forKey:@"wowPath"];
}

- (NSString *)bigfootUrl
{
    if (_line == SKBigFootLineTelecom) {
        return @"http://bfupdatedx.178.com/BigFoot/Interface/3.1/";
    } else {
        return @"http://bfupdatewt.178.com/BigFoot/Interface/3.1/";
    }
}

- (void)setLine:(SKBigFootLine)line
{
    _line = line;
    [[NSUserDefaults standardUserDefaults] setObject:@(line) forKey:@"line"];
}



- (NSString *)bigFootPath:(NSString *)fileName
{
    return [[self bigfootUrl] stringByAppendingFormat:@"/Interface/AddOns/%@", fileName];
}
- (NSString *)fileInLocalPath:(NSString *)fileName
{
    return [_wowPath stringByAppendingFormat:@"/Interface/AddOns/%@", fileName];
}

- (BOOL)notUpdateFlagForAddonName:(NSString *)name
{
    if (!_updateInfos) {
        _updateInfos = [[[NSUserDefaults standardUserDefaults] objectForKey:@"updateInfos"] mutableCopy];
        
        if (!_updateInfos) {
            _updateInfos = [NSMutableDictionary dictionary];
        }
    }
    
    return [[_updateInfos objectForKey:name] boolValue];
}

- (void)setAddonName:(NSString *)name notUpdateFlag:(BOOL)notUpdateFlag
{
    if (!_updateInfos) {
        _updateInfos = [[[NSUserDefaults standardUserDefaults] objectForKey:@"updateInfos"] mutableCopy];
        
        if (!_updateInfos) {
            _updateInfos = [NSMutableDictionary dictionary];
        }
    }
    
    [_updateInfos setObject:@(notUpdateFlag) forKey:name];
    [[NSUserDefaults standardUserDefaults] setObject:_updateInfos forKey:@"updateInfos"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
