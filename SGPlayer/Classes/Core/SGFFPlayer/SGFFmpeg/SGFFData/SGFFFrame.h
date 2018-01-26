//
//  SGFFFrame.h
//  SGPlayer
//
//  Created by Single on 2018/1/18.
//  Copyright © 2018年 single. All rights reserved.
//

#ifndef SGFFFrame_h
#define SGFFFrame_h


#import <Foundation/Foundation.h>
#import "SGFFObjectPool.h"
#import "SGFFTime.h"
#import "avformat.h"

@class SGFFAudioFrame;
@class SGFFVideoFrame;
@protocol SGFFFrameUtil;


typedef NS_ENUM(NSUInteger, SGFFFrameType)
{
    SGFFFrameTypeUnkonwn,
    SGFFFrameTypeVideo,
    SGFFFrameTypeAudio,
    SGFFFrameTypeSubtitle,
};


@protocol SGFFFrame <NSObject, SGFFFrameUtil, SGFFObjectPoolItem>

- (SGFFFrameType)type;

- (SGFFTimebase)timebase;
- (long long)position;
- (long long)duration;
- (long long)size;

@end


@protocol SGFFFrameUtil <NSObject>

- (void)fill;
- (void)fillWithPacket:(AVPacket *)packet;
- (AVFrame *)coreFrame;
- (SGFFAudioFrame *)audioFrame;
- (SGFFVideoFrame *)videoFrame;

@end


#endif /* SGFFFrame_h */
