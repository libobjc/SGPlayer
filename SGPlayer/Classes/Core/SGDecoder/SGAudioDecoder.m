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
@property (nonatomic, strong) SGCodecpar * codecpar;

@end

@implementation SGAudioDecoder

- (SGMediaType)type
{
    return SGMediaTypeAudio;
}

- (void)setup
{
    self.codecContext = [[SGCodecContext alloc] initWithCodecpar:[self.codecpar copy] frameClass:[SGAudioFrame class]];
    [self.codecContext open];
}

- (void)destroy
{
    [self.codecContext close];
    self.codecContext = nil;
}

- (NSArray <__kindof SGFrame *> *)decode:(SGPacket *)packet
{
    SGCodecpar * codecpar = packet.codecpar;
    if (codecpar && ![codecpar isEqualToCodecpar:self.codecpar]) {
        self.codecpar = codecpar;
        [self destroy];
    }
    return [self.codecContext decode:packet];
}

- (void)flush
{
    [self.codecContext flush];
}

@end
