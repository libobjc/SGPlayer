//
//  SGAudioProcessor.m
//  SGPlayer
//
//  Created by Single on 2018/11/28.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGAudioProcessor.h"
#import "SGAudioMixer.h"

@interface SGAudioProcessor ()

@property (nonatomic, strong, readonly) SGAudioMixer *mixer;
@property (nonatomic, strong, readonly) SGTrackSelection *selection;

@end

@implementation SGAudioProcessor

- (void)setSelection:(SGTrackSelection *)selection action:(SGTrackSelectionAction)action
{
    self->_selection = [selection copy];
    if (action & SGTrackSelectionActionTracks) {
        self->_mixer = [[SGAudioMixer alloc] initWithTracks:selection.tracks weights:selection.weights];
    } else if (action & SGTrackSelectionActionWeights) {
        self->_mixer.weights = selection.weights;
    }
}

- (__kindof SGFrame *)putFrame:(__kindof SGFrame *)frame
{
    if (![frame isKindOfClass:[SGAudioFrame class]] ||
        ![self->_selection.tracks containsObject:frame.track]) {
        [frame unlock];
        return nil;
    }
    return [self->_mixer putFrame:frame];
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
}

- (void)close
{
    self->_mixer = nil;
}

@end
