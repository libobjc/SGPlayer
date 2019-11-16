//
//  SGVideoFrame.h
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFrame.h"
#import "SGPLFImage.h"
#import "SGVideoDescriptor.h"

@interface SGVideoFrame : SGFrame

/**
 *
 */
@property (nonatomic, strong, readonly) SGVideoDescriptor *descriptor;

/**
 *
 */
- (int *)linesize;

/**
 *
 */
- (uint8_t **)data;

/**
 *
 */
- (CVPixelBufferRef)pixelBuffer;

/**
 *
 */
- (SGPLFImage *)image;

@end
