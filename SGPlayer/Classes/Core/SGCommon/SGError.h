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
    SGErrorCodeNoValidFormat,
    SGErrorCodeNoValidTrackToPlay,
    SGErrorCodeFormatNotSeekable,
};

typedef NS_ENUM(NSUInteger, SGOperationCode)
{
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
};

NSError * SGEGetError(int result, SGOperationCode operation);
NSError * SGECreateError(NSUInteger code, SGOperationCode operation);
