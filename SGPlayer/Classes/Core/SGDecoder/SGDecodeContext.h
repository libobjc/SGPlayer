//
//  SGDecodeContext.h
//  KTVMediaKitDemo
//
//  Created by Single on 2019/11/18.
//  Copyright © 2019 Single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGDecoderOptions.h"
#import "SGCapacity.h"
#import "SGPacket.h"
#import "SGFrame.h"

@interface SGDecodeContext : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 *
 */
- (instancetype)initWithDecoderClass:(Class)decoderClass;

/**
 *
 */
@property (nonatomic, copy) SGDecoderOptions *options;

/**
 *
 */
@property (nonatomic, readonly) CMTime decodeTimeStamp;

/**
 *
 */
- (SGCapacity)capacity;

/**
 *
 */
- (void)putPacket:(SGPacket *)packet;

/**
 *
 */
- (BOOL)needsPredecode;

/**
 *
 */
- (void)predecode:(SGBlock)lock unlock:(SGBlock)unlock;

/**
 *
 */
- (NSArray<__kindof SGFrame *> *)decode:(SGBlock)lock unlock:(SGBlock)unlock;

/**
 *
 */
- (void)setNeedsFlush;

/**
 *
 */
- (void)markAsFinished;

/**
 *
 */
- (void)destory;

@end

