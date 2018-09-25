//
//  SGPacketReader.m
//  SGPlayer iOS
//
//  Created by Single on 2018/9/19.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGPacketReader.h"

@implementation SGPacketReader

- (NSError *)error
{
    return nil;
}

- (CMTime)duration
{
    return kCMTimeZero;
}

- (NSDictionary *)metadata
{
    return nil;
}

- (NSArray <SGStream *> *)streams
{
    return nil;
}

- (NSArray <SGStream *> *)audioStreams
{
    return nil;
}

- (NSArray <SGStream *> *)videoStreams
{
    return nil;
}

- (NSArray <SGStream *> *)otherStreams
{
    return nil;
}

- (NSError *)open
{
    return nil;
}

- (NSError *)close
{
    return nil;
}

- (NSError *)seekable
{
    return nil;
}

- (NSError *)seekableToTime:(CMTime)time
{
    return nil;
}

- (NSError *)seekToTime:(CMTime)time
{
    return nil;
}

- (NSError *)nextPacket:(SGPacket *)packet
{
    return nil;
}

@end
