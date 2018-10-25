//
//  SGVideoFrame.h
//  SGPlayer
//
//  Created by Single on 2018/1/22.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFrame.h"

@interface SGVideoFrame : SGFrame

{
@public
    uint8_t * _data[SGFramePlaneCount];
    int _linesize[SGFramePlaneCount];
    CVPixelBufferRef _pixelBuffer;
}

@property (nonatomic, assign, readonly) int format;     // AVPixelFormat
@property (nonatomic, assign, readonly) int width;
@property (nonatomic, assign, readonly) int height;
@property (nonatomic, assign, readonly) int key_frame;

- (UIImage *)image;

@end
