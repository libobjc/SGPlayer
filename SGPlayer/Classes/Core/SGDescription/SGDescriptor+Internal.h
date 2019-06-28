//
//  SGPacket+Internal.h
//  SGPlayer iOS
//
//  Created by Single on 2018/10/23.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGPacket.h"
#import "SGFFmpeg.h"
#import "SGAudioDescriptor.h"
#import "SGVideoDescriptor.h"

@interface SGAudioDescriptor ()

- (instancetype)initWithFrame:(AVFrame *)frame;

@end

@interface SGVideoDescriptor ()

- (instancetype)initWithFrame:(AVFrame *)frame;

@end
