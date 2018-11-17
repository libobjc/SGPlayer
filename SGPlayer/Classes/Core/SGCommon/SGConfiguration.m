//
//  SGConfiguration.m
//  SGPlayer iOS
//
//  Created by Single on 2018/10/29.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGConfiguration.h"
#import "SGMapping.h"

@implementation SGConfiguration

+ (instancetype)shared
{
    static SGConfiguration * obj = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        obj = [[SGConfiguration alloc] init];
    });
    return obj;
}

- (instancetype)init
{
    if (self = [super init]) {
        self.formatContextOptions = @{@"user-agent" : @"SGPlayer",
                                      @"timeout" : @(20 * 1000 * 1000),
                                      @"reconnect" : @(1)};
        self.codecContextOptions = nil;
        self.threadsAuto = YES;
        self.refcountedFrames = YES;
        self.hardwareDecodeH264 = YES;
        self.hardwareDecodeH265 = YES;
        self.preferredPixelFormat = SGPixelFormatFF2AV(AV_PIX_FMT_NV12);
    }
    return self;
}

@end
