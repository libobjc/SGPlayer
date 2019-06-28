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

@property (nonatomic, strong, readonly) SGAudioMixer *mixer;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSNumber *, SGAudioFormatter *> *formatters;

@end

@implementation SGAudioProcessor

#pragma mark - Setter & Getter

- (void)setSelection:(SGAudioSelection *)selection actionFlags:(SGAudioSelectionActionFlags)actionFlags descriptor:(SGAudioDescriptor *)descriptor
{
    self->_selection = [selection copy];
    if (actionFlags & SGAudioSelectionAction_Tracks) {
        self->_mixer = [[SGAudioMixer alloc] initWithTracks:self->_selection.tracks
                                                    weights:self->_selection.weights
                                                 descriptor:descriptor];
        self->_mixer.weights = self->_selection.weights;
        self->_formatters = [NSMutableDictionary dictionary];
        for (SGTrack *track in self->_selection.tracks) {
            SGAudioFormatter *formatter = [[SGAudioFormatter alloc] init];
            formatter.descriptor = descriptor;
            [self->_formatters setObject:formatter forKey:@(track.index)];
        }
    } else if (actionFlags & SGAudioSelectionAction_Weights) {
        self->_mixer.weights = self->_selection.weights;
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

- (SGCapacity)capacity
{
    return self->_mixer.capacity;
}

- (void)flush
{
    [self->_mixer flush];
    [self->_formatters enumerateKeysAndObjectsUsingBlock:^(id key, SGAudioFormatter *obj, BOOL *stop) {
        [obj flush];
    }];
}

- (void)close
{
    self->_mixer = nil;
    self->_formatters = nil;
}

@end
