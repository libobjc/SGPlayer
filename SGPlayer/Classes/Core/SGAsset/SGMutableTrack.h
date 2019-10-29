//
//  SGMutableTrack.h
//  SGPlayer
//
//  Created by Single on 2018/11/29.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGSegment.h"
#import "SGTrack.h"

@interface SGMutableTrack : SGTrack

/*!
 @property subTracks
 @abstract
    Indicates the sub tracks.
 */
@property (nonatomic, copy, readonly) NSArray<SGTrack *> *subTracks;

/*!
 @property segments
 @abstract
    Provides array of SGMutableTrack segments.
 */
@property (nonatomic, copy, readonly) NSArray<SGSegment *> *segments;

/*!
 @method appendSegment:
 @abstract
    Append a segment to the track.
 */
- (BOOL)appendSegment:(SGSegment *)segment;

@end
