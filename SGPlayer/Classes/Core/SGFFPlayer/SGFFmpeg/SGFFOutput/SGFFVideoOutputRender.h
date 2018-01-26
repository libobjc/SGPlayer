//
//  SGFFVideoOutputRender.h
//  SGPlayer
//
//  Created by Single on 2018/1/21.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFOutputRenderInternal.h"
#import "SGFFVideoFrame.h"

@interface SGFFVideoOutputRender : SGFFOutputRenderInternal

@property (nonatomic, assign) long long position;
@property (nonatomic, assign) long long duration;
@property (nonatomic, assign) long long size;

- (SGFFVideoFrame *)videoFrame;
- (void)updateVideoFrame:(SGFFVideoFrame *)videoFrame;

@end
