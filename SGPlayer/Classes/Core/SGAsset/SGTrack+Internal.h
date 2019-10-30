//
//  SGTrack+Internal.h
//  SGPlayer iOS
//
//  Created by Single on 2018/10/23.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGTrack.h"
#import "SGFFmpeg.h"
#import "SGMutableTrack.h"

@interface SGTrack ()

/*!
 @method initWithType:index:
 @abstract
    Initializes an SGTrack.
 */
- (instancetype)initWithType:(SGMediaType)type index:(NSInteger)index;

/*!
 @property core
 @abstract
    Indicates the pointer to the AVStream.
*/
@property (nonatomic) AVStream *core;

@end

@interface SGMutableTrack ()

/*!
 @property subTracks
 @abstract
    Indicates the sub tracks.
 */
@property (nonatomic, copy) NSArray<SGTrack *> *subTracks;

@end
