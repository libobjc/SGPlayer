//
//  SGCodecContext.h
//  SGPlayer iOS
//
//  Created by Single on 2018/8/16.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGCodecpar.h"
#import "SGPacket.h"
#import "SGFrame.h"

@interface SGCodecContext : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithCodecpar:(SGCodecpar *)codecpar frameClass:(Class)frameClass;

@property (nonatomic, strong) NSDictionary * options;
@property (nonatomic) BOOL threadsAuto;
@property (nonatomic) BOOL refcountedFrames;
@property (nonatomic) BOOL hardwareDecodeH264;
@property (nonatomic) BOOL hardwareDecodeH265;
@property (nonatomic) OSType preferredPixelFormat;

- (BOOL)open;
- (void)close;
- (void)flush;
- (NSArray <__kindof SGFrame *> *)decode:(SGPacket *)packet;

@end
