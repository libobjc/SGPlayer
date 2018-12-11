//
//  SGAudioFrame+Internal.h
//  SGPlayer iOS
//
//  Created by Single on 2018/10/23.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGAudioFrame.h"
#import "SGFrame+Internal.h"

@interface SGAudioFrame ()

+ (instancetype)audioFrameWithDescription:(SGAudioDescription *)description numberOfSamples:(int)numberOfSamples;

@end
