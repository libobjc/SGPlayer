//
//  SGCodecDescription.h
//  SGPlayer
//
//  Created by Single on 2018/11/15.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGTimeLayout.h"
#import "SGFFmpeg.h"
#import "SGTrack.h"

@interface SGCodecDescription : NSObject <NSCopying>

/**
 *
 */
@property (nonatomic, strong) SGTrack * _Nullable track;

/**
 *
 */
@property (nonatomic) AVRational timebase;

/**
 *
 */
@property (nonatomic) AVCodecParameters * _Nullable codecpar;

/**
 *
 */
@property (nonatomic, readonly) CMTimeRange timeRange;

/**
 *
 */
@property (nonatomic, readonly) CMTime scale;

/**
 *
 */
@property (nonatomic, copy, readonly) NSArray<SGTimeLayout *> * _Nullable timeLayouts;

/**
 *
 */
- (void)appendTimeRange:(CMTimeRange)timeRange;

/**
 *
 */
- (void)appendTimeLayout:(SGTimeLayout * _Nonnull)timeLayout;

/**
 *
 */
- (void)fillToDescription:(SGCodecDescription * _Nonnull)description;

/**
 *
 */
- (BOOL)isEqualToDescription:(SGCodecDescription * _Nonnull)description;

/**
 *
 */
- (BOOL)isEqualCodecparToDescription:(SGCodecDescription * _Nonnull)description;

@end
