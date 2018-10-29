//
//  SGPacket+Internal.h
//  SGPlayer iOS
//
//  Created by Single on 2018/10/23.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGPacket.h"
#import "avcodec.h"

@interface SGPacket (Internal)

@property (nonatomic, assign, readonly) AVPacket * core;

- (void)configurateWithTrack:(SGTrack *)track;

@end
