//
//  SGFFDefinesMapping.h
//  SGPlayer
//
//  Created by Single on 2018/1/26.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGGLProgramPool.h"
#import "SGGLTextureUploader.h"
#import "SGDefines.h"
#import "SGFFDefines.h"
#import "avformat.h"

SGMediaType SGFFMediaType(enum AVMediaType mediaType);
SGGLProgramType SGFFDMProgram(enum AVPixelFormat format);
SGGLTextureType SGFFDMTexture(enum AVPixelFormat format);

SGAVSampleFormat SGSampleFormatFF2SG(enum AVSampleFormat format);
enum AVSampleFormat SGSampleFormatSG2FF(SGAVSampleFormat froamt);
