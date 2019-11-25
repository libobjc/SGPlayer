//
//  SGDecodeContext.m
//  KTVMediaKitDemo
//
//  Created by Single on 2019/11/18.
//  Copyright © 2019 Single. All rights reserved.
//

#import "SGDecodeContext.h"
#import "SGPacket+Internal.h"
#import "SGObjectQueue.h"
#import "SGDecodable.h"

static SGPacket *gFlushPacket = nil;
static SGPacket *gFinishPacket = nil;

@interface SGDecodeContext ()

@property (nonatomic, readonly) BOOL needsFlush;
@property (nonatomic, readonly) NSInteger decodeIndex;
@property (nonatomic, readonly) NSInteger predecodeIndex;
@property (nonatomic, copy, readonly) Class decoderClass;
@property (nonatomic, strong, readonly) id<SGDecodable> decoder;
@property (nonatomic, strong, readonly) id<SGDecodable> predecoder;
@property (nonatomic, strong, readonly) NSArray<SGFrame *> *predecodeFrames;
@property (nonatomic, strong, readonly) NSMutableArray<SGObjectQueue *> *packetQueues;
@property (nonatomic, strong, readonly) NSMutableArray<SGCodecDescriptor *> *codecDescriptors;

@end

@implementation SGDecodeContext

- (instancetype)initWithDecoderClass:(Class)decoderClass
{
    if (self = [super init]) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            gFlushPacket = [[SGPacket alloc] init];
            gFinishPacket = [[SGPacket alloc] init];
            [gFlushPacket lock];
            [gFinishPacket lock];
        });
        self->_needsFlush = NO;
        self->_decodeIndex = 0;
        self->_predecodeIndex = 0;
        self->_decoderClass = decoderClass;
        self->_decodeTimeStamp = kCMTimeInvalid;
        self->_packetQueues = [NSMutableArray array];
        self->_codecDescriptors = [NSMutableArray array];
    }
    return self;
}

- (SGCapacity)capacity
{
    SGCapacity capacity = SGCapacityCreate();
    for (SGObjectQueue *obj in self->_packetQueues) {
        capacity = SGCapacityAdd(capacity, obj.capacity);
    }
    return capacity;
}

- (void)putPacket:(SGPacket *)packet
{
    SGObjectQueue *packetQueue = self->_packetQueues.lastObject;
    SGCodecDescriptor *codecDescriptor = self->_codecDescriptors.lastObject;
    if (![codecDescriptor isEqualCodecContextToDescriptor:packet.codecDescriptor]) {
        packetQueue = [[SGObjectQueue alloc] init];
        codecDescriptor = [packet.codecDescriptor copy];
        [self->_packetQueues addObject:packetQueue];
        [self->_codecDescriptors addObject:codecDescriptor];
    }
    [packetQueue putObjectSync:packet];
}

- (BOOL)needsPredecode
{
    if (self->_predecodeFrames.count > 0) {
        return NO;
    }
    for (NSInteger i = self->_decodeIndex + 1; i < self->_packetQueues.count; i++) {
        SGCodecDescriptor *codecDescriptor = self->_codecDescriptors[i];
        if (codecDescriptor.codecpar &&
            codecDescriptor.codecpar->codec_type == AVMEDIA_TYPE_VIDEO &&
            (codecDescriptor.codecpar->codec_id == AV_CODEC_ID_H264 ||
             codecDescriptor.codecpar->codec_id == AV_CODEC_ID_H265)) {
            self->_predecodeIndex = i;
            return self->_packetQueues[i].capacity.count > 0;
        }
    }
    return NO;
}

- (void)predecode:(SGBlock)lock unlock:(SGBlock)unlock
{
    SGPacket *packet = nil;
    SGObjectQueue *queue = self->_packetQueues[self->_predecodeIndex];
    if ([queue getObjectAsync:&packet]) {
        if (!self->_predecoder) {
            self->_predecoder = [[self->_decoderClass alloc] init];
            self->_predecoder.options = self->_options;
        }
        self->_predecodeFrames = [self->_predecoder decode:packet];
        [packet unlock];
    }
}

- (NSArray<SGFrame *> *)decode:(SGBlock)lock unlock:(SGBlock)unlock
{
    NSMutableArray<SGFrame *> *objs = [NSMutableArray array];
    SGPacket *packet = nil;
    SGObjectQueue *queue = nil;
    for (SGObjectQueue *obj in self->_packetQueues) {
        if ([obj getObjectAsync:&packet]) {
            queue = obj;
            break;
        }
    }
    NSAssert(packet, @"Invalid Packet.");
    if (packet == gFlushPacket) {
        self->_needsFlush = NO;
        self->_decodeIndex = 0;
        self->_decodeTimeStamp = kCMTimeInvalid;
        [self->_packetQueues removeObjectAtIndex:0];
        [self->_codecDescriptors removeObjectAtIndex:0];
        for (SGFrame *obj in self->_predecodeFrames) {
            [obj unlock];
        }
        self->_predecodeFrames = nil;
        self->_predecodeIndex = 0;
        unlock();
        [self->_decoder flush];
        [self->_predecoder flush];
        lock();
    } else if (packet == gFinishPacket) {
        [self->_packetQueues removeLastObject];
        [self->_codecDescriptors removeLastObject];
        unlock();
        [objs addObjectsFromArray:[self->_decoder finish]];
        [objs addObjectsFromArray:self->_predecodeFrames];
        self->_predecodeFrames = nil;
        self->_predecodeIndex = 0;
        lock();
    } else {
        self->_decodeTimeStamp = packet.decodeTimeStamp;
        unlock();
        NSInteger index = [self->_packetQueues indexOfObject:queue];
        if (self->_decodeIndex < index) {
            self->_decodeIndex = index;
            [objs addObjectsFromArray:[self->_decoder finish]];
            if (self->_predecodeIndex <= index) {
                if (self->_predecodeIndex == index) {
                    self->_decoder = self->_predecoder;
                }
                [objs addObjectsFromArray:self->_predecodeFrames];
                self->_predecodeFrames = nil;
                self->_predecodeIndex = 0;
                self->_predecoder = nil;
            }
        }
        id<SGDecodable> decoder = self->_decoder;
        if (!decoder) {
            decoder = [[self->_decoderClass alloc] init];
            decoder.options = self->_options;
            self->_decoder = decoder;
        }
        [objs addObjectsFromArray:[decoder decode:packet]];
        [packet unlock];
        lock();
    }
    if (self->_needsFlush) {
        for (SGFrame *obj in objs) {
            [obj unlock];
        }
        [objs removeAllObjects];
    }
    return objs.count ? objs.copy : nil;
}

- (void)setNeedsFlush
{
    self->_needsFlush = YES;
    [self->_packetQueues removeAllObjects];
    [self->_codecDescriptors removeAllObjects];
    [self->_packetQueues addObject:[[SGObjectQueue alloc] init]];
    [self->_codecDescriptors addObject:[[SGCodecDescriptor alloc] init]];
    [self->_packetQueues.lastObject putObjectSync:gFlushPacket];
}

- (void)markAsFinished
{
    [self->_packetQueues addObject:[[SGObjectQueue alloc] init]];
    [self->_codecDescriptors addObject:[[SGCodecDescriptor alloc] init]];
    [self->_packetQueues.lastObject putObjectSync:gFinishPacket];
}

- (void)destory
{
    [self->_packetQueues removeAllObjects];
    [self->_codecDescriptors removeAllObjects];
    for (SGFrame *obj in self->_predecodeFrames) {
        [obj unlock];
    }
    self->_predecodeFrames = nil;
    self->_predecodeIndex = 0;
}

@end
