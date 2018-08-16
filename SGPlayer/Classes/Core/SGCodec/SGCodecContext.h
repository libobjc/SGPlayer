//
//  SGCodecContext.h
//  SGPlayer iOS
//
//  Created by Single on 2018/8/16.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "avcodec.h"
#import "SGFrame.h"
#import "SGFFFrame.h"
#import "SGPacket.h"

@interface SGCodecContext : NSObject

@property (nonatomic, assign) CMTime timebase;
@property (nonatomic, assign) AVCodecParameters * codecpar;
@property (nonatomic, strong) Class frameClass;

- (BOOL)open;
- (void)flush;
- (void)close;

- (NSArray <__kindof SGFrame <SGFFFrame> *> *)decode:(SGPacket *)packet;

@end
