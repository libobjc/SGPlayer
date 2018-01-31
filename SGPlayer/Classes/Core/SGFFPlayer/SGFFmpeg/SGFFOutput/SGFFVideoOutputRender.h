//
//  SGFFVideoOutputRender.h
//  SGPlayer
//
//  Created by Single on 2018/1/21.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGFFOutputRender.h"
#import "SGFFVideoFrame.h"

@interface SGFFVideoOutputRender : NSObject <SGFFOutputRender>

@property (nonatomic, assign) SGFFTimebase timebase;
@property (nonatomic, assign) long long position;
@property (nonatomic, assign) long long duration;
@property (nonatomic, assign) long long size;

- (SGFFVideoFrame *)coreVideoFrame;
- (void)updateCoreVideoFrame:(SGFFVideoFrame *)coreVideoFrame;

@end
