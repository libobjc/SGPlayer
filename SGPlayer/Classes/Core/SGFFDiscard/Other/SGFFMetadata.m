//
//  SGFFMetadata.m
//  SGPlayer
//
//  Created by Single on 2017/3/6.
//  Copyright © 2017年 single. All rights reserved.
//

#import "SGFFMetadata.h"

@implementation SGFFMetadata

+ (instancetype)metadataWithAVDictionary:(AVDictionary *)avDictionary
{
    return [[self alloc] initWithAVDictionary:avDictionary];
}

- (instancetype)initWithAVDictionary:(AVDictionary *)avDictionary
{
    if (self = [super init])
    {
        NSDictionary * dic = SGFFFoundationBrigeOfAVDictionary(avDictionary);
        
        self.metadata = dic;
        
        self.language = [dic objectForKey:@"language"];
        self.BPS = [[dic objectForKey:@"BPS"] longLongValue];
        self.duration = [dic objectForKey:@"DURATION"];
        self.number_of_bytes = [[dic objectForKey:@"NUMBER_OF_BYTES"] longLongValue];
        self.number_of_frames = [[dic objectForKey:@"NUMBER_OF_FRAMES"] longLongValue];
    }
    return self;
}

@end
