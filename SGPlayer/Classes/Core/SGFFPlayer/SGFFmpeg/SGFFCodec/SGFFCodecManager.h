//
//  SGFFCodecManager.h
//  SGPlayer
//
//  Created by Single on 2018/1/16.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGFFCodec.h"
#import "avformat.h"

@interface SGFFCodecManager : NSObject

- (id <SGFFCodec>)codecForStream:(AVStream *)stream;

@end
