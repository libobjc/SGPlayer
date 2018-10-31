//
//  SGURLPacketReader.m
//  SGPlayer iOS
//
//  Created by Single on 2018/9/19.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGURLPacketReader.h"
#import "SGFormatContext.h"
#import "SGMacro.h"

@interface SGURLPacketReader () <SGFormatContextDelegate>

@property (nonatomic, copy) NSURL * URL;
@property (nonatomic, strong) SGFormatContext * formatContext;

@end

@implementation SGURLPacketReader

@synthesize object = _object;
@synthesize delegate = _delegate;

- (instancetype)initWithURL:(NSURL *)URL
{
    if (self = [super init]) {
        self.URL = URL;
        self.formatContext = [[SGFormatContext alloc] initWithURL:self.URL];
        self.formatContext.delegate = self;
    }
    return self;
}

#pragma mark - Mapping

SGGet0Map(CMTime, duration, self.formatContext)
SGGet0Map(NSDictionary *, metadata, self.formatContext)
SGGet0Map(NSArray <SGTrack *> *, tracks, self.formatContext)
SGGet0Map(NSArray <SGTrack *> *, audioTracks, self.formatContext)
SGGet0Map(NSArray <SGTrack *> *, videoTracks, self.formatContext)
SGGet0Map(NSArray <SGTrack *> *, otherTracks, self.formatContext)
SGGet0Map(NSError *, open, self.formatContext)
SGGet0Map(NSError *, close, self.formatContext)
SGGet0Map(NSError *, seekable, self.formatContext)
SGGet1Map(NSError *, seekToTime, CMTime, self.formatContext)
SGGet1Map(NSError *, nextPacket, SGPacket *, self.formatContext)

#pragma mark - SGFormatContextDelegate

- (BOOL)formatContextShouldAbortBlockingFunctions:(SGFormatContext *)formatContext
{
    if ([self.delegate respondsToSelector:@selector(packetReadableShouldAbortBlockingFunctions:)]) {
        return [self.delegate packetReadableShouldAbortBlockingFunctions:self];
    }
    return NO;
}

@end
