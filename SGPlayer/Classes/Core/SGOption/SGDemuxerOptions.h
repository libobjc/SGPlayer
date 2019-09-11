//
//  SGDemuxerOptions.h
//  SGPlayer
//
//  Created by Single on 2019/6/14.
//  Copyright © 2019 single. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SGDemuxerOptions : NSObject <NSCopying>

/*!
 @property options
 @abstract
    The options for avformat_open_input.
    Default:
        @{@"reconnect" : @(1),
          @"user-agent" : @"SGPlayer",
          @"timeout" : @(20 * 1000 * 1000)}
 */
@property (nonatomic, copy) NSDictionary *options;

@end
