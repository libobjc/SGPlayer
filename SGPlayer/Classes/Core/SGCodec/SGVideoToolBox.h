//
//  SGVideoToolBox.h
//  SGPlayer iOS
//
//  Created by Single on 2018/8/16.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGPacket.h"
#import "SGFrame.h"
#import "avcodec.h"

@interface SGVideoToolBox : NSObject

@property (nonatomic, assign) CMTime timebase;
@property (nonatomic, assign) AVCodecParameters * codecpar;
@property (nonatomic, assign) OSType preferredPixelFormat;

- (BOOL)open;
- (void)flush;
- (void)close;

- (NSArray <__kindof SGFrame *> *)decode:(SGPacket *)packet;

@end
