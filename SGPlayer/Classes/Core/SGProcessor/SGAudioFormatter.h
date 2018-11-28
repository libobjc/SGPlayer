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

/**
 *
 */
@property (nonatomic, strong) SGAudioDescription * _Nonnull audioDescription;

/**
 *
 */
- (void)close;

/**
 *
 */
- (void)flush;

/**
 *
 */
- (BOOL)format:(SGAudioFrame *)original formatted:(SGAudioFrame **)formatted;

@end
