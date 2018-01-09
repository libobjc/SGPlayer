//
//  SGPLFImage.m
//  SGPlatform
//
//  Created by Single on 2017/2/24.
//  Copyright © 2017年 single. All rights reserved.
//

#import "SGPLFImage.h"

#if SGPLATFORM_TARGET_OS_MAC


SGPLFImage * SGPLFImageWithCGImage(CGImageRef image)
{
    return [[NSImage alloc] initWithCGImage:image size:CGSizeMake(CGImageGetWidth(image), CGImageGetHeight(image))];
}

SGPLFImage * SGPLFImageWithCVPixelBuffer(CVPixelBufferRef pixelBuffer)
{
    CIImage * ciImage = SGPLFImageCIImageWithCVPexelBuffer(pixelBuffer);
    if (!ciImage) return nil;
    NSCIImageRep * imageRep = [NSCIImageRep imageRepWithCIImage:ciImage];
    NSImage * image = [[NSImage alloc] initWithSize:imageRep.size];
    [image addRepresentation:imageRep];
    return image;
}


#elif SGPLATFORM_TARGET_OS_IPHONE_OR_TV


SGPLFImage * SGPLFImageWithCGImage(CGImageRef image)
{
    return [UIImage imageWithCGImage:image];
}

SGPLFImage * SGPLFImageWithCVPixelBuffer(CVPixelBufferRef pixelBuffer)
{
    CIImage * ciImage = SGPLFImageCIImageWithCVPexelBuffer(pixelBuffer);
    if (!ciImage) return nil;
    return [UIImage imageWithCIImage:ciImage];
}


#endif


CIImage * SGPLFImageCIImageWithCVPexelBuffer(CVPixelBufferRef pixelBuffer)
{
    CIImage * image = [CIImage imageWithCVPixelBuffer:pixelBuffer];
    return image;
}

CGImageRef SGPLFImageCGImageWithCVPexelBuffer(CVPixelBufferRef pixelBuffer)
{
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
    size_t count = CVPixelBufferGetPlaneCount(pixelBuffer);
    if (count > 1) {
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        return nil;
    }

    uint8_t * baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(pixelBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(baseAddress,
                                                 width,
                                                 height,
                                                 8,
                                                 bytesPerRow,
                                                 colorSpace,
                                                 kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    
    CGImageRef imageRef = CGBitmapContextCreateImage(context);
    
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    return imageRef;
}

SGPLFImage * SGPLFImageWithRGBData(UInt8 * rgb_data, int linesize, int width, int height)
{
    CGImageRef imageRef = SGPLFImageCGImageWithRGBData(rgb_data, linesize, width, height);
    if (!imageRef) return nil;
    SGPLFImage * image = SGPLFImageWithCGImage(imageRef);
    CGImageRelease(imageRef);
    return image;
}

CGImageRef SGPLFImageCGImageWithRGBData(UInt8 * rgb_data, int linesize, int width, int height)
{
    CFDataRef data = CFDataCreate(kCFAllocatorDefault, rgb_data, linesize * height);
    CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGImageRef imageRef = CGImageCreate(width,
                                       height,
                                       8,
                                       24,
                                       linesize,
                                       colorSpace,
                                       kCGBitmapByteOrderDefault,
                                       provider,
                                       NULL,
                                       NO,
                                       kCGRenderingIntentDefault);
    CGColorSpaceRelease(colorSpace);
    CGDataProviderRelease(provider);
    CFRelease(data);
    
    return imageRef;
}

