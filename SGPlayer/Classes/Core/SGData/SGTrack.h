//
//  SGTrack.h
//  SGPlayer
//
//  Created by Single on 2018/1/17.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGDefines.h"
#import "SGTime.h"

@interface SGTrack : NSObject

@property (nonatomic, assign, readonly) void * coreptr;

@property (nonatomic, assign, readonly) SGMediaType type;
@property (nonatomic, assign, readonly) int index;
@property (nonatomic, assign, readonly) int disposition;
@property (nonatomic, assign, readonly) CMTime timebase;

@end
