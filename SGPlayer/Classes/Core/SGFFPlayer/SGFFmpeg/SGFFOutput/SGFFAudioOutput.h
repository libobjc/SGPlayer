//
//  SGFFAudioOutput.h
//  SGPlayer
//
//  Created by Single on 2018/1/19.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGFFOutput.h"

@interface SGFFAudioOutput : NSObject <SGFFOutput>

- (void)play;
- (void)pause;

@end
