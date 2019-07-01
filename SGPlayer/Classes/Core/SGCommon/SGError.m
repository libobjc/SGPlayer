//
//  SGError.m
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGError.h"
#import "SGFFmpeg.h"

static NSString * const SGErrorUserInfoKeyOperation = @"SGErrorUserInfoKeyOperation";

NSError * SGGetFFError(int result, SGActionCode operation)
{
    if (result >= 0) {
        return nil;
    }
    char *data = malloc(256);
    av_strerror(result, data, 256);
    NSString *domain = [NSString stringWithFormat:@"SGPlayer-Error-FFmpeg code : %d, msg : %s", result, data];
    free(data);
    if (result == AVERROR_EXIT) {
        result = SGErrorImmediateExitRequested;
    } else if (result == AVERROR_EOF) {
        result = SGErrorCodeDemuxerEndOfFile;
    }
    return [NSError errorWithDomain:domain code:result userInfo:@{SGErrorUserInfoKeyOperation : @(operation)}];
}

NSError * SGCreateError(NSUInteger code, SGActionCode operation)
{
    return [NSError errorWithDomain:@"SGPlayer-Error-SGErrorCode" code:(NSInteger)code userInfo:@{SGErrorUserInfoKeyOperation : @(operation)}];
}
