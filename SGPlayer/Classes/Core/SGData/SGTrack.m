//
//  SGTrack.m
//  SGPlayer
//
//  Created by Single on 2018/1/17.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGTrack.h"
#import "SGTrack+Internal.h"

@interface SGTrack ()

{
    SInt32 _index;
    SGMediaType _type;
}

@end

@implementation SGTrack

- (instancetype)init
{
    NSAssert(NO, @"Invalid Function.");
    return nil;
}

- (instancetype)initWithType:(SGMediaType)type index:(SInt32)index
{
    if (self = [super init]) {
        self->_type = type;
        self->_index = index;
    }
    return self;
}

- (SGMediaType)type
{
    return self->_type;
}

- (SInt32)index
{
    return self->_index;
}

@end
