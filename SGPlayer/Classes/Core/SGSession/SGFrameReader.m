//
//  SGFrameReader.m
//  SGPlayer
//
//  Created by Single on 2019/11/12.
//  Copyright © 2019 single. All rights reserved.
//

#import "SGFrameReader.h"
#import "SGAsset+Internal.h"
#import "SGAudioDecoder.h"
#import "SGVideoDecoder.h"
#import "SGObjectQueue.h"
#import "SGDecodable.h"
#import "SGOptions.h"
#import "SGMacro.h"
#import "SGError.h"
#import "SGLock.h"

@interface SGFrameReader () <SGDemuxableDelegate>

{
    struct {
        BOOL noMorePacket;
    } _flags;
}

@property (nonatomic, strong, readonly) id<SGDemuxable> demuxer;
@property (nonatomic, strong, readonly) SGObjectQueue *frameQueue;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSNumber *, id<SGDecodable>> *decoders;

@end

@implementation SGFrameReader

@synthesize selectedTracks = _selectedTracks;

- (instancetype)initWithAsset:(SGAsset *)asset
{
    if (self = [super init]) {
        self->_demuxer = [asset newDemuxer];
        self->_demuxer.delegate = self;
        self->_demuxer.options = [SGOptions sharedOptions].demuxer.copy;
        self->_decoderOptions = [SGOptions sharedOptions].decoder.copy;
    }
    return self;
}

- (void)dealloc
{
    [self close];
}

#pragma mark - Mapping

SGGet0Map(CMTime, duration, self->_demuxer)
SGGet0Map(NSError *, seekable, self->_demuxer);
SGGet0Map(NSDictionary *, metadata, self->_demuxer)
SGGet0Map(SGDemuxerOptions *, options, self->_demuxer)
SGGet0Map(NSArray<SGTrack *> *, tracks, self->_demuxer)
SGGet00Map(SGDemuxerOptions *,demuxerOptions, options, self->_demuxer)
SGSet11Map(void, setDemuxerOptions, setOptions, SGDemuxerOptions *, self->_demuxer)

#pragma mark - Setter & Getter

- (NSArray<SGTrack *> *)selectedTracks
{
    return [self->_selectedTracks copy];
}

- (void)setDecoderOptions:(SGDecoderOptions *)decoderOptions
{
    self->_decoderOptions = decoderOptions;
    for (id<SGDecodable> obj in self->_decoders.allValues) {
        obj.options = decoderOptions;
    }
}

#pragma mark - Control

- (NSError *)open
{
    NSError *error = [self->_demuxer open];
    if (!error) {
        self->_selectedTracks = [self->_demuxer.tracks copy];
        self->_decoders = [[NSMutableDictionary alloc] init];
        self->_frameQueue = [[SGObjectQueue alloc] init];
        self->_frameQueue.shouldSortObjects = YES;
    }
    return error;
}

- (NSError *)close
{
    self->_decoders = nil;
    self->_frameQueue = nil;
    return [self->_demuxer close];
}

- (NSError *)seekToTime:(CMTime)time
{
    return [self seekToTime:time toleranceBefor:kCMTimeInvalid toleranceAfter:kCMTimeInvalid];
}

- (NSError *)seekToTime:(CMTime)time toleranceBefor:(CMTime)toleranceBefor toleranceAfter:(CMTime)toleranceAfter
{
    NSError *error = [self seekToTime:time toleranceBefor:toleranceBefor toleranceAfter:toleranceAfter];
    if (!error) {
        for (id<SGDecodable> obj in self->_decoders.allValues) {
            [obj flush];
        }
        [self->_frameQueue flush];
        self->_flags.noMorePacket = NO;
    }
    return error;
}

- (NSError *)selectTracks:(NSArray<SGTrack *> *)tracks
{
    self->_selectedTracks = [tracks copy];
    return nil;
}

- (NSError *)nextFrame:(__kindof SGFrame **)frame
{
    NSError *err= nil;
    __kindof SGFrame *ret = nil;
    while (!ret && !err) {
        if ([self->_frameQueue getObjectAsync:&ret]) {
            continue;
        }
        if (self->_flags.noMorePacket) {
            err = SGCreateError(SGErrorCodeDemuxerEndOfFile, SGActionCodeNextFrame);
            continue;
        }
        SGPacket *packet = nil;
        [self->_demuxer nextPacket:&packet];
        NSArray<__kindof SGFrame *> *objs = nil;
        if (packet) {
            if (![self->_selectedTracks containsObject:packet.track]) {
                [packet unlock];
                continue;
            }
            id<SGDecodable> decoder = [self->_decoders objectForKey:@(packet.track.index)];
            if (!decoder) {
                if (packet.track.type == SGMediaTypeAudio) {
                    decoder = [[SGAudioDecoder alloc] init];
                }
                if (packet.track.type == SGMediaTypeVideo) {
                    decoder = [[SGVideoDecoder alloc] init];
                }
                if (decoder) {
                    decoder.options = self->_decoderOptions;
                    [self->_decoders setObject:decoder forKey:@(packet.track.index)];
                }
            }
            objs = [decoder decode:packet];
            [packet unlock];
        } else {
            NSMutableArray<__kindof SGFrame *> *mObjs = [NSMutableArray array];
            for (id<SGDecodable> decoder in self->_decoders.allValues) {
                [mObjs addObjectsFromArray:[decoder finish]];
            }
            objs = [mObjs copy];
            self->_flags.noMorePacket = YES;
        }
        for (id<SGData> obj in objs) {
            [self->_frameQueue putObjectSync:obj];
            [obj unlock];
        }
    }
    if (ret) {
        if (frame) {
            *frame = ret;
        } else {
            [ret unlock];
        }
    }
    return err;
}

#pragma mark - SGDemuxableDelegate

- (BOOL)demuxableShouldAbortBlockingFunctions:(id<SGDemuxable>)demuxable
{
    if ([self->_delegate respondsToSelector:@selector(demuxableShouldAbortBlockingFunctions:)]) {
        return [self->_delegate frameReaderShouldAbortBlockingFunctions:self];
    }
    return NO;
}

@end
