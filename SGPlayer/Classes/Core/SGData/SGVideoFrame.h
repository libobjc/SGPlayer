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
- (SInt32)format;

/**
 *
 */
- (BOOL)isKey;

/**
 *
 */
- (SInt32)width;

/**
 *
 */
- (SInt32)height;

/**
 *
 */
- (SInt32 *)linesize;

/**
 *
 */
- (UInt8 **)data;

/**
 *
 */
- (CVPixelBufferRef _Nullable)pixelBuffer;

/**
 *
 */
- (SGPLFImage * _Nullable)image;

@end
