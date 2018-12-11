//
//  SGVideoFrame.h
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFrame.h"
#import "SGPLFImage.h"
#import "SGVideoDescription.h"

@interface SGVideoFrame : SGFrame

/**
 *
 */
@property (nonatomic, copy, readonly) SGVideoDescription * _Nullable videoDescription;

/**
 *
 */
- (int * _Nullable)linesize;

/**
 *
 */
- (uint8_t * _Nullable * _Nullable)data;

/**
 *
 */
- (CVPixelBufferRef _Nullable)pixelBuffer;

/**
 *
 */
- (SGPLFImage * _Nullable)image;

@end
