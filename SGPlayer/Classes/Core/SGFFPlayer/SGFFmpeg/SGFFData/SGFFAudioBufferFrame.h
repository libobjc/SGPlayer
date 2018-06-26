//
//  SGFFAudioBufferFrame.h
//  SGPlayer
//
//  Created by Single on 2018/6/26.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGFFAudioFrame.h"

@interface SGFFAudioBufferFrame : SGFFAudioFrame

- (void)updateData:(void **)data linesize:(int *)linesize;

@end
