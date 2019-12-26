//
//  SGAudioRenderer.h
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGAudioDescriptor.h"

@interface SGAudioRenderer : NSObject

/*!
 @method supportedAudioDescriptor
 @abstract
    Indicates all supported audio descriptor.
*/
+ (SGAudioDescriptor *)supportedAudioDescriptor;

/*!
 @property pitch
 @abstract
    Indicates the current pitch.
 */
@property (nonatomic) Float64 pitch;

/*!
 @property volume
 @abstract
    Indicates the current volume.
 */
@property (nonatomic) Float64 volume;

@end
