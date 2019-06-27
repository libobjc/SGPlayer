//
//  SGMetalTextureLoader.m
//  MetalTest
//
//  Created by Single on 2019/6/26.
//  Copyright © 2019 Single. All rights reserved.
//

#import "SGMetalTextureLoader.h"

@interface SGMetalTextureLoader ()

@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic) CVMetalTextureCacheRef textureCache;

@end

@implementation SGMetalTextureLoader

- (instancetype)initWithDevice:(id<MTLDevice>)device
{
    if (self = [super init]) {
        self.device = device;
    }
    return self;
}

- (void)dealloc
{
    if (self.textureCache) {
        CVMetalTextureCacheFlush(self.textureCache, 0);
        CFRelease(self.textureCache);
        self.textureCache = NULL;
    }
}

- (NSArray<id<MTLTexture>> *)texturesWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    if (!self.textureCache) {
        CVMetalTextureCacheCreate(NULL, NULL, self.device, NULL, &_textureCache);
    }
    CVMetalTextureRef texture;
    NSMutableArray *textures = [NSMutableArray array];
    OSType formatType = CVPixelBufferGetPixelFormatType(pixelBuffer);
    if (formatType == kCVPixelFormatType_420YpCbCr8Planar) {
        for (NSUInteger i = 0; i < 3; i++) {
            CVMetalTextureCacheCreateTextureFromImage(NULL,
                                                      self.textureCache,
                                                      pixelBuffer,
                                                      NULL,
                                                      MTLPixelFormatR8Unorm,
                                                      CVPixelBufferGetWidthOfPlane(pixelBuffer, i),
                                                      CVPixelBufferGetHeightOfPlane(pixelBuffer, i),
                                                      i,
                                                      &texture);
            [textures addObject:CVMetalTextureGetTexture(texture)];
            CVBufferRelease(texture);
            texture = NULL;
        }
    } else if (formatType == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange) {
        MTLPixelFormat formats[2] = {MTLPixelFormatR8Unorm, MTLPixelFormatRG8Unorm};
        for (NSUInteger i = 0; i < 2; i++) {
            CVMetalTextureCacheCreateTextureFromImage(NULL,
                                                      self.textureCache,
                                                      pixelBuffer,
                                                      NULL,
                                                      formats[i],
                                                      CVPixelBufferGetWidthOfPlane(pixelBuffer, i),
                                                      CVPixelBufferGetHeightOfPlane(pixelBuffer, i),
                                                      i,
                                                      &texture);
            [textures addObject:CVMetalTextureGetTexture(texture)];
            CVBufferRelease(texture);
            texture = NULL;
        }
    } else if (formatType == kCVPixelFormatType_32BGRA) {
        CVMetalTextureCacheCreateTextureFromImage(NULL,
                                                  self.textureCache,
                                                  pixelBuffer,
                                                  NULL,
                                                  MTLPixelFormatBGRA8Unorm,
                                                  CVPixelBufferGetWidth(pixelBuffer),
                                                  CVPixelBufferGetHeight(pixelBuffer),
                                                  0,
                                                  &texture);
        [textures addObject:CVMetalTextureGetTexture(texture)];
        CVBufferRelease(texture);
    }
    return textures.count ? textures : nil;
}

- (NSArray<id<MTLTexture>> *)texturesWithCVPixelFormat:(OSType)pixelFormat
                                                 width:(NSUInteger)width
                                                height:(NSUInteger)height
                                                 bytes:(void **)bytes
                                           bytesPerRow:(int *)bytesPerRow
{
    static NSUInteger const channelCount = 3;
    NSUInteger planes = 0;
    NSUInteger widths[channelCount] = {0};
    NSUInteger heights[channelCount] = {0};
    MTLPixelFormat formats[channelCount] = {0};
    if (pixelFormat == kCVPixelFormatType_420YpCbCr8Planar) {
        planes = 3;
        widths[0] = width;
        widths[1] = width / 2;
        widths[2] = width / 2;
        heights[0] = height;
        heights[1] = height / 2;
        heights[2] = height / 2;
        formats[0] = MTLPixelFormatR8Unorm;
        formats[1] = MTLPixelFormatR8Unorm;
        formats[2] = MTLPixelFormatR8Unorm;
    } else if (pixelFormat == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange) {
        planes = 2;
        widths[0] = width;
        widths[1] = width / 2;
        heights[0] = height;
        heights[1] = height / 2;
        formats[0] = MTLPixelFormatR8Unorm;
        formats[1] = MTLPixelFormatRG8Unorm;
    } else if (pixelFormat == kCVPixelFormatType_32BGRA) {
        planes = 1;
        widths[0] = width;
        heights[0] = height;
        formats[0] = MTLPixelFormatBGRA8Unorm;
    } else {
        return nil;
    }
    NSMutableArray<id<MTLTexture>> *textures = [NSMutableArray array];
    for (NSUInteger i = 0; i < planes; i++) {
        id<MTLTexture> texture = [self textureWithPixelFormat:formats[i]
                                                        width:widths[i]
                                                       height:heights[i]
                                                        bytes:bytes[i]
                                                  bytesPerRow:bytesPerRow[i]];
        [textures addObject:texture];
    }
    return textures.count ? textures : nil;
}

- (id<MTLTexture>)textureWithPixelFormat:(MTLPixelFormat)pixelFormat
                                   width:(NSUInteger)width
                                  height:(NSUInteger)height
                                   bytes:(void *)bytes
                             bytesPerRow:(NSUInteger)bytesPerRow
{
    MTLTextureDescriptor *descriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:pixelFormat width:width height:height mipmapped:NO];
    id<MTLTexture> texture = [self.device newTextureWithDescriptor:descriptor];
    [texture replaceRegion:MTLRegionMake2D(0, 0, width, height)
               mipmapLevel:0
                 withBytes:bytes
               bytesPerRow:bytesPerRow];
    return texture;
}

@end
