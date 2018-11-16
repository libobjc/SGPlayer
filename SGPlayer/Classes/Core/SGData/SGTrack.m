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

@property (nonatomic) SGMediaType type;
@property (nonatomic) int32_t index;

@end

@implementation SGTrack

- (instancetype)initWithType:(SGMediaType)type index:(int32_t)index
{
    if (self = [super init]) {
        self.type = type;
        self.index = self.index;
    }
    return self;
}

@end
