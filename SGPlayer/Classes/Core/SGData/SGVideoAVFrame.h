//
//  SGVideoAVFrame.h
//  SGPlayer
//
//  Created by Single on 2018/6/26.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGVideoFrame.h"

@interface SGVideoAVFrame : SGVideoFrame

@property (nonatomic, assign) CVPixelBufferRef corePixelBuffer;

- (void)fillWithTimebase:(CMTime)timebase packet:(SGPacket *)packet;

@end
