//
//  SGFrame+Internal.h
//  SGPlayer iOS
//
//  Created by Single on 2018/10/23.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGFrame.h"
#import "SGCodecDescription.h"

@interface SGFrame ()

/**
 *
 */
@property (nonatomic, assign, readonly) AVFrame * _Nonnull core;

/**
 *
 */
@property (nonatomic, copy) SGCodecDescription * _Nullable codecDescription;

/**
 *
 */
- (void)fill;

@end
