//
//  SGSensor.h
//  SGPlayer iOS
//
//  Created by Single on 2018/8/23.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface SGSensor : NSObject

@property (nonatomic, assign, readonly) BOOL ready;
@property (nonatomic, assign, readonly) GLKMatrix4 matrix;

- (void)start;
- (void)stop;

@end
