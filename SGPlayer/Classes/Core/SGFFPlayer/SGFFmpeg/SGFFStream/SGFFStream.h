//
//  SGFFStream.h
//  SGPlayer
//
//  Created by Single on 2018/1/17.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGFFCodec.h"
#import "SGFFPacket.h"

@interface SGFFStream : NSObject

@property (nonatomic, assign) AVStream * coreStream;
@property (nonatomic, strong) id <SGFFCodec> codec;

- (BOOL)open;
- (void)flush;
- (void)close;

- (BOOL)putPacket:(SGFFPacket *)packet;

@end
