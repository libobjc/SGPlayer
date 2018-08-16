//
//  SGFrame.h
//  SGPlayer
//
//  Created by Single on 2018/1/18.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGDefines.h"
#import "SGObjectPool.h"
#import "SGObjectQueue.h"

@interface SGFrame : NSObject <SGObjectPoolItem, SGObjectQueueItem>

@property (nonatomic, assign, readonly) SGMediaType mediaType;

@property (nonatomic, assign) CMTime timebase;
@property (nonatomic, assign) CMTime offset;
@property (nonatomic, assign) CMTime scale;
@property (nonatomic, assign) CMTime timeStamp;
@property (nonatomic, assign) CMTime duration;
@property (nonatomic, assign) CMTime originalTimeStamp;
@property (nonatomic, assign) CMTime originalDuration;
@property (nonatomic, assign) CMTime decodeTimeStamp;
@property (nonatomic, assign) long long size;

@end
