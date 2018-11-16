//
//  SGTrack.h
//  SGPlayer
//
//  Created by Single on 2018/1/17.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGDefines.h"

@interface SGTrack : NSObject

@property (nonatomic, readonly) SGMediaType type;
@property (nonatomic, readonly) int32_t index;

@end
