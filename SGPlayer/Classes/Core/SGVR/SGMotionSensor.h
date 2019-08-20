//
//  SGMotionSensor.h
//  SGPlayer iOS
//
//  Created by Single on 2018/8/23.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface SGMotionSensor : NSObject

@property (nonatomic, readonly) BOOL ready;
@property (nonatomic, readonly) GLKMatrix4 matrix;

- (void)start;
- (void)stop;

@end
