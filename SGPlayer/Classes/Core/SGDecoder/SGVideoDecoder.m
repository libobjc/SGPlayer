//
//  SGVideoDecoder.m
//  SGPlayer iOS
//
//  Created by Single on 2018/8/16.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGVideoDecoder.h"
#import "SGPacket+Internal.h"
#import "SGFrame+Internal.h"
#import "SGCodecContext.h"
#import "SGVideoFrame.h"

@interface SGVideoDecoder ()

{
    uint32_t _is_end_output;
}

@property (nonatomic, strong) SGCodecContext * codecContext;
@property (nonatomic, strong) SGCodecDescription * codecDescription;
@property (nonatomic) CMTimeRange timeRange;

@end

@implementation SGVideoDecoder

@synthesize index = _index;

- (void)setup
{
    SGCodecDescription * cd = self.codecDescription;
    self.codecContext = [[SGCodecContext alloc] initWithTimebase:cd.timebase codecpar:cd.codecpar frameClass:[SGVideoFrame class]];
    [self.codecContext open];
}

- (void)destroy
{
    self->_is_end_output = 0;
    [self.codecContext close];
    self.codecContext = nil;
}

- (void)flush
{
    self->_is_end_output = 0;
    [self.codecContext flush];
}

- (NSArray <__kindof SGFrame *> *)decode:(SGPacket *)packet
{
    SGCodecDescription * cd = packet.codecDescription;
    if (cd && ![cd isEqualToDescription:self.codecDescription]) {
        self.codecDescription = cd;
        self.timeRange = cd.layoutTimeRange;
        [self destroy];
        [self setup];
    }
    if (self->_is_end_output) {
        return nil;
    }
    NSMutableArray * ret = [NSMutableArray array];
    NSArray <SGVideoFrame *> * frames = [self.codecContext decode:packet];
    for (SGVideoFrame * obj in frames) {
        obj.codecDescription = self.codecDescription;
        [obj fill];
        if (CMTimeCompare(obj.timeStamp, self.timeRange.start) < 0) {
            [obj unlock];
            continue;
        }
        if (CMTimeCompare(obj.timeStamp, CMTimeRangeGetEnd(self.timeRange)) >= 0) {
            self->_is_end_output = 1;
            [obj unlock];
            continue;
        }
        [ret addObject:obj];
    }
    return ret;
}

@end
