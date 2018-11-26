//
//  SGVideoFrame.h
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFrame.h"
#import "SGPLFImage.h"

@interface SGVideoFrame : SGFrame

/**
 *  AVPixelFormat
 */
- (int)format;

/**
 *
 */
- (int)isKey;

/**
 *
 */
- (int)width;

/**
 *
 */
- (int)height;

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
- (CVPixelBufferRef _Nullable)pixelBuffer;

/**
 *
 */
- (SGPLFImage * _Nullable)image;

@end
