//
//  SGAsyncDecoder.h
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGDecodable.h"

@protocol SGAsyncDecoderDelegate;

typedef NS_ENUM(NSUInteger, SGAsyncDecoderState)
{
    SGAsyncDecoderStateNone,
    SGAsyncDecoderStateDecoding,
    SGAsyncDecoderStatePaused,
    SGAsyncDecoderStateClosed,
};

@interface SGAsyncDecoder : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithDecodable:(id <SGDecodable>)decodable;

@property (nonatomic, weak) id object;
@property (nonatomic, weak) id <SGAsyncDecoderDelegate> delegate;

- (SGAsyncDecoderState)state;
- (BOOL)duratioin:(CMTime *)duration size:(int64_t *)size count:(NSUInteger *)count;

- (BOOL)open;
- (BOOL)close;
- (BOOL)pause;
- (BOOL)resume;

- (BOOL)putPacket:(SGPacket *)packet;
- (BOOL)flush;

@end

@protocol SGAsyncDecoderDelegate <NSObject>

- (void)decoder:(SGAsyncDecoder *)decoder didOutputFrame:(__kindof SGFrame *)frame;
- (void)decoder:(SGAsyncDecoder *)decoder didChangeState:(SGAsyncDecoderState)state;
- (void)decoder:(SGAsyncDecoder *)decoder didChangeDuration:(CMTime)duration size:(int64_t)size count:(NSUInteger)count;

@end
