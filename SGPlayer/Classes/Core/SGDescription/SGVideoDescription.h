//
//  SGVideoDescription.h
//  SGPlayer
//
//  Created by Single on 2018/12/11.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>

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
