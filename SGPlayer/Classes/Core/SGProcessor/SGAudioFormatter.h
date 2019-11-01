//
//  SGAudioFormatter.h
//  SGPlayer iOS
//
//  Created by Single on 2018/10/30.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGAudioDescriptor.h"
#import "SGAudioFrame.h"

@interface SGAudioFormatter : NSObject

/**
 *
 */
@property (nonatomic, copy) SGAudioDescriptor *descriptor;

/**
 *
 */
- (SGAudioFrame *)format:(SGAudioFrame *)frame;

/**
 *
 */
- (SGAudioFrame *)finish;

/**
 *
 */
- (void)flush;

@end
