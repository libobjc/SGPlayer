//
//  SGAsyncDecoder.h
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGDecodable.h"
#import "SGCapacity.h"

@protocol SGAsyncDecoderDelegate;

typedef NS_ENUM(uint32_t, SGAsyncDecoderState) {
    SGAsyncDecoderStateNone,
    SGAsyncDecoderStateDecoding,
    SGAsyncDecoderStatePaused,
    SGAsyncDecoderStateClosed,
};

@interface SGAsyncDecoder : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithDecodable:(id <SGDecodable>)decodable;

- (id <SGDecodable>)decodable;

@property (nonatomic, weak) id <SGAsyncDecoderDelegate> delegate;

- (SGAsyncDecoderState)state;
- (SGCapacity *)capacity;

- (BOOL)open;
- (BOOL)close;
- (BOOL)pause;
- (BOOL)resume;
- (BOOL)flush;
- (BOOL)finish;
- (BOOL)putPacket:(SGPacket *)packet;

@end

@protocol SGAsyncDecoderDelegate <NSObject>

- (void)decoder:(SGAsyncDecoder *)decoder didChangeState:(SGAsyncDecoderState)state;
- (void)decoder:(SGAsyncDecoder *)decoder didChangeCapacity:(SGCapacity *)capacity;
- (void)decoder:(SGAsyncDecoder *)decoder didOutputFrame:(__kindof SGFrame *)frame;

@end
