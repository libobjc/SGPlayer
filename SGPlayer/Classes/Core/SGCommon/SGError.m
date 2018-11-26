//
//  SGError.m
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGError.h"
#import "error.h"

static NSString * const SGErrorUserInfoKeyOperation = @"SGErrorUserInfoKeyOperation";

NSError * SGEGetError(int result, SGOperationCode operation)
{
    if (result >= 0) {
        return nil;
    }
    char *data = malloc(256);
    av_strerror(result, data, 256);
    NSString *domain = [NSString stringWithFormat:@"SGPlayer-Error-FFmpeg code : %d, msg : %s", result, data];
    free(data);
    return [NSError errorWithDomain:domain code:result userInfo:@{SGErrorUserInfoKeyOperation : @(operation)}];
}

NSError * SGECreateError(int code, SGOperationCode operation)
{
    return [NSError errorWithDomain:@"SGPlayer-Error-SGErrorCode" code:(NSInteger)code userInfo:@{SGErrorUserInfoKeyOperation : @(operation)}];
}
