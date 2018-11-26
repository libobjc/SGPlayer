//
//  SGError.h
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *
 */
typedef NS_ENUM(UInt32, SGErrorCode) {
    SGErrorCodeUnknown,
    SGErrorCodeNoValidFormat,
    SGErrorCodeNoValidTrackToPlay,
    SGErrorCodeFormatNotSeekable,
    SGErrorCodePacketOutputCannotOpen,
    SGErrorCodePacketOutputCannotClose,
    SGErrorCodePacketOutputCannotPause,
    SGErrorCodePacketOutputCannotResume,
    SGErrorCodePacketOutputCannotSeek,
    SGErrorCodePacketOutputCancelSeek,
    SGErrorCodeURLDemuxerFunnelFinished,
    SGErrorCodeConcatDemuxerNotFoundUnit,
    SGErrorCodeConcatDemuxerUnitInvaildDuration,
    SGErrorCodeMutilDemuxerEndOfFile,
};

/**
 *
 */
typedef NS_ENUM(UInt32, SGOperationCode) {
    SGOperationCodeUnknown,
    SGOperationCodeFormatCreate,
    SGOperationCodeFormatOpenInput,
    SGOperationCodeFormatFindStreamInfo,
    SGOperationCodeFormatSeekFrame,
    SGOperationCodeFormatReadFrame,
    SGOperationCodeFormatGetSeekable,
    SGOperationCodeCodecSetParametersToContext,
    SGOperationCodeCodecOpen2,
    SGOperationCodeAuidoSwrInit,
    SGOperationCodeSessionOpen,
    SGOperationCodePacketOutputOpen,
    SGOperationCodePacketOutputClose,
    SGOperationCodePacketOutputPause,
    SGOperationCodePacketOutputResmue,
    SGOperationCodePacketOutputSeek,
    SGOperationCodeURLDemuxerFunnelNext,
    SGOperationCodeURLDemuxerSeek,
    SGOperationCodeConcatDemuxerUnitOpen,
    SGOperationCodeMutilDemuxerNext,
};

/**
 *
 */
NSError * SGEGetError(SInt32 result, SGOperationCode operation);

/**
 *
 */
NSError * SGECreateError(SInt64 code, SGOperationCode operation);
