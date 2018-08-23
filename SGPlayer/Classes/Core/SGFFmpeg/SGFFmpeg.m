//
//  SGFFmpeg.m
//  SGPlayer
//
//  Created by Single on 2018/8/2.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGFFmpeg.h"
#import "avformat.h"

void SGFFLogCallback(void * context, int level, const char * format, va_list args)
{
//    NSString * message = [[NSString alloc] initWithFormat:[NSString stringWithUTF8String:format] arguments:args];
//    NSLog(@"SGFFLog : %@", message);
}

@implementation SGFFmpeg

+ (void)setupIfNeeded
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        av_log_set_callback(SGFFLogCallback);
        avformat_network_init();
    });
}

@end
