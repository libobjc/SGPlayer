//
//  SGURLDemuxerFunnel.m
//  SGPlayer
//
//  Created by Single on 2018/11/14.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGURLDemuxerFunnel.h"
#import "SGURLDemuxer.h"

@interface SGURLDemuxerFunnel ()

@property (nonatomic, strong) SGURLDemuxer * demuxer;

@end

@implementation SGURLDemuxerFunnel

- (instancetype)initWithURL:(NSURL *)URL
{
    if (self = [super init]) {
        self.demuxer = [[SGURLDemuxer alloc] initWithURL:URL];
    }
    return self;
}

@end
