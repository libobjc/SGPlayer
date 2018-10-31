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

@protocol SGFrameOutputDelegate;

typedef NS_ENUM(NSUInteger, SGFrameOutputState)
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

- (SGCapacity *)capacityWithTrack:(SGTrack *)track;

- (NSError *)open;
- (NSError *)start;
- (NSError *)close;
- (NSError *)pause:(NSArray <SGTrack *> *)tracks;
- (NSError *)resume:(NSArray <SGTrack *> *)tracks;
- (NSError *)seekable;
- (NSError *)seekToTime:(CMTime)time completionHandler:(void(^)(CMTime time, NSError * error))completionHandler;

@end

@protocol SGFrameOutputDelegate <NSObject>

- (void)frameOutput:(SGFrameOutput *)frameOutput didChangeState:(SGFrameOutputState)state;
- (void)frameOutput:(SGFrameOutput *)frameOutput didChangeCapacity:(SGCapacity *)capacity track:(SGTrack *)track;
- (void)frameOutput:(SGFrameOutput *)frameOutput didOutputFrame:(SGFrame *)frame;

@end
