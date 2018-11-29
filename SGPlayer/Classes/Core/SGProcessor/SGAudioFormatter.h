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

@interface SGAudioFormatter : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

/**
 *
 */
- (instancetype)initWithAudioDescription:(SGAudioDescription * _Nullable)audioDescription NS_DESIGNATED_INITIALIZER;

/**
 *
 */
@property (nonatomic, copy, readonly) SGAudioDescription * _Nonnull audioDescription;

/**
 *
 */
- (BOOL)format:(SGAudioFrame *)original formatted:(SGAudioFrame **)formatted;

@end
