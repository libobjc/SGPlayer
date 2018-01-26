//
//  SGFFFrame.m
//  SGPlayer
//
//  Created by Single on 06/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import "SGFFFrame2.h"
#import "SGFFTools.h"

@implementation SGFFFrame2

- (void)startPlaying
{
    self->_playing = YES;
    if ([self.delegate respondsToSelector:@selector(frameDidStartPlaying:)]) {
        [self.delegate frameDidStartPlaying:self];
    }
}

- (void)stopPlaying
{
    self->_playing = NO;
    if ([self.delegate respondsToSelector:@selector(frameDidStopPlaying:)]) {
        [self.delegate frameDidStopPlaying:self];
    }
}

- (void)cancel
{
    self->_playing = NO;
    if ([self.delegate respondsToSelector:@selector(frameDidCancel:)]) {
        [self.delegate frameDidCancel:self];
    }
}

@end


@implementation SGFFSubtileFrame

- (SGFFFrameType2)type
{
    return SGFFFrameType2Subtitle;
}

@end


@implementation SGFFArtworkFrame

- (SGFFFrameType2)type
{
    return SGFFFrameTypeArtwork;
}

@end
