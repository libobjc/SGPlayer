//
//  SGURLPreview.m
//  SGPlayer
//
//  Created by Single on 2018/11/14.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGURLPreview.h"
#import "SGFormatContext.h"
#import "SGMacro.h"

@interface SGURLPreview () <SGFormatContextDelegate>

@property (nonatomic, copy) NSURL * URL;
@property (nonatomic, strong) SGFormatContext * context;

@end

@implementation SGURLPreview

- (instancetype)initWithURL:(NSURL *)URL
{
    if (self = [super init]) {
        _URL = URL;
        _context = [[SGFormatContext alloc] initWithURL:URL];
        _context.delegate = self;
    }
    return self;
}

- (void)dealloc
{
    [_context close];
}

#pragma mark - Mapping

SGGet0Map(CMTime, duration, _context)
SGGet0Map(NSError *, seekable, _context)
SGGet0Map(NSDictionary *, metadata, _context)
SGGet0Map(NSArray <SGTrack *> *, tracks, _context)
SGGet0Map(NSArray <SGTrack *> *, audioTracks, _context)
SGGet0Map(NSArray <SGTrack *> *, videoTracks, _context)
SGGet0Map(NSArray <SGTrack *> *, otherTracks, _context)
SGGet0Map(NSError *, open, _context)
SGGet0Map(NSError *, close, _context)

#pragma mark - SGFormatContextDelegate

- (BOOL)formatContextShouldAbortBlockingFunctions:(SGFormatContext *)formatContext
{
    if ([_delegate respondsToSelector:@selector(URLPreviewShouldAbortBlockingFunctions:)]) {
        return [_delegate URLPreviewShouldAbortBlockingFunctions:self];
    }
    return NO;
}

@end
