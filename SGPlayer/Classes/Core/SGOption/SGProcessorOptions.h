//
//  SGProcessorOptions.h
//  SGPlayer
//
//  Created by Single on 2019/8/13.
//  Copyright © 2019 single. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SGProcessorOptions : NSObject <NSCopying>

/**
 *
 */
@property (nonatomic, copy) Class audioClass;

/**
 *
 */
@property (nonatomic, copy) Class videoClass;

@end
