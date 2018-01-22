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

- (SGFFVideoFrame *)videoFrame;
- (void)updateVideoFrame:(SGFFVideoFrame *)videoFrame;

@end
