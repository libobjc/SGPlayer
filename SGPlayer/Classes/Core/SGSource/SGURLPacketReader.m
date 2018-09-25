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

@synthesize object = _object;
@synthesize delegate = _delegate;
@synthesize options = _options;

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

- (NSError *)error
{
    return [self.formatContext error];
}

- (CMTime)duration
{
    return [self.formatContext duration];
}

- (NSDictionary *)metadata
{
    return [self.formatContext metadata];
}

- (NSArray <SGStream *> *)streams
{
    return [self.formatContext streams];
}

- (NSArray <SGStream *> *)audioStreams
{
    return [self.formatContext audioStreams];
}

- (NSArray <SGStream *> *)videoStreams
{
    return [self.formatContext videoStreams];
}

- (NSArray <SGStream *> *)otherStreams
{
    return [self.formatContext otherStreams];
}

- (NSError *)open
{
    return [self.formatContext open];
}

- (NSError *)close
{
    return [self.formatContext close];
}

- (NSError *)seekable
{
    return [self.formatContext seekable];
}

- (NSError *)seekToTime:(CMTime)time
{
    return [self.formatContext seekToTime:time];
}

- (NSError *)nextPacket:(SGPacket *)packet
{
    return [self.formatContext nextPacket:packet];
}

#pragma mark - SGFormatContextDelegate

- (BOOL)formatContextShouldAbortBlockingFunctions:(SGFormatContext *)formatContext
{
    if ([self.delegate respondsToSelector:@selector(packetReadableShouldAbortBlockingFunctions:)])
    {
        return [self.delegate packetReadableShouldAbortBlockingFunctions:self];
    }
    return NO;
}

@end
