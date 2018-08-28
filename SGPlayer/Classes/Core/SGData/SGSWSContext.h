//
//  SGSWSContext.h
//  SGPlayer iOS
//
//  Created by Single on 2018/8/28.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGFFDefines.h"

@interface SGSWSContext : NSObject

@property (nonatomic, assign) SGAVPixelFormat srcFormat;
@property (nonatomic, assign) SGAVPixelFormat dstFormat;
@property (nonatomic, assign) int width;
@property (nonatomic, assign) int height;
@property (nonatomic, assign) int flags;        // SWS_FAST_BILINEAR

- (BOOL)open;

- (int)scaleWithSrcData:(const uint8_t * const [])srcData
            srcLinesize:(const int [])srcLinesize
                dstData:(uint8_t * const [])dstData
            dstLinesize:(const int [])dstLinesize;

@end
