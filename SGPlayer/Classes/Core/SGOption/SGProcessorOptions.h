//
//  SGProcessorOptions.h
//  SGPlayer
//
//  Created by Single on 2019/8/13.
//  Copyright © 2019 single. All rights reserved.
//

#import <Foundation/Foundation.h>

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

@end
