//
//  SGFrame+Private.h
//  SGPlayer iOS
//
//  Created by Single on 2018/10/23.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGFrame.h"
#import "avformat.h"

@interface SGFrame (Private)

@property (nonatomic, assign, readonly) AVFrame * core;

- (void)configurateWithStream:(SGStream *)stream;

@end
