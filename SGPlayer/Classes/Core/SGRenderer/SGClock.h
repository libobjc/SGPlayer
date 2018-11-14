//
//  SGClock.h
//  SGPlayer
//
//  Created by Single on 2018/6/14.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface SGClock : NSObject

@property (nonatomic, assign) CMTime audio_video_offset;        // [-2, 2];

@end
