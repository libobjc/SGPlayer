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

- (int)scaleWithSrc_data:(const uint8_t * const [])src_data
            src_linesize:(const int [])src_linesize
                dst_data:(uint8_t * const [])dst_data
            dst_linesize:(const int [])dst_linesize;

@end
