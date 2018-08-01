//
//  SGFFAudioFFFrame.h
//  SGPlayer
//
//  Created by Single on 2018/6/26.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGAudioFrame.h"

@interface SGFFAudioFFFrame : SGAudioFrame

@property (nonatomic, assign, readonly) AVFrame * coreFrame;

- (void)fillWithTimebase:(CMTime)timebase packet:(SGPacket *)packet;

@end
