//
//  SGError.h
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, SGErrorCode) {
    SGErrorCodeUnknown = 0,
    SGErrorImmediateExitRequested,
    SGErrorCodeNoValidFormat,
    SGErrorCodeFormatNotSeekable,
    SGErrorCodePacketOutputCancelSeek,
    SGErrorCodeDemuxerEndOfFile,
    SGErrorCodeInvlidTime,
};

typedef NS_ENUM(NSUInteger, SGActionCode) {
    SGActionCodeUnknown = 0,
    SGActionCodeFormatCreate,
    SGActionCodeFormatOpenInput,
    SGActionCodeFormatFindStreamInfo,
    SGActionCodeFormatSeekFrame,
    SGActionCodeFormatReadFrame,
    SGActionCodeFormatGetSeekable,
    SGActionCodeCodecSetParametersToContext,
    SGActionCodeCodecOpen2,
    SGActionCodePacketOutputSeek,
    SGActionCodeURLDemuxerFunnelNext,
    SGActionCodeMutilDemuxerNext,
    SGActionCodeSegmentDemuxerNext,
    SGActionCodeNextFrame,
};

NSError * SGGetFFError(int result, SGActionCode operation);
NSError * SGCreateError(NSUInteger code, SGActionCode operation);
