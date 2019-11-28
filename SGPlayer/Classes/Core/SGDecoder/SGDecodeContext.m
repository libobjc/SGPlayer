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

static SGPacket *kFlushPacket = nil;
static SGPacket *kFinishPacket = nil;
static NSInteger kMaxPredecoderCount = 2;

@interface SGDecodeContextUnit : NSObject

@property (nonatomic, strong) NSArray *frames;
@property (nonatomic, strong) id<SGDecodable> decoder;
@property (nonatomic, strong) SGObjectQueue *packetQueue;
@property (nonatomic, strong) SGCodecDescriptor *codecDescriptor;

@end

@implementation SGDecodeContextUnit

- (void)dealloc
{
    for (SGFrame *obj in self->_frames) {
        [obj unlock];
    }
    self->_frames = nil;
}

@end

@interface SGDecodeContext ()

@property (nonatomic, readonly) BOOL needsFlush;
@property (nonatomic, readonly) NSInteger decodeIndex;
@property (nonatomic, readonly) NSInteger predecodeIndex;
@property (nonatomic, strong, readonly) Class decoderClass;
@property (nonatomic, strong, readonly) NSMutableArray<id<SGDecodable>> *decoders;
@property (nonatomic, strong, readonly) NSMutableArray<SGDecodeContextUnit *> *units;

@end

@implementation SGDecodeContext

- (instancetype)initWithDecoderClass:(Class)decoderClass
{
    if (self = [super init]) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            kFlushPacket = [[SGPacket alloc] init];
            kFinishPacket = [[SGPacket alloc] init];
            [kFlushPacket lock];
            [kFinishPacket lock];
        });
        self->_needsFlush = NO;
        self->_decodeIndex = 0;
        self->_predecodeIndex = 0;
        self->_decoderClass = decoderClass;
        self->_decodeTimeStamp = kCMTimeInvalid;
        self->_units = [NSMutableArray array];
        self->_decoders = [NSMutableArray array];
    }
    return self;
}

- (SGCapacity)capacity
{
    SGCapacity capacity = SGCapacityCreate();
    for (SGDecodeContextUnit *obj in self->_units) {
        capacity = SGCapacityAdd(capacity, obj.packetQueue.capacity);
    }
    return capacity;
}

- (void)putPacket:(SGPacket *)packet
{
    SGDecodeContextUnit *unit = self->_units.lastObject;
    if (![unit.codecDescriptor isEqualToDescriptor:packet.codecDescriptor]) {
        unit = [[SGDecodeContextUnit alloc] init];
        unit.packetQueue = [[SGObjectQueue alloc] init];
        unit.codecDescriptor = packet.codecDescriptor.copy;
        [self->_units addObject:unit];
    }
    [unit.packetQueue putObjectSync:packet];
}

- (BOOL)needsPredecode
{
    NSInteger count = 0;
    for (NSInteger i = self->_decodeIndex + 1; i < self->_units.count; i++) {
        if (count >= kMaxPredecoderCount) {
            return NO;
        }
        SGDecodeContextUnit *unit = self->_units[i];
        SGCodecDescriptor *cd = unit.codecDescriptor;
        if (cd.codecpar &&
            cd.codecpar->codec_type == AVMEDIA_TYPE_VIDEO &&
            (cd.codecpar->codec_id == AV_CODEC_ID_H264 ||
             cd.codecpar->codec_id == AV_CODEC_ID_H265)) {
            count += 1;
            if (unit.frames.count > 0) {
                continue;
            }
            self->_predecodeIndex = i;
            return unit.packetQueue.capacity.count > 0;
        }
    }
    return NO;
}

- (void)predecode:(SGBlock)lock unlock:(SGBlock)unlock
{
    SGPacket *packet = nil;
    SGDecodeContextUnit *unit = self->_units[self->_predecodeIndex];
    if ([unit.packetQueue getObjectAsync:&packet]) {
        [self setDecoderIfNeeded:unit];
        id<SGDecodable> decoder = unit.decoder;
        unlock();
        NSArray *frames = [decoder decode:packet];
        lock();
        unit.frames = frames;
        [packet unlock];
    }
}

