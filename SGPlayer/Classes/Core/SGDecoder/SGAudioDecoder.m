//
//  SGAudioDecoder.m
//  SGPlayer iOS
//
//  Created by Single on 2018/8/16.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGAudioDecoder.h"
#import "SGPacket+Internal.h"
#import "SGCodecContext.h"
#import "SGAudioFrame.h"

@interface SGAudioDecoder ()

@property (nonatomic, strong) SGCodecContext * codecContext;
@property (nonatomic, strong) SGCodecDescription * codecDescription;

@end

@implementation SGAudioDecoder

- (SGMediaType)type
{
    return SGMediaTypeAudio;
}

- (void)setup
{
    self.codecContext = [[SGCodecContext alloc] initWithCodecDescription:[self.codecDescription copy]];
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
    if (cd && ![cd isEqualToDescription:self.codecDescription]) {
        self.codecDescription = cd;
        [self destroy];
        [self setup];
    }
    return [self.codecContext decode:packet];
}

@end
