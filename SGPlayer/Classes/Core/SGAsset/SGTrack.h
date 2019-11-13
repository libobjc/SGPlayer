//
//  SGTrack.h
//  SGPlayer
//
//  Created by Single on 2018/1/17.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGDefines.h"

@class SGTrack;

/*!
 @abstract
   Get track with index.
*/
SGTrack *SGTrackWithIndex(NSArray<SGTrack *> *tracks, NSInteger index);

/*!
 @abstract
   Get track with media type.
*/
SGTrack *SGTrackWithType(NSArray<SGTrack *> *tracks, SGMediaType type);

/*!
 @abstract
   Get tracks with media types.
*/
NSArray<SGTrack *> *SGTracksWithType(NSArray<SGTrack *> *tracks, SGMediaType type);

@interface SGTrack : NSObject <NSCopying>

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/*!
 @property coreptr
 @abstract
    Indicates the pointer to the AVStream.
 */
@property (nonatomic, readonly) void *coreptr;

/*!
 @property type
 @abstract
    Indicates the track media type.
 */
@property (nonatomic, readonly) SGMediaType type;

/*!
 @property type
 @abstract
    Indicates the track index.
 */
@property (nonatomic, readonly) NSInteger index;

@end
