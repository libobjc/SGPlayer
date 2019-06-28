//
//  SGMapping.h
//  SGPlayer
//
//  Created by Single on 2018/1/26.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGVideoRenderer.h"
#import "SGMetalViewport.h"
#import "SGFFmpeg.h"

// SG <-> SGMetal
SGMetalViewportMode SGScaling2Viewport(SGScalingMode mode);
SGScalingMode SGViewport2Scaling(SGMetalViewportMode mode);

// FF <-> SG
SGMediaType SGMediaTypeFF2SG(enum AVMediaType mediaType);
enum AVMediaType SGMediaTypeSG2FF(SGMediaType mediaType);

// FF <-> AV
OSType SGPixelFormatFF2AV(enum AVPixelFormat format);
enum AVPixelFormat SGPixelFormatAV2FF(OSType format);

// FF <-> NS
AVDictionary * SGDictionaryNS2FF(NSDictionary *dictionary);
NSDictionary * SGDictionaryFF2NS(AVDictionary *dictionary);
