//
//  SGFFAudioOutputRender.h
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGFFOutputRenderInternal.h"
#import "SGFFAudioFrame.h"

@interface SGFFAudioOutputRender : SGFFOutputRenderInternal

@end


@interface SGFFAudioOutputRender (Factory)

- (SGFFAudioOutputRender *)initWithAudioFrame:(SGFFAudioFrame *)audioFrame;

@end
