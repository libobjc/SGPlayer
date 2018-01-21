//
//  SGFFFrameFactory.h
//  SGPlayer
//
//  Created by Single on 2018/1/21.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGFFAudioFrame.h"
#import "avformat.h"


@interface SGFFAudioFrame (Factory)

- (SGFFAudioFrame *)initWithAVFrame:(AVFrame *)frame timebase:(SGFFTimebase)timebase;

@end
