//
//  SGSWScale.h
//  SGPlayer iOS
//
//  Created by Single on 2018/8/28.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SGSWScale : NSObject

@property (nonatomic) int i_format;       // AVPixelFormat
@property (nonatomic) int o_format;       // AVPixelFormat
@property (nonatomic) int width;
@property (nonatomic) int height;
@property (nonatomic) int flags;            // SWS_FAST_BILINEAR

- (BOOL)open;

- (int)convert:(const uint8_t * const [])i_data i_linesize:(const int [])i_linesize o_data:(uint8_t * const [])o_data o_linesize:(const int [])o_linesize;

@end
