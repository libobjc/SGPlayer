//
//  SGFFStream.h
//  SGPlayer
//
//  Created by Single on 2018/1/17.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGFFCodec.h"
#import "avformat.h"

@interface SGFFStream : NSObject

@property (nonatomic, assign) NSInteger index;
@property (nonatomic, assign) AVStream * stream;
@property (nonatomic, strong) id <SGFFCodec> codec;

- (BOOL)open;
- (void)close;
- (void)putPacket:(AVPacket)packet;

@end
