//
//  SGFFError.h
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, SGFFErrorCode)
{
    SGFFErrorCodeUnknown,
    SGFFErrorCodeFormatCreate,
    SGFFErrorCodeFormatOpenInput,
    SGFFErrorCodeFormatFindStreamInfo,
    SGFFErrorCodeStreamNotFound,
    SGFFErrorCodeCodecContextCreate,
    SGFFErrorCodeCodecContextSetParam,
    SGFFErrorCodeCodecFindDecoder,
    SGFFErrorCodeCodecVideoSendPacket,
    SGFFErrorCodeCodecAudioSendPacket,
    SGFFErrorCodeCodecVideoReceiveFrame,
    SGFFErrorCodeCodecAudioReceiveFrame,
    SGFFErrorCodeCodecReceiveFrame,
    SGFFErrorCodeCodecOpen2,
    SGFFErrorCodeAuidoSwrInit,
};

NSError * SGFFGetError(int result);
NSError * SGFFGetErrorCode(int result, NSUInteger errorCode);
NSError * SGFFCreateErrorCode(NSUInteger errorCode);
