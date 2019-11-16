//
//  SGProcessorOptions.h
//  SGPlayer
//
//  Created by Single on 2019/8/13.
//  Copyright © 2019 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGAudioDescriptor.h"

@interface SGProcessorOptions : NSObject <NSCopying>

/*!
 @property audioClass
 @abstract
    The audio frame processor class.
    Default is SGAudioProcessor.
 */
@property (nonatomic, copy) Class audioClass;

/*!
 @property videoClass
 @abstract
    The video frame processor class.
    Default is SGVideoProcessor.
 */
@property (nonatomic, copy) Class videoClass;

/*!
 @property supportedPixelFormats
 @abstract
    Indicates the supported pixel formats.
 */
@property (nonatomic, copy) NSArray<NSNumber *> *supportedPixelFormats;

/*!
 @property supportedAudioDescriptor
 @abstract
    Indicates the supported audio descriptor.
 */
@property (nonatomic, copy) SGAudioDescriptor *supportedAudioDescriptor;

@end
