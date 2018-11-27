//
//  SGCodecContext.h
//  SGPlayer iOS
//
//  Created by Single on 2018/8/16.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGCodecDescription.h"
#import "SGPacket.h"
#import "SGFrame.h"

@interface SGCodecContext : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 *
 */
- (instancetype)initWithTimebase:(AVRational)timebase
                        codecpar:(AVCodecParameters * _Nonnull)codecpar
                      frameClass:(Class _Nonnull)frameClass NS_DESIGNATED_INITIALIZER;

/**
 *
 */
@property (nonatomic, copy) NSDictionary * _Nullable options;

/**
 *
 */
@property (nonatomic) BOOL threadsAuto;

/**
 *
 */
@property (nonatomic) BOOL refcountedFrames;

/**
 *
 */
@property (nonatomic) BOOL hardwareDecodeH264;

/**
 *
 */
@property (nonatomic) BOOL hardwareDecodeH265;

/**
 *
 */
@property (nonatomic) OSType preferredPixelFormat;

/**
 *
 */
- (BOOL)open;

/**
 *
 */
- (void)close;

/**
 *
 */
- (void)flush;

/**
 *
 */
- (NSArray<__kindof SGFrame *> * _Nullable)decode:(SGPacket * _Nonnull)packet;

@end
