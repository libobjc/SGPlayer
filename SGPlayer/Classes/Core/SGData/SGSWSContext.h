//
//  SGSWSContext.h
//  SGPlayer iOS
//
//  Created by Single on 2018/8/28.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SGSWSContext : NSObject

@property (nonatomic, assign) int src_format;       // AVPixelFormat
@property (nonatomic, assign) int dst_format;       // AVPixelFormat
@property (nonatomic, assign) int width;
@property (nonatomic, assign) int height;
@property (nonatomic, assign) int flags;            // SWS_FAST_BILINEAR

- (BOOL)open;

- (int)scaleWithSrcData:(const uint8_t * const [])src_data
            srcLinesize:(const int [])src_linesize
                dstData:(uint8_t * const [])dst_data
            dstLinesize:(const int [])dst_linesize;

@end
