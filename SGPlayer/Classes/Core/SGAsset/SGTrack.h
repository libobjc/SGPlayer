//
//  SGTrack.h
//  SGPlayer
//
//  Created by Single on 2018/1/17.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGDefines.h"

NS_ASSUME_NONNULL_BEGIN

@interface SGTrack : NSObject <NSCopying>

/**
 *
 */
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 *
 */
@property (nonatomic, readonly) SGMediaType type;

/**
 *
 */
@property (nonatomic, readonly) NSInteger index;

@end

NS_ASSUME_NONNULL_END
