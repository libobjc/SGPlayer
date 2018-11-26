//
//  SGFrameOutput.m
//  SGPlayer iOS
//
//  Created by Single on 2018/10/22.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGFrameOutput.h"
#import "SGAsset+Internal.h"
#import "SGPacketOutput.h"
#import "SGAsyncDecoder.h"
#import "SGAudioDecoder.h"
#import "SGVideoDecoder.h"
#import "SGMacro.h"
#import "SGLock.h"

@interface SGFrameOutput () <SGPacketOutputDelegate, SGAsyncDecoderDelegate>

{
    NSLock *_lock;
    NSError *_error;
    SGFrameOutputState _state;
    SGPacketOutput *_packetOutput;
    NSArray<SGTrack *> *_selectedTracks;
    NSArray<SGTrack *> *_finishedTracks;
    NSMutableDictionary<NSNumber *, SGCapacity *> *_capacitys;
    NSMutableDictionary<NSNumber *, SGAsyncDecoder *> *_decoders;
}

@end

@implementation SGFrameOutput

- (instancetype)initWithAsset:(SGAsset *)asset
{
    if (self = [super init]) {
        self->_lock = [[NSLock alloc] init];
        self->_decoders = [NSMutableDictionary dictionary];
        self->_capacitys = [NSMutableDictionary dictionary];
        self->_packetOutput = [[SGPacketOutput alloc] initWithDemuxable:[asset newDemuxable]];
        self->_packetOutput.delegate = self;
    }
    return self;
}

- (void)dealloc
{
    SGLockCondEXE10(self->_lock, ^BOOL {
        return self->_state != SGFrameOutputStateClosed;
    }, ^SGBlock {
        [self setState:SGFrameOutputStateClosed];
        [self->_packetOutput close];
        [self->_decoders enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, SGAsyncDecoder *obj, BOOL *stop) {
            [obj close];
        }];
        return nil;
    });
}

#pragma mark - Mapping

SGGet0Map(CMTime, duration, self->_packetOutput)
SGGet0Map(NSDictionary *, metadata, self->_packetOutput)
SGGet0Map(NSArray<SGTrack *> *, tracks, self->_packetOutput)

#pragma mark - Setter & Getter

- (NSError *)error
{
    __block NSError *ret = nil;
    SGLockEXE00(self->_lock, ^{
        ret = [self->_error copy];
    });
    return ret;
}

- (SGBlock)setState:(SGFrameOutputState)state
{
    if (_state == state) {
        return ^{};
    }
    _state = state;
    return ^{
        [self->_delegate frameOutput:self didChangeState:state];
    };
}

- (SGFrameOutputState)state
{
    __block SGFrameOutputState ret = SGFrameOutputStateNone;
    SGLockEXE00(self->_lock, ^{
        ret = self->_state;
    });
    return ret;
}

