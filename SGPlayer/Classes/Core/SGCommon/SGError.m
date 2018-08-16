//
//  SGError.m
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGError.h"
#import "avformat.h"

NSError * SGEGetError(int result)
{
    return SGEGetErrorCode(result, SGErrorCodeUnknown);
}

NSError * SGEGetErrorCode(int result, NSUInteger code)
{
    if (result < 0)
    {
        char * errorStringBuffer = malloc(256);
        av_strerror(result, errorStringBuffer, 256);
        NSString * errorString = [NSString stringWithFormat:@"FFmpeg code : %d, FFmpeg msg : %s", result, errorStringBuffer];
        NSError * error = [NSError errorWithDomain:errorString code:code userInfo:nil];
        return error;
    }
    return nil;
}

NSError * SGECreateError(NSString * domian, NSUInteger code)
{
    NSError * error = [NSError errorWithDomain:domian code:code userInfo:nil];
    return error;
}
