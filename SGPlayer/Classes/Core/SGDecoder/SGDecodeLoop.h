//
//  SGDecodeLoop.h
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGDecodable.h"
#import "SGCapacity.h"

@protocol SGDecodeLoopDelegate;

/**
 *
 */
typedef NS_ENUM(int, SGDecodeLoopState) {
    SGDecodeLoopStateNone,
    SGDecodeLoopStateDecoding,
    SGDecodeLoopStateStalled,
    SGDecodeLoopStatePaused,
    SGDecodeLoopStateClosed,
};

NS_ASSUME_NONNULL_BEGIN

@interface SGDecodeLoop : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 *
 */
- (instancetype)initWithDecodableClass:(Class)decodableClass NS_DESIGNATED_INITIALIZER;

/**
 *
 */
@property (nonatomic, weak) id<SGDecodeLoopDelegate> delegate;

/**
 *
 */
- (SGDecodeLoopState)state;

/**
 *
 */
- (BOOL)open;

/**
 *
 */
- (BOOL)close;

/**
 *
 */
- (BOOL)pause;

/**
 *
 */
- (BOOL)resume;

/**
 *
 */
- (BOOL)flush;

/**
 *
 */
- (BOOL)finish:(NSArray<SGTrack *> *)tracks;

/**
 *
 */
- (BOOL)putPacket:(SGPacket *)packet;

@end

@protocol SGDecodeLoopDelegate <NSObject>

/**
 *
 */
- (void)decodeLoop:(SGDecodeLoop *)decodeLoop didChangeState:(SGDecodeLoopState)state;

/**
 *
 */
- (void)decodeLoop:(SGDecodeLoop *)decodeLoop didChangeCapacity:(SGCapacity *)capacity;

/**
 *
 */
- (void)decodeLoop:(SGDecodeLoop *)decodeLoop didOutputFrame:(__kindof SGFrame *)frame;

@end

NS_ASSUME_NONNULL_END
