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
@property (nonatomic, strong) SGFormatContext * context;

@end

@implementation SGURLPacketReader

@synthesize object = _object;
@synthesize delegate = _delegate;

- (instancetype)initWithURL:(NSURL *)URL
{
    if (self = [super init]) {
        _URL = URL;
        _context = [[SGFormatContext alloc] initWithURL:URL];
        _context.delegate = self;
    }
    return self;
}

#pragma mark - Mapping

SGGet0Map(CMTime, duration, _context)
SGGet0Map(NSDictionary *, metadata, _context)
SGGet0Map(NSArray <SGTrack *> *, tracks, _context)
SGGet0Map(NSArray <SGTrack *> *, audioTracks, _context)
SGGet0Map(NSArray <SGTrack *> *, videoTracks, _context)
SGGet0Map(NSArray <SGTrack *> *, otherTracks, _context)
SGGet0Map(NSError *, open, _context)
SGGet0Map(NSError *, close, _context)
SGGet0Map(NSError *, seekable, _context)
SGGet1Map(NSError *, seekToTime, CMTime, _context)
SGGet1Map(NSError *, nextPacket, SGPacket *, _context)

#pragma mark - SGFormatContextDelegate

- (BOOL)formatContextShouldAbortBlockingFunctions:(SGFormatContext *)formatContext
{
    if ([_delegate respondsToSelector:@selector(packetReadableShouldAbortBlockingFunctions:)]) {
        return [_delegate packetReadableShouldAbortBlockingFunctions:self];
    }
    return NO;
}

@end
