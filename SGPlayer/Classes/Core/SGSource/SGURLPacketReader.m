//
//  SGURLPacketReader.m
//  SGPlayer iOS
//
//  Created by Single on 2018/9/19.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGURLPacketReader.h"
#import "SGFormatContext.h"

@interface SGURLPacketReader () <SGFormatContextDelegate>

@property (nonatomic, copy) NSURL * URL;
@property (nonatomic, strong) SGFormatContext * formatContext;

@end

@implementation SGURLPacketReader

- (instancetype)initWithURL:(NSURL *)URL
{
    if (self = [super init])
    {
        self.URL = URL;
        self.formatContext = [[SGFormatContext alloc] initWithURL:self.URL];
        self.formatContext.delegate = self;
    }
    return self;
}

- (BOOL)open
{
    return [self.formatContext open];
}

- (BOOL)close
{
    return [self.formatContext close];
}

- (BOOL)seekable
{
    return [self.formatContext seekable];
}

- (BOOL)seekableToTime:(CMTime)time
{
    return [self.formatContext seekableToTime:time];
}

- (BOOL)seekToTime:(CMTime)time
{
    return [self seekToTime:time completionHandler:nil];
}

- (BOOL)seekToTime:(CMTime)time completionHandler:(void(^)(CMTime time, NSError * error))completionHandler
{
    NSError * error = [self.formatContext seekToTime:time];
    if (completionHandler)
    {
        completionHandler(time, error);
    }
    return !error;
}

- (NSError *)nextPacket:(SGPacket *)packet
{
    return [self.formatContext nextPacket:packet];
}

#pragma mark - SGFormatContextDelegate

- (BOOL)formatContextShouldAbortBlockingFunctions:(SGFormatContext *)formatContext
{
    if ([self.delegate respondsToSelector:@selector(packetReaderShouldAbortBlockingFunctions:)])
    {
        return [self.delegate packetReaderShouldAbortBlockingFunctions:self];
    }
    return NO;
}

@end
