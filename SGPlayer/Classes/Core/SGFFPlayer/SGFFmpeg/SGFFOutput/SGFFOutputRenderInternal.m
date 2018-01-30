//
//  SGFFOutputRenderInternal.m
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFOutputRenderInternal.h"

@interface SGFFOutputRenderInternal ()

SGFFObjectPoolItemInterface

@end

@implementation SGFFOutputRenderInternal

- (SGFFOutputRenderType)type
{
    return SGFFOutputRenderTypeUnkonwn;
}

- (SGFFTimebase)timebase {return SGFFTimebaseIdentity();}
- (long long)position {return 0;}
- (long long)duration {return 0;}
- (long long)size {return 0;}

SGFFObjectPoolItemLockingImplementation

- (void)clear {}

@end
