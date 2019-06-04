//
//  SGSWResample.h
//  SGPlayer iOS
//
//  Created by Single on 2018/10/30.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGAudioDescription.h"

@interface SGSWResample : NSObject

/**
 *
 */
@property (nonatomic, copy) SGAudioDescription *inputDescription;
@property (nonatomic, copy) SGAudioDescription *outputDescription;

/**
 *
 */
- (BOOL)open;

/**
 *
 */
- (int)write:(uint8_t **)data nb_samples:(int)nb_samples;

/**
 *
 */
- (int)read:(uint8_t **)data nb_samples:(int)nb_samples;

@end
