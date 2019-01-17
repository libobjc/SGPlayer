//
//  SGVideoDescription.h
//  SGPlayer
//
//  Created by Single on 2018/12/11.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SGVideoDescription : NSObject <NSCopying>

/**
 *  AVPixelFormat
 */
@property (nonatomic) int format;

/**
 *
 */
@property (nonatomic) int width;

/**
 *
 */
@property (nonatomic) int height;

/**
 *
 */
- (BOOL)isEqualToDescription:(SGVideoDescription *)description;

@end

NS_ASSUME_NONNULL_END
