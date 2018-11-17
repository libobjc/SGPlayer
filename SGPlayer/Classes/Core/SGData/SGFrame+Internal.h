//
//  SGFrame+Internal.h
//  SGPlayer iOS
//
//  Created by Single on 2018/10/23.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGFrame.h"
#import "SGTimeLayout.h"
#import "frame.h"

@interface SGFrame (Internal)

@property (nonatomic, readonly) AVFrame * core;

- (void)setTimebase:(AVRational)timebase;
- (void)setTimeLayout:(SGTimeLayout *)timeLayout;
- (void)setFrame:(SGFrame *)frame;

@end
