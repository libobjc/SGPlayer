//
//  SGMutableTrack.h
//  SGPlayer
//
//  Created by Single on 2018/11/29.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGSegment.h"
#import "SGTrack.h"

@interface SGMutableTrack : SGTrack

/**
 *
 */
@property (nonatomic, copy, readonly) NSArray<SGSegment *> *segments;

/**
 *
 */
- (BOOL)appendSegment:(SGSegment *)segment;

@end
