//
//  SGURLAsset.m
//  SGPlayer iOS
//
//  Created by Single on 2018/9/19.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGURLAsset.h"
#import "SGURLPacketReader.h"

@interface SGURLAsset ()

@property (nonatomic, copy) NSURL * URL;
@property (nonatomic, strong) SGURLPacketReader * reader;

@end

@implementation SGURLAsset

- (instancetype)initWithURL:(NSURL *)URL
{
    if (self = [super init])
    {
        self.URL = URL;
        self.reader = [[SGURLPacketReader alloc] initWithURL:self.URL];
    }
    return self;
}

- (NSError *)error
{
    [self openIfNeeded];
    return self.reader.error;
}

- (CMTime)duration
{
    [self openIfNeeded];
    return self.reader.duration;
}

- (NSDictionary *)metadata
{
    [self openIfNeeded];
    return self.reader.metadata;
}

- (void)openIfNeeded
{
    [self.reader open];
}

@end
