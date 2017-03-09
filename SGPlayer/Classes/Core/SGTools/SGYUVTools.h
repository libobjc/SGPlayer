//
//  SGYUVTools.h
//  SGPlayer
//
//  Created by Single on 2017/3/2.
//  Copyright © 2017年 single. All rights reserved.
//

#import <SGPlatform/SGPlatform.h>
#import "pixfmt.h"

int SGYUVChannelFilterNeedSize(int linesize, int width, int height, int channel_count);
void SGYUVChannelFilter(UInt8 * src, int linesize, int width, int height, UInt8 * dst, size_t dstsize, int channel_count);
SGPLFImage * SGYUVConvertToImage(UInt8 * src_data[], int src_linesize[], int width, int height, enum AVPixelFormat pixelFormat);
