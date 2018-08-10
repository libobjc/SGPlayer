//
//  SGGLTextureUploader.h
//  SGPlayer
//
//  Created by Single on 2018/1/25.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "SGPLFGLContext.h"
#import "SGGLDefines.h"

typedef NS_ENUM(NSUInteger, SGGLTextureType)
{
    SGGLTextureTypeUnknown,
    SGGLTextureTypeYUV420P,
    SGGLTextureTypeNV12,
};

@interface SGGLTextureUploader : NSObject

- (instancetype)initWithGLContext:(SGPLFGLContext *)context;

- (BOOL)uploadWithType:(SGGLTextureType)type
                  data:(uint8_t **)data
                  size:(SGGLSize)size;
- (BOOL)uploadWithData:(uint8_t **)data
                widths:(int *)widths
               heights:(int *)heights
       internalFormats:(int *)internalFormats
               formats:(int *)formats
                 count:(int)count;

- (BOOL)uploadWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer;
- (BOOL)uploadWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer
                         widths:(int *)widths
                        heights:(int *)heights
                internalFormats:(int *)internalFormats
                        formats:(int *)formats
                          count:(int)count;

@end
