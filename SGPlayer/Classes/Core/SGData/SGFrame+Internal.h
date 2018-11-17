//
//  SGFrame+Internal.h
//  SGPlayer iOS
//
//  Created by Single on 2018/10/23.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGFrame.h"
#import "SGCodecDescription.h"

@interface SGFrame (Internal)

@property (nonatomic, readonly) AVFrame * core;
@property (nonatomic, copy) SGCodecDescription * codecDescription;

- (void)fill;

@end
