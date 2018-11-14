//
//  SGURLDemuxer.h
//  SGPlayer iOS
//
//  Created by Single on 2018/8/13.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGDemuxable.h"

@interface SGURLDemuxer : NSObject <SGDemuxable>

- (instancetype)initWithURL:(NSURL *)URL;

@end
