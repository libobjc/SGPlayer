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
    obj.audioDescription = self->_audioDescription;
    return obj;
}

@end
