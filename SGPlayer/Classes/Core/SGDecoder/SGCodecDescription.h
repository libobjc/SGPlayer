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
@property (nonatomic) CMTimeRange timeRange;

/**
 *
 */
@property (nonatomic) AVCodecParameters * _Nullable codecpar;

/**
 *
 */
@property (nonatomic, copy) NSArray<SGTimeLayout *> * _Nullable timeLayouts;

/**
 *
 */
- (BOOL)isEqualToDescription:(SGCodecDescription * _Nonnull)codecpar;

/**
 *
 */
- (void)appendTimeLayout:(SGTimeLayout * _Nonnull)timeLayout;

/**
 *
 */
- (void)appendTimeRange:(CMTimeRange)timeRange;

/**
 *
 */
- (CMTimeRange)finalTimeRange;

@end
