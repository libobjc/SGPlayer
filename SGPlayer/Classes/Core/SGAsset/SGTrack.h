//
//  SGTrack.h
//  SGPlayer
//
//  Created by Single on 2018/1/17.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGDefines.h"

@interface SGTrack : NSObject <NSCopying>

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/*!
 @property type
 @abstract
    Indicates the track media type.
 */
@property (nonatomic, readonly) SGMediaType type;

/*!
 @property type
 @abstract
    Indicates the track index.
 */
@property (nonatomic, readonly) NSInteger index;

@end
