//
//  SGCodecContext.h
//  SGPlayer iOS
//
//  Created by Single on 2018/8/16.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGPacket.h"
#import "SGFrame.h"

@interface SGCodecContext : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithStream:(SGStream *)stream frameClass:(Class)frameClass;

@property (nonatomic, strong) NSDictionary * options;
@property (nonatomic, assign) BOOL threadsAuto;
@property (nonatomic, assign) BOOL refcountedFrames;
@property (nonatomic, assign) BOOL hardwareDecodeH264;
@property (nonatomic, assign) BOOL hardwareDecodeH265;
@property (nonatomic, assign) enum AVPixelFormat preferredPixelFormat;

- (BOOL)open;
- (void)close;

- (NSArray <__kindof SGFrame *> *)decode:(SGPacket *)packet;
- (void)flush;

@end
