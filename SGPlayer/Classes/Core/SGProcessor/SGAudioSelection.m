//
//  SGAudioSelection.m
//  SGPlayer iOS
//
//  Created by Single on 2019/5/30.
//  Copyright © 2019 single. All rights reserved.
//

#import "SGAudioSelection.h"

@implementation SGAudioSelection

- (id)copyWithZone:(NSZone *)zone
{
    SGAudioSelection *obj = [[SGAudioSelection alloc] init];
    obj.tracks = self->_tracks;
    obj.weights = self->_weights;
    return obj;
}

- (void)setTracks:(NSArray *)tracks
{
    NSMutableArray *objs = [NSMutableArray array];
    for (SGTrack *track in tracks) {
        if (track.type == SGMediaTypeAudio) {
            [objs addObject:track];
        }
    }
    _tracks = objs.count > 0 ? [objs copy] : nil;
}

@end
