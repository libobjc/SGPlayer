//
//  SGVideoFFFrame.h
//  SGPlayer
//
//  Created by Single on 2018/6/26.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGVideoFrame.h"

@interface SGVideoFFFrame : SGVideoFrame

@property (nonatomic, assign, readonly) AVFrame * coreFrame;

- (void)fillWithPacket:(SGPacket *)packet;

@end
