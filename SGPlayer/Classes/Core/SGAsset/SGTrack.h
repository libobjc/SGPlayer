//
//  SGTrack.h
//  SGPlayer
//
//  Created by Single on 2018/1/17.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGDefines.h"

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

/*!
 @method trackWithTracks:type:
 @abstract
   Get track with media type.
*/
+ (SGTrack *)trackWithTracks:(NSArray<SGTrack *> *)tracks type:(SGMediaType)type;

/*!
 @method trackWithTracks:index:
 @abstract
   Get track with index.
*/
+ (SGTrack *)trackWithTracks:(NSArray<SGTrack *> *)tracks index:(NSInteger)index;

/*!
 @method tracksWithTracks:type:
 @abstract
   Get tracks with media types.
*/
+ (NSArray<SGTrack *> *)tracksWithTracks:(NSArray<SGTrack *> *)tracks type:(SGMediaType)type;

@end
