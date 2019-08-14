//
//  SGTrackSelection.m
//  SGPlayer
//
//  Created by Single on 2019/8/13.
//  Copyright © 2019 single. All rights reserved.
//

#import "SGTrackSelection.h"

@implementation SGTrackSelection

- (id)copyWithZone:(NSZone *)zone
{
    SGTrackSelection *obj = [[SGTrackSelection alloc] init];
    obj->_tracks = self->_tracks;
    obj->_weights = self->_weights;
    return obj;
}

@end
