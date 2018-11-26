//
//  SGSWScale.h
//  SGPlayer iOS
//
//  Created by Single on 2018/8/28.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SGSWScale : NSObject

@property (nonatomic) SInt32 i_format;       // AVPixelFormat
@property (nonatomic) SInt32 o_format;       // AVPixelFormat
@property (nonatomic) SInt32 width;
@property (nonatomic) SInt32 height;
@property (nonatomic) SInt32 flags;          // SWS_FAST_BILINEAR

/**
 *
 */
- (BOOL)open;

/**
 *
 */
- (int)convert:(const UInt8 *const [])i_data i_linesize:(const SInt32 [])i_linesize o_data:(UInt8 *const [])o_data o_linesize:(const SInt32 [])o_linesize;

@end
