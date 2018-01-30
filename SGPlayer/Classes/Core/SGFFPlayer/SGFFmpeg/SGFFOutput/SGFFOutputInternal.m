//
//  SGFFOutputInternal.m
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFOutputInternal.h"

@implementation SGFFOutputInternal

@synthesize renderDelegate = _renderDelegate;
@synthesize renderSource = _renderSource;

- (id <SGFFOutputRender>)renderWithFrame:(id <SGFFFrame>)frame {return nil;}
- (SGFFTime)currentTime {return SGFFTimeIdentity();}
- (void)play {};
- (void)pause {};

@end
