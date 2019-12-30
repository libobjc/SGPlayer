//
//  SGFrameOutput.m
//  SGPlayer iOS
//
//  Created by Single on 2018/10/22.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGFrameOutput.h"
#import "SGAudioDecoder.h"
#import "SGVideoDecoder.h"
#import "SGPacketOutput.h"
#import "SGDecodeLoop.h"
#import "SGOptions.h"
#import "SGMacro.h"
#import "SGLock.h"

@interface SGFrameOutput () <SGPacketOutputDelegate, SGDecodeLoopDelegate>

{
    struct {
        NSError *error;
        SGFrameOutputState state;
    } _flags;
    BOOL _capacityFlags[8];
    SGCapacity _capacities[8];
}

@property (nonatomic, strong, readonly) NSLock *lock;
@property (nonatomic, strong, readonly) SGDecodeLoop *audioDecoder;
@property (nonatomic, strong, readonly) SGDecodeLoop *videoDecoder;
@property (nonatomic, strong, readonly) SGPacketOutput *packetOutput;
@property (nonatomic, strong, readonly) NSArray<SGTrack *> *finishedTracks;

@end

@implementation SGFrameOutput

@synthesize selectedTracks = _selectedTracks;
@synthesize finishedTracks = _finishedTracks;

- (instancetype)initWithAsset:(SGAsset *)asset
{
    if (self = [super init]) {
        self->_lock = [[NSLock alloc] init];
        self->_audioDecoder = [[SGDecodeLoop alloc] initWithDecoderClass:[SGAudioDecoder class]];
        self->_audioDecoder.delegate = self;
        self->_videoDecoder = [[SGDecodeLoop alloc] initWithDecoderClass:[SGVideoDecoder class]];
        self->_videoDecoder.delegate = self;
        self->_packetOutput = [[SGPacketOutput alloc] initWithAsset:asset];
        self->_packetOutput.delegate = self;
        for (int i = 0; i < 8; i++) {
            self->_capacityFlags[i] = NO;
            self->_capacities[i] = SGCapacityCreate();
        }
        [self setDecoderOptions:[SGOptions sharedOptions].decoder.copy];
    }
    return self;
}

- (void)dealloc
{
    SGLockCondEXE10(self->_lock, ^BOOL {
        return self->_flags.state != SGFrameOutputStateClosed;
    }, ^SGBlock {
        [self setState:SGFrameOutputStateClosed];
        [self->_packetOutput close];
        [self->_audioDecoder close];
        [self->_videoDecoder close];
        return nil;
    });
}

#pragma mark - Mapping

SGGet0Map(CMTime, duration, self->_packetOutput)
SGGet0Map(NSDictionary *, metadata, self->_packetOutput)
SGGet0Map(NSArray<SGTrack *> *, tracks, self->_packetOutput)
SGGet00Map(SGDemuxerOptions *,demuxerOptions, options, self->_packetOutput)
SGGet00Map(SGDecoderOptions *, decoderOptions, options, self->_audioDecoder)
SGSet11Map(void, setDemuxerOptions, setOptions, SGDemuxerOptions *, self->_packetOutput)

#pragma mark - Setter & Getter

- (void)setDecoderOptions:(SGDecoderOptions *)decoderOptions
{
    self->_audioDecoder.options = decoderOptions;
    self->_videoDecoder.options = decoderOptions;
}

- (SGBlock)setState:(SGFrameOutputState)state
{
    if (self->_flags.state == state) {
        return ^{};
    }
    self->_flags.state = state;
    return ^{
        [self->_delegate frameOutput:self didChangeState:state];
    };
}

- (SGFrameOutputState)state
{
    __block SGFrameOutputState ret = SGFrameOutputStateNone;
    SGLockEXE00(self->_lock, ^{
        ret = self->_flags.state;
    });
    return ret;
}

- (NSError *)error
{
    __block NSError *ret = nil;
    SGLockEXE00(self->_lock, ^{
        ret = [self->_flags.error copy];
    });
    return ret;
}

- (BOOL)selectTracks:(NSArray<SGTrack *> *)tracks
{
    return SGLockCondEXE10(self->_lock, ^BOOL {
        return ![self->_selectedTracks isEqualToArray:tracks];
    }, ^SGBlock {
        self->_selectedTracks = [tracks copy];
        return nil;
    });
}

- (NSArray<SGTrack *> *)selectedTracks
{
    __block NSArray<SGTrack *> *ret = nil;
    SGLockEXE00(self->_lock, ^{
        ret = [self->_selectedTracks copy];
    });
    return ret;
}

