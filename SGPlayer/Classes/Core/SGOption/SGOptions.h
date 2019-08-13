//
//  SGOptions.h
//  SGPlayer iOS
//
//  Created by Single on 2018/10/29.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGProcessorOptions.h"
#import "SGRendererOptions.h"
#import "SGDecoderOptions.h"
#import "SGDemuxerOptions.h"

@interface SGOptions : NSObject <NSCopying>

/**
 *
 */
+ (instancetype)sharedOptions;

/**
 *
 */
@property (nonatomic, strong) SGDemuxerOptions *demuxer;

/**
 *
 */
@property (nonatomic, strong) SGDecoderOptions *decoder;

/**
 *
 */
@property (nonatomic, strong) SGProcessorOptions *processor;

/**
 *
 */
@property (nonatomic, strong) SGRendererOptions *renderer;

@end
