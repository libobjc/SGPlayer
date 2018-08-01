//
//  SGFrame.h
//  SGPlayer
//
//  Created by Single on 2018/1/18.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGDefines.h"
#import "SGPacket.h"
#import "SGObjectPool.h"
#import "SGObjectQueue.h"

@interface SGFrame : NSObject <SGObjectPoolItem, SGObjectQueueItem>

- (SGMediaType)mediaType;

@property (nonatomic, assign) CMTime position;
@property (nonatomic, assign) CMTime duration;
@property (nonatomic, assign) long long size;

@end
