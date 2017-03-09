//
//  SGFingerRotation.h
//  SGPlayer
//
//  Created by Single on 17/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import <GLKit/GLKit.h>

@interface SGFingerRotation : NSObject

+ (instancetype)fingerRotation;

+ (CGFloat)degress;

@property (nonatomic, assign) CGFloat x;
@property (nonatomic, assign) CGFloat y;

- (void)clean;

@end
