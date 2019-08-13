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
@property (nonatomic, strong, readonly) SGTrackSelection *selection;
@property (nonatomic, strong, readonly) SGAudioDescriptor *descriptor;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSNumber *, SGAudioFormatter *> *formatters;

@end

@implementation SGAudioProcessor

- (void)setDescriptor:(SGAudioDescriptor *)descriptor
{
    self->_descriptor = [descriptor copy];
}

- (void)setSelection:(SGTrackSelection *)selection action:(SGTrackSelectionAction)action
{
    self->_selection = [selection copy];
    if (action & SGTrackSelectionActionTracks) {
        self->_mixer = [[SGAudioMixer alloc] initWithTracks:selection.tracks weights:selection.weights descriptor:self->_descriptor];
        self->_formatters = [NSMutableDictionary dictionary];
        for (SGTrack *track in selection.tracks) {
            SGAudioFormatter *formatter = [[SGAudioFormatter alloc] init];
            formatter.descriptor = self->_descriptor;
            [self->_formatters setObject:formatter forKey:@(track.index)];
        }
    } else if (action & SGTrackSelectionActionWeights) {
        self->_mixer.weights = selection.weights;
    }
}

- (__kindof SGFrame *)putFrame:(__kindof SGFrame *)frame
{
    if (![self->_selection.tracks containsObject:frame.track]) {
        [frame unlock];
        return nil;
    }
    frame = [self->_formatters[@(frame.track.index)] format:frame];
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
    return [self->_mixer capacity];
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
