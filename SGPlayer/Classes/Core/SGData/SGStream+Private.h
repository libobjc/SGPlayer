//
//  SGStream+Private.h
//  SGPlayer iOS
//
//  Created by Single on 2018/10/23.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGStream.h"
#import "avformat.h"

@interface SGStream (Private)

- (instancetype)initWithCore:(AVStream *)core;

@property (nonatomic, assign, readonly) AVStream * core;

@end
