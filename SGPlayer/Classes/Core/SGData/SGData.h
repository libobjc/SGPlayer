//
//  SGDemuxable.h
//  SGPlayer iOS
//
//  Created by Single on 2018/9/25.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

/**
 *
 */
typedef NS_OPTIONS(NSUInteger, SGDataFlags) {
    SGDataFlagPadding = 1 << 0,
};

@protocol SGData <NSObject>

/**
 *
 */
@property (nonatomic) SGDataFlags flags;

/**
 *
 */
@property (nonatomic, copy) NSString *reuseName;

/**
 *
 */
- (void)lock;

/**
 *
 */
- (void)unlock;

/**
 *
 */
- (void)clear;

/**
 *
 */
- (CMTime)duration;

/**
 *
 */
- (CMTime)timeStamp;

/**
 *
 */
- (int)size;

@end
