//
//  SGTrack+Internal.h
//  SGPlayer iOS
//
//  Created by Single on 2018/10/23.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGTrack.h"
#import "avformat.h"

@interface SGTrack (Internal)

- (instancetype)initWithCore:(AVStream *)core;

@property (nonatomic, assign, readonly) AVStream * core;

@end
