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
- (AVFrame * _Nonnull)core;

/**
 *
 */
- (SGCodecDescription * _Nullable)codecDescription;

/**
 *
 */
- (void)setCodecDescription:(SGCodecDescription * _Nonnull)codecDescription;

/**
 *
 */
- (void)fill;

@end
