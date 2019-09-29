//
//  SGVRProjection.h
//  SGPlayer iOS
//
//  Created by Single on 2018/8/23.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>

#if TARGET_OS_MACCATALYST
#import "Catalyst.h"
#else
#import <GLKit/GLKit.h>
#endif


#import "SGVRViewport.h"

@interface SGVRProjection : NSObject

@property (nonatomic, strong) SGVRViewport * viewport;

- (BOOL)ready;
- (BOOL)matrixWithAspect:(Float64)aspect matrix1:(GLKMatrix4 *)matrix1;
- (BOOL)matrixWithAspect:(Float64)aspect matrix1:(GLKMatrix4 *)matrix1 matrix2:(GLKMatrix4 *)matrix2;
@end
