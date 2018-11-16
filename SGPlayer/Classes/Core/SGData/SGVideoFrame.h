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

{
@public
    uint8_t * _data[SGFramePlaneCount];
    int _linesize[SGFramePlaneCount];
    CVPixelBufferRef _pixelBuffer;
}

@property (nonatomic, readonly) int format;     // AVPixelFormat
@property (nonatomic, readonly) int width;
@property (nonatomic, readonly) int height;
@property (nonatomic, readonly) int key_frame;

- (SGPLFImage *)image;

@end
