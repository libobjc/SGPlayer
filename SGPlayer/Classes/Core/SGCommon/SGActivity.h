//
//  SGPlayerActivity.h
//  SGPlayer
//
//  Created by Single on 2018/1/10.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SGActivity : NSObject

/**
 *
 */
+ (void)addTarget:(id)target;

/**
 *
 */
+ (void)removeTarget:(id)target;

@end

NS_ASSUME_NONNULL_END
