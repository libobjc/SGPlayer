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
#import <AVFoundation/AVFoundation.h>
#import "SGFFObjectPool.h"
#import "SGFFObjectQueue.h"
#import "SGFFPacket.h"
#import "SGDefines.h"

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


@protocol SGFFFrame <NSObject, SGFFObjectPoolItem, SGFFObjectQueueItem>

- (SGFFFrameType)type;

- (CMTime)position;
- (CMTime)duration;
- (long long)size;

- (SGFFAudioFrame *)audioFrame;
- (SGFFVideoFrame *)videoFrame;
- (AVFrame *)coreFrame;

- (void)fillWithTimebase:(CMTime)timebase;
- (void)fillWithTimebase:(CMTime)timebase packet:(SGFFPacket *)packet;

@end


#define SGFFFramePointerCoversionImplementation \
- (SGFFAudioFrame *)audioFrame \
{ \
    if (self.type == SGFFFrameTypeAudio) \
    { \
        return (SGFFAudioFrame *)self; \
    } \
    return nil; \
} \
 \
- (SGFFVideoFrame *)videoFrame \
{ \
    if (self.type == SGFFFrameTypeVideo) \
    { \
        return (SGFFVideoFrame *)self; \
    } \
    return nil; \
} \


#endif /* SGFFFrame_h */
