//
//  SGSegment.h
//  SGPlayer
//
//  Created by Single on 2018/11/14.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface SGSegment : NSObject <NSCopying>

- (instancetype)initWithTimeRange:(CMTimeRange)timeRange scale:(CMTime)scale;

@property (nonatomic) CMTimeRange timeRange;
@property (nonatomic) CMTime scale;

@end
