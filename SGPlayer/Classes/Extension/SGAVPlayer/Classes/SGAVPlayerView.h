//
//  SGAVPlayerView.h
//  SGAVPlayer iOS
//
//  Created by Single on 2018/1/9.
//  Copyright © 2018年 single. All rights reserved.
//

#import "SGPLFView.h"
#import <AVFoundation/AVFoundation.h>

@interface SGAVPlayerView : SGPLFView

@property (nonatomic, strong, readonly) AVPlayerLayer * playerLayer;

@end
