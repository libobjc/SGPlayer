//
//  SGMetalTextureLoader.h
//  MetalTest
//
//  Created by Single on 2019/6/26.
//  Copyright © 2019 Single. All rights reserved.
//

#import <Metal/Metal.h>
#import <CoreVideo/CoreVideo.h>

@interface SGMetalTextureLoader : NSObject

- (instancetype)initWithDevice:(id<MTLDevice>)device;

- (NSArray<id<MTLTexture>> *)texturesWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer;

- (NSArray<id<MTLTexture>> *)texturesWithCVPixelFormat:(OSType)pixelFormat
                                                 width:(NSUInteger)width
                                                height:(NSUInteger)height
                                                 bytes:(void **)bytes
                                           bytesPerRow:(int *)bytesPerRow;

- (id<MTLTexture>)textureWithPixelFormat:(MTLPixelFormat)pixelFormat
                                   width:(NSUInteger)width
                                  height:(NSUInteger)height
                                   bytes:(void *)bytes
                             bytesPerRow:(NSUInteger)bytesPerRow;

@end
