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
typedef NS_ENUM(int, SGErrorCode) {
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
typedef NS_ENUM(int, SGOperationCode) {
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
NSError * SGEGetError(int result, SGOperationCode operation);

/**
 *
 */
NSError * SGECreateError(int code, SGOperationCode operation);
