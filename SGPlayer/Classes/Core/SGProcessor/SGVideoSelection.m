//
//  SGVideoSelection.m
//  SGPlayer
//
//  Created by Single on 2019/5/30.
//  Copyright © 2019 single. All rights reserved.
//

#import "SGVideoSelection.h"

@implementation SGVideoSelection

- (id)copyWithZone:(NSZone *)zone
{
    SGVideoSelection *obj = [[SGVideoSelection alloc] init];
    obj.tracks = self->_tracks;
    return obj;
}

- (void)setTracks:(NSArray *)tracks
{
    NSMutableArray *objs = [NSMutableArray array];
    for (SGTrack *track in tracks) {
        if (track.type == SGMediaTypeVideo) {
            [objs addObject:track];
        }
    }
    _tracks = objs.count > 0 ? [objs copy] : nil;
}

@end
