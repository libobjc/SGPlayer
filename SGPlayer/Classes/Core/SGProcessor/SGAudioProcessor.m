//
//  SGAudioProcessor.m
//  SGPlayer
//
//  Created by Single on 2018/11/28.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGAudioProcessor.h"
#import "SGAudioFormatter.h"
#import "SGAudioMixer.h"

@interface SGAudioProcessor ()

{
    SGAudioMixer *_mixer;
    NSMutableDictionary<NSNumber *, SGAudioFormatter *> *_formatters;
}

@end

@implementation SGAudioProcessor

- (instancetype)initWithAudioDescription:(SGAudioDescription *)audioDescription
{
    if (self = [super init]) {
        self->_audioDescription = [audioDescription copy];
    }
    return self;
}

#pragma mark - Setter & Getter

- (NSArray<SGTrack *> *)tracks
{
    return self->_mixer.tracks;
}

- (NSArray<NSNumber *> *)weights
{
    return self->_mixer.weights;
}

- (BOOL)setTracks:(NSArray<SGTrack *> *)tracks weights:(NSArray<NSNumber *> *)weights
{
    if (tracks.count > 0) {
        [self setupWithTracks:tracks weights:weights];
    } else {
        self->_mixer.weights = weights;
    }
    return YES;
}

#pragma mark - Setup

- (void)setupWithTracks:(NSArray<SGTrack *> *)tracks weights:(NSArray<NSNumber *> *)weights
{
    self->_mixer = [[SGAudioMixer alloc] initWithAudioDescription:self->_audioDescription
                                                           tracks:tracks];
    self->_mixer.weights = weights;
    self->_formatters = [NSMutableDictionary dictionary];
    for (SGTrack *i in tracks) {
        SGAudioFormatter *obj = [[SGAudioFormatter alloc] initWithAudioDescription:self->_audioDescription];
        [self->_formatters setObject:obj forKey:@(i.index)];
    }
}

#pragma mark - Control

- (SGAudioFrame *)putFrame:(SGAudioFrame *)frame
{
    if (![self->_mixer.tracks containsObject:frame.track]) {
        [frame unlock];
        return nil;
    }
    SGAudioFormatter *formatter = [self->_formatters objectForKey:@(frame.track.index)];
    frame = [formatter format:frame];
    if (frame) {
        return [self->_mixer putFrame:frame];
    }
    return nil;
}

- (SGAudioFrame *)finish
{
    return [self->_mixer finish];
}

- (SGCapacity *)capacity
{
    return self->_mixer.capacity;
}

- (void)flush
{
    [self setupWithTracks:self.tracks weights:self.weights];
}

- (void)close
{
    self->_mixer = nil;
    self->_formatters = nil;
}

@end
