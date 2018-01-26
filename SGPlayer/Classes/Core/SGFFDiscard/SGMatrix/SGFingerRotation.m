//
//  SGFingerRotation.m
//  SGPlayer
//
//  Created by Single on 17/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import "SGFingerRotation.h"

@implementation SGFingerRotation

+ (instancetype)fingerRotation
{
    return [[self alloc] init];
}

+ (CGFloat)degress
{
    return 60.0;
}

- (void)clean
{
    self.x = 0;
    self.y = 0;
}

@end
