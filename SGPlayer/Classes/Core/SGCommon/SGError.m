//
//  SGError.m
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGError.h"
#import "avformat.h"

NSError * SGFFGetError(int result)
{
    return SGFFGetErrorCode(result, SGErrorCodeUnknown);
}

NSError * SGFFGetErrorCode(int result, NSUInteger errorCode)
{
    if (result < 0)
    {
        char * errorStringBuffer = malloc(256);
        av_strerror(result, errorStringBuffer, 256);
        NSString * errorString = [NSString stringWithFormat:@"FFmpeg code : %d, FFmpeg msg : %s", result, errorStringBuffer];
        NSError * error = [NSError errorWithDomain:errorString code:errorCode userInfo:nil];
        return error;
    }
    return nil;
}

NSError * SGFFCreateErrorCode(NSUInteger errorCode)
{
    NSError * error = [NSError errorWithDomain:@"SGFFCreateErrorCode" code:errorCode userInfo:nil];
    return error;
}