- (NSArray<SGFrame *> *)decode:(SGBlock)lock unlock:(SGBlock)unlock
{
    NSMutableArray *frames = [NSMutableArray array];
    NSInteger index = 0;
    SGPacket *packet = nil;
    SGDecodeContextUnit *unit = nil;
    for (NSInteger i = 0; i < self->_units.count; i++) {
        SGDecodeContextUnit *obj = self->_units[i];
        if ([obj.packetQueue getObjectAsync:&packet]) {
            index = i;
            unit = obj;
            break;
        }
    }
    NSAssert(packet, @"Invalid Packet.");
    if (packet == kFlushPacket) {
        self->_needsFlush = NO;
        self->_decodeIndex = 0;
        self->_predecodeIndex = 0;
        self->_decodeTimeStamp = kCMTimeInvalid;
        [self->_units removeObjectAtIndex:0];
    } else if (packet == kFinishPacket) {
        [self->_units removeLastObject];
        for (NSInteger i = self->_decodeIndex; i < self->_units.count; i++) {
            SGDecodeContextUnit *obj = self->_units[i];
            [frames addObjectsFromArray:obj.frames];
            [frames addObjectsFromArray:[obj.decoder finish]];
            [self removeDecoderIfNeeded:obj];
        }
        [self->_units removeAllObjects];
    } else {
        self->_decodeTimeStamp = packet.decodeTimeStamp;
        if (self->_decodeIndex < index) {
            for (NSInteger i = self->_decodeIndex; i < MIN(index, self->_units.count); i++) {
                SGDecodeContextUnit *obj = self->_units[i];
                [frames addObjectsFromArray:obj.frames];
                [frames addObjectsFromArray:[obj.decoder finish]];
                [self removeDecoderIfNeeded:obj];
            }
            [frames addObjectsFromArray:unit.frames];
            unit.frames = nil;
            self->_decodeIndex = index;
        }
        [self setDecoderIfNeeded:unit];
        id<SGDecodable> decoder = unit.decoder;
        unlock();
        [frames addObjectsFromArray:[decoder decode:packet]];
        lock();
        [packet unlock];
    }
    if (self->_needsFlush) {
        for (SGFrame *obj in frames) {
            [obj unlock];
        }
        [frames removeAllObjects];
    }
    return frames.count ? frames.copy : nil;
}

- (void)setNeedsFlush
{
    self->_needsFlush = YES;
    for (SGDecodeContextUnit *obj in self->_units) {
        [self removeDecoderIfNeeded:obj];
    }
    [self->_units removeAllObjects];
    SGDecodeContextUnit *unit = [[SGDecodeContextUnit alloc] init];
    unit.packetQueue = [[SGObjectQueue alloc] init];
    unit.codecDescriptor = [[SGCodecDescriptor alloc] init];
    [unit.packetQueue putObjectSync:kFlushPacket];
    [self->_units addObject:unit];
}

- (void)markAsFinished
{
    SGDecodeContextUnit *unit = [[SGDecodeContextUnit alloc] init];
    unit.packetQueue = [[SGObjectQueue alloc] init];
    unit.codecDescriptor = [[SGCodecDescriptor alloc] init];
    [unit.packetQueue putObjectSync:kFinishPacket];
    [self->_units addObject:unit];
}

- (void)destory
{
    [self->_units removeAllObjects];
}

- (void)setDecoderIfNeeded:(SGDecodeContextUnit *)unit
{
    if (!unit.decoder) {
        if (self->_decoders.count) {
            unit.decoder = self->_decoders.lastObject;
            [unit.decoder flush];
            [self->_decoders removeLastObject];
        } else {
            unit.decoder = [[self->_decoderClass alloc] init];
            unit.decoder.options = self->_options;
        }
    }
}

- (void)removeDecoderIfNeeded:(SGDecodeContextUnit *)unit
{
    if (unit.decoder) {
        [self->_decoders addObject:unit.decoder];
        unit.decoder = nil;
    }
}

@end
