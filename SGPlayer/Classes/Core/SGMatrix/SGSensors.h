//
//  SGSensors.h
//  SGPlayer
//
//  Created by Single on 16/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import <GLKit/GLKit.h>

@interface SGSensors : NSObject

@property (nonatomic, assign, readonly, getter=isReady) BOOL ready;

- (void)start;
- (void)stop;

- (GLKMatrix4)modelView;

@end
