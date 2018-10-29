//
//  SGCapacity.h
//  SGPlayer iOS
//
//  Created by Single on 2018/10/25.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGTime.h"

@interface SGCapacity : NSObject

@property (nonatomic, weak) id object;

@property (nonatomic, assign) CMTime duration;
@property (nonatomic, assign) uint64_t size;
@property (nonatomic, assign) uint64_t count;

@end
