//
//  SGFFAsyncAVCodec.h
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFAsyncCodec.h"
#import "avformat.h"

@interface SGFFAsyncAVCodec : SGFFAsyncCodec

@property (nonatomic, assign) AVCodecParameters * codecpar;
@property (nonatomic, assign, readonly) AVCodecContext * codecContext;

@end
