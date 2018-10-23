//
//  SGVideoAVFrame.h
//  SGPlayer
//
//  Created by Single on 2018/6/26.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGVideoFrame.h"
#import "SGPacket.h"

@interface SGVideoAVFrame : SGVideoFrame

- (void)fillWithPacket:(SGPacket *)packet;

@end
