//
//  SGPLFImage.h
//  SGPlatform
//
//  Created by Single on 2017/2/24.
//  Copyright © 2017年 single. All rights reserved.
//

#import "SGPLFObject.h"

#import <CoreVideo/CoreVideo.h>
#import <CoreImage/CoreImage.h>

#if SGPLATFORM_TARGET_OS_MAC


typedef NSImage SGPLFImage;


#elif SGPLATFORM_TARGET_OS_IPHONE_OR_TV


typedef UIImage SGPLFImage;


#endif

SGPLFImage * SGPLFImageWithCGImage(CGImageRef image);

// CVPixelBufferRef
SGPLFImage * SGPLFImageWithCVPixelBuffer(CVPixelBufferRef pixelBuffer);
CIImage * SGPLFImageCIImageWithCVPexelBuffer(CVPixelBufferRef pixelBuffer);
CGImageRef SGPLFImageCGImageWithCVPexelBuffer(CVPixelBufferRef pixelBuffer);

// RGB data buffer
SGPLFImage * SGPLFImageWithRGBData(UInt8 * rgb_data, int linesize, int width, int height);
CGImageRef SGPLFImageCGImageWithRGBData(UInt8 * rgb_data, int linesize, int width, int height);
