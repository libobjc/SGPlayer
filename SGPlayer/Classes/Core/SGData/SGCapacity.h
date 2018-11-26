//
//  SGCapacity.h
//  SGPlayer iOS
//
//  Created by Single on 2018/10/25.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGTime.h"

@interface SGCapacity : NSObject <NSCopying>

/**
 *
 */
@property (nonatomic) int size;

/**
 *
 */
@property (nonatomic) int count;

/**
 *
 */
@property (nonatomic) CMTime duration;

/**
 *
 */
- (SGCapacity *)minimum:(SGCapacity *)capacity;

/**
 *
 */
- (void)add:(SGCapacity *)capacity;

/**
 *
 */
- (BOOL)isEqualToCapacity:(SGCapacity *)capacity;

/**
 *
 */
- (BOOL)isEnough;

/**
 *
 */
- (BOOL)isEmpty;

@end
