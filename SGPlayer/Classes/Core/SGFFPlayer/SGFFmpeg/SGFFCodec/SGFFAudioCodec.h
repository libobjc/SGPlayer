//
//  SGFFAudioCodec.h
//  SGPlayer
//
//  Created by Single on 2018/1/17.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGFFCodec.h"
#import "avformat.h"

@interface SGFFAudioCodec : NSObject <SGFFCodec>

@property (nonatomic, assign) AVCodecContext * codecContext;

@end