- (BOOL)selectTracks:(NSArray<SGTrack *> *)tracks
{
    return SGLockCondEXE10(self->_lock, ^BOOL {
        return ![self->_selectedTracks isEqualToArray:tracks];
    }, ^SGBlock {
        self->_selectedTracks = [tracks copy];
        [self openDecodersIfNeeded];
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

- (NSArray<SGTrack *> *)finishedTracks
{
    __block NSArray<SGTrack *> *ret = nil;
    SGLockEXE00(self->_lock, ^{
        ret = [self->_finishedTracks copy];
    });
    return ret;
}

- (NSArray<SGCapacity *> *)capacityWithTrack:(NSArray<SGTrack *> *)tracks
{
    __block NSMutableArray<SGCapacity *> *ret = [NSMutableArray array];
    SGLockEXE00(self->_lock, ^{
        for (SGTrack *obj in tracks) {
            SGCapacity *c = [[self->_capacitys objectForKey:@(obj.index)] copy];
            c = c ? c : [[SGCapacity alloc] init];
            [ret addObject:c];
        }
    });
    return [ret copy];
}

#pragma mark - Control

- (BOOL)open
{
    return SGLockCondEXE11(self->_lock, ^BOOL {
        return self->_state == SGFrameOutputStateNone;
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
        return self->_state == SGFrameOutputStateOpened;
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
        return self->_state != SGFrameOutputStateClosed;
    }, ^SGBlock {
        return [self setState:SGFrameOutputStateClosed];
    }, ^BOOL(SGBlock block) {
        block();
        [self->_packetOutput close];
        [self->_decoders enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, SGAsyncDecoder *obj, BOOL *stop) {
            [obj close];
        }];
        return YES;
    });
}

- (BOOL)pause:(NSArray<SGTrack *> *)tracks
{
    return SGLockEXE00(self->_lock, ^{
        for (SGTrack *obj in tracks) {
            SGAsyncDecoder *d = [self->_decoders objectForKey:@(obj.index)];
            [d pause];
        }
    });
}

- (BOOL)resume:(NSArray<SGTrack *> *)tracks
{
    return SGLockEXE00(self->_lock, ^{
        for (SGTrack *obj in tracks) {
            SGAsyncDecoder *d = [self->_decoders objectForKey:@(obj.index)];
            [d resume];
        }
    });
}

- (BOOL)seekable
{
    return [self->_packetOutput seekable];
}

- (BOOL)seekToTime:(CMTime)time result:(SGSeekResult)result
{
    SGWeakify(self)
    return [self->_packetOutput seekToTime:time result:^(CMTime time, NSError *error) {
        SGStrongify(self)
        if (!error) {
            [self->_decoders enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, SGAsyncDecoder *obj, BOOL *stop) {
                [obj flush];
            }];
        }
        if (result) {
            result(time, error);
        }
    }];
}

#pragma mark - Internal

- (void)openDecodersIfNeeded
{
    for (SGTrack *obj in self->_selectedTracks) {
        SGAsyncDecoder *decoder = [self->_decoders objectForKey:@(obj.index)];
        if (!decoder) {
            id<SGDecodable> decodable = nil;
            if (obj.type == SGMediaTypeAudio) {
                decodable = [[SGAudioDecoder alloc] init];
            } else if (obj.type == SGMediaTypeVideo) {
                decodable = [[SGVideoDecoder alloc] init];
            }
            NSAssert(decodable, @"Invalid Decodable.");
            decodable.index = obj.index;
            decoder = [[SGAsyncDecoder alloc] initWithDecodable:decodable];
            decoder.delegate = self;
            [self->_decoders setObject:decoder forKey:@(obj.index)];
            [decoder open];
        }
    }
}

#pragma mark - SGPacketOutputDelegate

- (void)packetOutput:(SGPacketOutput *)packetOutput didChangeState:(SGPacketOutputState)state
{
    SGLockEXE10(self->_lock, ^SGBlock {
        SGBlock b1 = ^{}, b2 = ^{}, b3 = ^{};
        switch (state) {
            case SGPacketOutputStateOpened: {
                b1 = [self setState:SGFrameOutputStateOpened];
                uint32_t nb_audio_track = 0;
                uint32_t nb_video_track = 0;
                NSMutableArray *tracks = [NSMutableArray array];
                for (SGTrack *obj in packetOutput.tracks) {
                    if (obj.type == SGMediaTypeAudio && nb_audio_track == 0) {
                        [tracks addObject:obj];
                        nb_audio_track += 1;
                    } else if (obj.type == SGMediaTypeVideo && nb_video_track == 0) {
                        [tracks addObject:obj];
                        nb_video_track += 1;
                    }
                    if (nb_audio_track && nb_video_track) {
                        break;
                    }
                }
                self->_selectedTracks = [tracks copy];
                [self openDecodersIfNeeded];
            }
                break;
            case SGPacketOutputStateReading:
                b1 = [self setState:SGFrameOutputStateReading];
                break;
            case SGPacketOutputStateSeeking:
                b1 = [self setState:SGFrameOutputStateSeeking];
                break;
            case SGPacketOutputStateFinished: {
                b1 = ^{
                    [self->_decoders enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, SGAsyncDecoder *obj, BOOL *stop) {
                        [obj finish];
                    }];
                };
            }
                break;
            case SGPacketOutputStateFailed:
                self->_error = [packetOutput.error copy];
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
    SGLockEXE10(self->_lock, ^SGBlock{
        SGAsyncDecoder *decoder = [self->_decoders objectForKey:@(packet.track.index)];
        return ^{
            [decoder putPacket:packet];
        };
    });
}

#pragma mark - SGDecoderDelegate

- (void)decoder:(SGAsyncDecoder *)decoder didChangeState:(SGAsyncDecoderState)state
{
    
}

- (void)decoder:(SGAsyncDecoder *)decoder didChangeCapacity:(SGCapacity *)capacity
{
    capacity = [capacity copy];
    __block SGTrack *track = nil;
    SGLockCondEXE11(self->_lock, ^BOOL {
        for (SGTrack *obj in self->_selectedTracks) {
            if (obj.index == decoder.decodable.index) {
                track = obj;
                break;
            }
        }
        return track && ![[self->_capacitys objectForKey:@(track.index)] isEqualToCapacity:capacity];
    }, ^SGBlock {
        [self->_capacitys setObject:capacity forKey:@(track.index)];
        SGBlock b1 = ^{};
        int size = 0;
        uint32_t is_enough = 1;
        uint32_t is_finished = self->_packetOutput.state == SGPacketOutputStateFinished;
        NSMutableArray *finished_tracks = [NSMutableArray array];
        for (SGTrack *obj in self->_selectedTracks) {
            SGCapacity *c = [self->_capacitys objectForKey:@(obj.index)];
            size += c.size;
            is_enough = is_enough && c.isEnough;
            if (is_finished && (!c || c.isEmpty)) {
                [finished_tracks addObject:obj];
            }
        }
        self->_finishedTracks = [finished_tracks copy];
        if ([self->_selectedTracks isEqualToArray:self->_finishedTracks]) {
            b1 = [self setState:SGFrameOutputStateFinished];
        }
        return ^{
            if (is_enough || (size > 15 * 1024 * 1024)) {
                [self->_packetOutput pause];
            } else {
                [self->_packetOutput resume];
            }
            b1();
        };
    }, ^BOOL(SGBlock block) {
        block();
        [self->_delegate frameOutput:self didChangeCapacity:[capacity copy] track:track];
        return YES;
    });
}

- (void)decoder:(SGAsyncDecoder *)decoder didOutputFrame:(SGFrame *)frame
{
    [self->_delegate frameOutput:self didOutputFrame:frame];
}

@end
