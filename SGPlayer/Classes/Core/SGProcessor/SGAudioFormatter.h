//
//  SGAudioFormatter.h
//  SGPlayer iOS
//
//  Created by Single on 2018/10/30.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGAudioDescription.h"
#import "SGAudioFrame.h"

NS_ASSUME_NONNULL_BEGIN

@interface SGAudioFormatter : NSObject

/**
 *
 */
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 *
 */
- (instancetype)initWithAudioDescription:(SGAudioDescription *)audioDescription NS_DESIGNATED_INITIALIZER;

/**
 *
 */
@property (nonatomic, copy, readonly) SGAudioDescription *audioDescription;

/**
 *
 */
- (SGAudioFrame * _Nullable)format:(SGAudioFrame *)frame;

/**
 *
 */
- (void)flush;

@end

NS_ASSUME_NONNULL_END
