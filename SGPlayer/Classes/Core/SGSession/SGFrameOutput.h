//
//  SGFrameOutput.h
//  SGPlayer iOS
//
//  Created by Single on 2018/10/22.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGAsset.h"
#import "SGFrame.h"
#import "SGTrack.h"

@protocol SGFrameOutputDelegate;

typedef NS_ENUM(uint32_t, SGFrameOutputState) {
    SGFrameOutputStateNone,
    SGFrameOutputStateOpening,
    SGFrameOutputStateOpened,
    SGFrameOutputStateReading,
    SGFrameOutputStateSeeking,
    SGFrameOutputStateFinished,
    SGFrameOutputStateClosed,
    SGFrameOutputStateFailed,
};

@interface SGFrameOutput : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithAsset:(SGAsset *)asset;

@property (nonatomic, weak) id <SGFrameOutputDelegate> delegate;

- (SGFrameOutputState)state;
- (NSError *)error;

- (CMTime)duration;
- (NSDictionary *)metadata;
- (NSArray <SGTrack *> *)tracks;

- (BOOL)open;
- (BOOL)start;
- (BOOL)close;
- (BOOL)pause:(SGMediaType)type;
- (BOOL)resume:(SGMediaType)type;
- (BOOL)seekable;
- (BOOL)seekToTime:(CMTime)time result:(SGSeekResultBlock)result;

@property (nonatomic, strong) SGTrack * selectedAudioTrack;
@property (nonatomic, strong) SGTrack * selectedVideoTrack;

- (SGCapacity *)capacityWithType:(SGMediaType)type;

- (BOOL)isAudioFinished;
- (BOOL)isVideoFinished;
- (BOOL)isAudioAvailable;
- (BOOL)isVideoAvailable;

@end

@protocol SGFrameOutputDelegate <NSObject>

- (void)frameOutput:(SGFrameOutput *)frameOutput didChangeState:(SGFrameOutputState)state;
- (void)frameOutput:(SGFrameOutput *)frameOutput didChangeCapacity:(SGCapacity *)capacity type:(SGMediaType)type;
- (void)frameOutput:(SGFrameOutput *)frameOutput didOutputFrame:(__kindof SGFrame *)frame;

@end
