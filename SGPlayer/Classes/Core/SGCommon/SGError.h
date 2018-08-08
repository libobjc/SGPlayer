//
//  SGError.h
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, SGErrorCode)
{
    SGErrorCodeUnknown,
    SGErrorCodeFormatCreate,
    SGErrorCodeFormatOpenInput,
    SGErrorCodeFormatFindStreamInfo,
    SGErrorCodeStreamNotFound,
    SGErrorCodeCodecContextCreate,
    SGErrorCodeCodecContextSetParam,
    SGErrorCodeCodecFindDecoder,
    SGErrorCodeCodecVideoSendPacket,
    SGErrorCodeCodecAudioSendPacket,
    SGErrorCodeCodecVideoReceiveFrame,
    SGErrorCodeCodecAudioReceiveFrame,
    SGErrorCodeCodecReceiveFrame,
    SGErrorCodeCodecOpen2,
    SGErrorCodeAuidoSwrInit,
};

NSError * SGFFGetError(int result);
NSError * SGFFGetErrorCode(int result, NSUInteger errorCode);
NSError * SGFFCreateErrorCode(NSUInteger errorCode);
