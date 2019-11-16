//
//  SGSWScale.h
//  SGPlayer iOS
//
//  Created by Single on 2018/8/28.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGVideoDescriptor.h"

@interface SGSWScale : NSObject

/**
 *
 */
+ (BOOL)isSupportedInputFormat:(int)format;

/**
 *
 */
+ (BOOL)isSupportedOutputFormat:(int)format;

/**
 *
 */
@property (nonatomic, copy) SGVideoDescriptor *inputDescriptor;

/**
 *
 */
@property (nonatomic, copy) SGVideoDescriptor *outputDescriptor;

/**
 *
 */
@property (nonatomic) int flags;          // SWS_FAST_BILINEAR

/**
 *
 */
- (BOOL)open;

/**
 *
 */
- (int)convert:(const uint8_t * const [])inputData inputLinesize:(const int[])inputLinesize outputData:(uint8_t * const [])outputData outputLinesize:(const int[])outputLinesize;

@end
