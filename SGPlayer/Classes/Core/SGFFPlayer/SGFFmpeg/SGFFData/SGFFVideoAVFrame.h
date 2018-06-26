//
//  SGFFVideoAVFrame.h
//  SGPlayer
//
//  Created by Single on 2018/6/26.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGFFFrame.h"

@interface SGFFVideoAVFrame : SGFFFrame

@property (nonatomic, assign) CVPixelBufferRef corePixelBuffer;

@property (nonatomic, assign) enum AVPixelFormat format;
@property (nonatomic, assign) int width;
@property (nonatomic, assign) int height;
@property (nonatomic, assign) long long bestEffortTimestamp;
@property (nonatomic, assign) long long packetPosition;
@property (nonatomic, assign) long long packetDuration;
@property (nonatomic, assign) long long packetSize;

@end