- (SGCapacity)capacityWithType:(SGMediaType)type
{
    __block SGCapacity ret;
    SGLockEXE00(self->_lock, ^{
        ret = self->_capacities[type];
    });
    return ret;
}

- (SGBlock)setFinishedTracks:(NSArray<SGTrack *> *)tracks
{
    if (tracks.count <= 0) {
        self->_finishedTracks = nil;
        return ^{};
    }
    SGBlock b1 = ^{}, b2 = ^{};
    if (![tracks isEqualToArray:self->_finishedTracks]) {
        NSMutableArray<SGTrack *> *audioTracks = [NSMutableArray array];
        NSMutableArray<SGTrack *> *videoTracks = [NSMutableArray array];
        for (SGTrack *obj in tracks) {
            if ([self->_selectedTracks containsObject:obj] &&
                ![self->_finishedTracks containsObject:obj]) {
                if (obj.type == SGMediaTypeAudio) {
                    [audioTracks addObject:obj];
                } else if (obj.type == SGMediaTypeVideo) {
                    [videoTracks addObject:obj];
                }
            }
        }
        self->_finishedTracks = tracks;
        if (audioTracks.count) {
            SGDecodeLoop *decoder = self->_audioDecoder;
            b1 = ^{
                [decoder finish:audioTracks];
            };
        }
        if (videoTracks.count) {
            SGDecodeLoop *decoder = self->_videoDecoder;
            b2 = ^{
                [decoder finish:videoTracks];
            };
        }
    }
    return ^{b1(); b2();};
}

#pragma mark - Control

- (BOOL)open
{
    return SGLockCondEXE11(self->_lock, ^BOOL {
        return self->_flags.state == SGFrameOutputStateNone;
    }, ^SGBlock {
        return [self setState:SGFrameOutputStateOpening];
    }, ^BOOL(SGBlock block) {
        block();
        return [self->_packetOutput open];
    });
}

- (BOOL)start
{
    return SGLockCondEXE11(self->_lock, ^BOOL {
        return self->_flags.state == SGFrameOutputStateOpened;
    }, ^SGBlock {
        return [self setState:SGFrameOutputStateReading];
    }, ^BOOL(SGBlock block) {
        block();
        return [self->_packetOutput resume];
    });
}

- (BOOL)close
{
    return SGLockCondEXE11(self->_lock, ^BOOL {
        return self->_flags.state != SGFrameOutputStateClosed;
    }, ^SGBlock {
        return [self setState:SGFrameOutputStateClosed];
    }, ^BOOL(SGBlock block) {
        block();
        [self->_packetOutput close];
        [self->_audioDecoder close];
        [self->_videoDecoder close];
        return YES;
    });
}

- (BOOL)pause:(SGMediaType)type
{
    return SGLockEXE00(self->_lock, ^{
        if (type == SGMediaTypeAudio) {
            [self->_audioDecoder pause];
        } else if (type == SGMediaTypeVideo) {
            [self->_videoDecoder pause];
        }
    });
}

- (BOOL)resume:(SGMediaType)type
{
    return SGLockEXE00(self->_lock, ^{
        if (type == SGMediaTypeAudio) {
            [self->_audioDecoder resume];
        } else if (type == SGMediaTypeVideo) {
            [self->_videoDecoder resume];
        }
    });
}

- (BOOL)seekable
{
    return [self->_packetOutput seekable];
}

- (BOOL)seekToTime:(CMTime)time
{
    return [self seekToTime:time result:nil];
}

- (BOOL)seekToTime:(CMTime)time result:(SGSeekResult)result
{
    return [self seekToTime:time toleranceBefor:kCMTimeInvalid toleranceAfter:kCMTimeInvalid result:result];
}

- (BOOL)seekToTime:(CMTime)time toleranceBefor:(CMTime)toleranceBefor toleranceAfter:(CMTime)toleranceAfter result:(SGSeekResult)result
{
    SGWeakify(self)
    return [self->_packetOutput seekToTime:time toleranceBefor:toleranceBefor toleranceAfter:toleranceAfter result:^(CMTime time, NSError *error) {
        SGStrongify(self)
        if (!error) {
            [self->_audioDecoder flush];
            [self->_videoDecoder flush];
        }
        if (result) {
            result(time, error);
        }
    }];
}

#pragma mark - SGPacketOutputDelegate

