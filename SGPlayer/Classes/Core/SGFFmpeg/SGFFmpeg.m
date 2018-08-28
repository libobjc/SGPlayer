//
//  SGFFmpeg.m
//  SGPlayer
//
//  Created by Single on 2018/8/2.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGFFmpeg.h"

void SGFFmpegLogCallback(void * context, int level, const char * format, va_list args)
{
//    NSString * message = [[NSString alloc] initWithFormat:[NSString stringWithUTF8String:format] arguments:args];
//    NSLog(@"SGFFLog : %@", message);
}

void SGFFmpegSetupIfNeeded(void)
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        av_log_set_callback(SGFFmpegLogCallback);
        avformat_network_init();
    });
}

AVDictionary * SGDictionaryNS2FF(NSDictionary * dictionary)
{
    __block AVDictionary * ret = NULL;
    [dictionary enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[NSNumber class]])
        {
            av_dict_set_int(&ret, [key UTF8String], [obj integerValue], 0);
        }
        else if ([obj isKindOfClass:[NSString class]])
        {
            av_dict_set(&ret, [key UTF8String], [obj UTF8String], 0);
        }
    }];
    return ret;
}

NSDictionary * SGDictionaryFF2NS(AVDictionary * dictionary)
{
    NSMutableDictionary * ret = [NSMutableDictionary dictionary];
    AVDictionaryEntry * entry = NULL;
    while ((entry = av_dict_get(dictionary, "", entry, AV_DICT_IGNORE_SUFFIX)))
    {
        NSString * key = [NSString stringWithUTF8String:entry->key];
        NSString * value = [NSString stringWithUTF8String:entry->value];
        [ret setObject:value forKey:key];
    }
    if (ret.count <= 0)
    {
        ret = nil;
    }
    return [ret copy];
}
