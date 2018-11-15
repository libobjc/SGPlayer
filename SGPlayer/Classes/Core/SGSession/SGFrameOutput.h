//
//  SGFrameOutput.h
//  SGPlayer iOS
//
//  Created by Single on 2018/10/22.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGCapacity.h"
#import "SGAsset.h"
#import "SGFrame.h"
#import "SGTrack.h"

@protocol SGFrameOutputDelegate;

typedef NS_ENUM(uint32_t, SGFrameOutputState)
{
    SGFrameOutputStateNone,
    SGFrameOutputStateOpening,
    SGFrameOutputStateOpened,
    SGFrameOutputStateReading,
    SGFrameOutputStatePaused,
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
- (NSArray <SGTrack *> *)audioTracks;
- (NSArray <SGTrack *> *)videoTracks;
- (NSArray <SGTrack *> *)otherTracks;

@property (nonatomic, strong) SGTrack * selectedAudioTrack;
@property (nonatomic, strong) SGTrack * selectedVideoTrack;

- (BOOL)audioFinished;
- (BOOL)videoFinished;

- (SGCapacity *)capacityWithTrack:(SGTrack *)track;

- (BOOL)open;
- (BOOL)start;
- (BOOL)close;

- (BOOL)pause:(SGMediaType)type;
- (BOOL)resume:(SGMediaType)type;

- (BOOL)seekable;
- (BOOL)seekToTime:(CMTime)time result:(SGSeekResultBlock)result;

@end

@protocol SGFrameOutputDelegate <NSObject>

- (void)frameOutput:(SGFrameOutput *)frameOutput didChangeState:(SGFrameOutputState)state;
- (void)frameOutput:(SGFrameOutput *)frameOutput didChangeCapacity:(SGCapacity *)capacity track:(SGTrack *)track;
- (void)frameOutput:(SGFrameOutput *)frameOutput didOutputFrame:(__kindof SGFrame *)frame;

@end