- (void)packetOutput:(SGPacketOutput *)packetOutput didChangeState:(SGPacketOutputState)state
{
    SGLockEXE10(self->_lock, ^SGBlock {
        SGBlock b1 = ^{}, b2 = ^{}, b3 = ^{};
        switch (state) {
            case SGPacketOutputStateOpened: {
                b1 = [self setState:SGFrameOutputStateOpened];
                int nb_a = 0, nb_v = 0;
                NSMutableArray *tracks = [NSMutableArray array];
                for (SGTrack *obj in packetOutput.tracks) {
                    if (obj.type == SGMediaTypeAudio && nb_a == 0) {
                        [tracks addObject:obj];
                        nb_a += 1;
                    } else if (obj.type == SGMediaTypeVideo && nb_v == 0) {
                        [tracks addObject:obj];
                        nb_v += 1;
                    }
                    if (nb_a && nb_v) {
                        break;
                    }
                }
                self->_selectedTracks = [tracks copy];
                if (nb_a) {
                    [self->_audioDecoder open];
                }
                if (nb_v) {
                    [self->_videoDecoder open];
                }
            }
                break;
            case SGPacketOutputStateReading:
                b1 = [self setState:SGFrameOutputStateReading];
                break;
            case SGPacketOutputStateSeeking:
                b1 = [self setState:SGFrameOutputStateSeeking];
                break;
            case SGPacketOutputStateFinished: {
                b1 = [self setFinishedTracks:self->_selectedTracks];
            }
                break;
            case SGPacketOutputStateFailed:
                self->_flags.error = [packetOutput.error copy];
                b1 = [self setState:SGFrameOutputStateFailed];
                break;
            default:
                break;
        }
        return ^{
            b1(); b2(); b3();
        };
    });
}

- (void)packetOutput:(SGPacketOutput *)packetOutput didOutputPacket:(SGPacket *)packet
{
    SGLockEXE10(self->_lock, ^SGBlock {
        SGBlock b1 = ^{}, b2 = ^{};
        b1 = [self setFinishedTracks:packetOutput.finishedTracks];
        if ([self->_selectedTracks containsObject:packet.track]) {
            SGDecodeLoop *decoder = nil;
            if (packet.track.type == SGMediaTypeAudio) {
                decoder = self->_audioDecoder;
            } else if (packet.track.type == SGMediaTypeVideo) {
                decoder = self->_videoDecoder;
            }
            b2 = ^{
                [decoder putPacket:packet];
            };
        }
        return ^{b1(); b2();};
    });
}

#pragma mark - SGDecoderDelegate

- (void)decodeLoop:(SGDecodeLoop *)decodeLoop didChangeState:(SGDecodeLoopState)state
{
    
}

- (void)decodeLoop:(SGDecodeLoop *)decodeLoop didChangeCapacity:(SGCapacity)capacity
{
    __block SGBlock finished = ^{};
    __block SGMediaType type = SGMediaTypeUnknown;
    SGLockCondEXE11(self->_lock, ^BOOL {
        if (decodeLoop == self->_audioDecoder) {
            type = SGMediaTypeAudio;
        } else if (decodeLoop == self->_videoDecoder) {
            type = SGMediaTypeVideo;
        }
        return !SGCapacityIsEqual(self->_capacities[type], capacity);
    }, ^SGBlock {
        self->_capacityFlags[type] = YES;
        self->_capacities[type] = capacity;
        SGCapacity ac = self->_capacities[SGMediaTypeAudio];
        SGCapacity vc = self->_capacities[SGMediaTypeVideo];
        int size = ac.size + vc.size;
        BOOL enough = NO;
        if ((!self->_capacityFlags[SGMediaTypeAudio] || SGCapacityIsEnough(ac)) &&
            (!self->_capacityFlags[SGMediaTypeVideo] || SGCapacityIsEnough(vc))) {
            enough = YES;
        }
        if ((!self->_capacityFlags[SGMediaTypeAudio] || SGCapacityIsEmpty(ac)) &&
            (!self->_capacityFlags[SGMediaTypeVideo] || SGCapacityIsEmpty(vc)) &&
            self->_packetOutput.state == SGPacketOutputStateFinished) {
            finished = [self setState:SGFrameOutputStateFinished];
        }
        return ^{
            if (enough || (size > 15 * 1024 * 1024)) {
                [self->_packetOutput pause];
            } else {
                [self->_packetOutput resume];
            }
        };
    }, ^BOOL(SGBlock block) {
        block();
        [self->_delegate frameOutput:self didChangeCapacity:capacity type:type];
        finished();
        return YES;
    });
}

- (void)decodeLoop:(SGDecodeLoop *)decodeLoop didOutputFrame:(__kindof SGFrame *)frame
{
    [self->_delegate frameOutput:self didOutputFrame:frame];
}

@end
