//
//  SGVideoDecoder.m
//  SGPlayer iOS
//
//  Created by Single on 2018/8/16.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGVideoDecoder.h"
#import "SGPacket+Internal.h"
#import "SGCodecContext.h"
#import "SGVideoFrame.h"

@interface SGVideoDecoder ()

@property (nonatomic, strong) SGCodecContext * codecContext;
@property (nonatomic, strong) SGCodecDescription * codecDescription;

@end

@implementation SGVideoDecoder

- (SGMediaType)type
{
    return SGMediaTypeVideo;
}

- (void)setup
{
    self.codecContext = [[SGCodecContext alloc] initWithCodecDescription:[self.codecDescription copy] frameClass:[SGVideoFrame class]];
    [self.codecContext open];
}

- (void)destroy
{
    [self.codecContext close];
    self.codecContext = nil;
}

- (void)flush
{
    [self.codecContext flush];
}

- (NSArray <__kindof SGFrame *> *)decode:(SGPacket *)packet
{
    SGCodecDescription * cd = packet.codecDescription;
    if (cd && ![cd isEqualToCodecpar:self.codecDescription]) {
        self.codecDescription = cd;
        [self destroy];
        [self setup];
    }
    return [self.codecContext decode:packet];
}

@end
