//
//  SGVRViewport.h
//  SGPlayer
//
//  Created by Single on 2018/8/27.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SGVRViewport : NSObject

@property (nonatomic, assign) double degress;        // Default value is 60.
@property (nonatomic, assign) double x;              // Default value is 0, range is (-360, 360).
@property (nonatomic, assign) double y;              // Default value is 0, range is (-360, 360).
@property (nonatomic, assign) BOOL flipX;            // Default value is NO.
@property (nonatomic, assign) BOOL flipY;            // Default value is NO.
@property (nonatomic, assign) BOOL sensorEnable;     // Default value is YES.

@end
