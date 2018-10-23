//
//  SGPacket+Private.h
//  SGPlayer iOS
//
//  Created by Single on 2018/10/23.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGPacket.h"
#import "avformat.h"

@interface SGPacket (Private)

@property (nonatomic, assign, readonly) AVPacket * core;

@property (nonatomic, strong) SGStream * stream;

@end
