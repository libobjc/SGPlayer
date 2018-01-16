//
//  SGFFTools.h
//  SGPlayer
//
//  Created by Single on 19/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGPlayerMacro.h"
#import "avformat.h"

typedef NS_ENUM(NSUInteger, SGFFDecoderErrorCode) {
    SGFFDecoderErrorCodeFormatCreate,
    SGFFDecoderErrorCodeFormatOpenInput,
    SGFFDecoderErrorCodeFormatFindStreamInfo,
    SGFFDecoderErrorCodeStreamNotFound,
    SGFFDecoderErrorCodeCodecContextCreate,
    SGFFDecoderErrorCodeCodecContextSetParam,
    SGFFDecoderErrorCodeCodecFindDecoder,
    SGFFDecoderErrorCodeCodecVideoSendPacket,
    SGFFDecoderErrorCodeCodecAudioSendPacket,
    SGFFDecoderErrorCodeCodecVideoReceiveFrame,
    SGFFDecoderErrorCodeCodecAudioReceiveFrame,
    SGFFDecoderErrorCodeCodecOpen2,
    SGFFDecoderErrorCodeAuidoSwrInit,
};

#pragma mark - Log Config

#define SGFFFFmpegLogEnable     0
#define SGFFSynLogEnable        0
#define SGFFThreadLogEnable     0
#define SGFFPacketLogEnable     0
#define SGFFSleepLogEnable      0
#define SGFFDecodeLogEnable     0
#define SGFFErrorLogEnable      0

#if SGFFFFmpegLogEnable
#define SGFFFFmpegLog(...)       NSLog(__VA_ARGS__)
#else
#define SGFFFFmpegLog(...)
#endif

#if SGFFSynLogEnable
#define SGFFSynLog(...)          NSLog(__VA_ARGS__)
#else
#define SGFFSynLog(...)
#endif

#if SGFFThreadLogEnable
#define SGFFThreadLog(...)       NSLog(__VA_ARGS__)
#else
#define SGFFThreadLog(...)
#endif

#if SGFFPacketLogEnable
#define SGFFPacketLog(...)       NSLog(__VA_ARGS__)
#else
#define SGFFPacketLog(...)
#endif

#if SGFFSleepLogEnable
#define SGFFSleepLog(...)        NSLog(__VA_ARGS__)
#else
#define SGFFSleepLog(...)
#endif

#if SGFFDecodeLogEnable
#define SGFFDecodeLog(...)       NSLog(__VA_ARGS__)
#else
#define SGFFDecodeLog(...)
#endif

#if SGFFErrorLogEnable
#define SGFFErrorLog(...)        NSLog(__VA_ARGS__)
#else
#define SGFFErrorLog(...)
#endif


#pragma mark - Util Function

void SGFFLog(void * context, int level, const char * format, va_list args);

NSError * SGFFCheckError(int result);
NSError * SGFFCheckErrorCode(int result, NSUInteger errorCode);

double SGFFStreamGetTimebase(AVStream * stream, double default_timebase);
double SGFFStreamGetFPS(AVStream * stream, double timebase);

NSDictionary * SGFFFoundationBrigeOfAVDictionary(AVDictionary * avDictionary);
AVDictionary * SGFFFFmpegBrigeOfNSDictionary(NSDictionary * dictionary);
