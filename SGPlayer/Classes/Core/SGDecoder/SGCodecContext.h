//
//  SGCodecContext.h
//  SGPlayer iOS
//
//  Created by Single on 2018/8/16.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGCodecDescriptor.h"
#import "SGDecoderOptions.h"
#import "SGPacket.h"
#import "SGFrame.h"

@interface SGCodecContext : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 *
 */
- (instancetype)initWithTimebase:(AVRational)timebase
                        codecpar:(AVCodecParameters *)codecpar
                      frameClass:(Class)frameClass
                  frameReuseName:(NSString *)frameReuseName;

/**
 *
 */
@property (nonatomic, strong) SGDecoderOptions *options;

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
- (NSArray<__kindof SGFrame *> *)decode:(SGPacket *)packet;

@end
