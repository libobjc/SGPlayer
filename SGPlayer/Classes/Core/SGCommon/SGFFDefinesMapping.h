//
//  SGFFDefinesMapping.h
//  SGPlayer
//
//  Created by Single on 2018/1/26.
//  Copyright © 2018年 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGGLProgram.h"
#import "SGGLTextureUploader.h"
#import "SGDefines.h"
#import "SGFFDefines.h"
#import "samplefmt.h"
#import "pixfmt.h"

// SG -> GL
SGGLProgramType SGDMFormat2Program(SGAVPixelFormat format);
SGGLTextureType SGDMFormat2Texture(SGAVPixelFormat format);

// FF -> SG
SGMediaType SGDMMediaTypeFF2SG(enum AVMediaType mediaType);
SGAVSampleFormat SGDMSampleFormatFF2SG(enum AVSampleFormat format);
SGAVPixelFormat SGDMPixelFormatFF2SG(enum AVPixelFormat format);
SGAVColorRange SGDMColorRangeFF2SG(enum AVColorRange format);
SGAVColorPrimaries SGDMColorPrimariesFF2SG(enum AVColorPrimaries format);
SGAVColorTransferCharacteristic SGDMColorTransferCharacteristicFF2SG(enum AVColorTransferCharacteristic format);
SGAVColorSpace SGDMColorSpaceFF2SG(enum AVColorSpace format);
SGAVChromaLocation SGDMChromaLocationFF2SG(enum AVChromaLocation format);

// SG -> FF
enum AVMediaType SGDMMediaTypeSG2FF(SGMediaType mediaType);
enum AVSampleFormat SGDMSampleFormatSG2FF(SGAVSampleFormat foramt);
enum AVPixelFormat SGDMPixelFormatSG2FF(SGAVPixelFormat foramt);
enum AVColorRange SGDMColorRangeSG2FF(SGAVColorRange foramt);
enum AVColorPrimaries SGDMColorPrimariesSG2FF(SGAVColorPrimaries foramt);
enum AVColorTransferCharacteristic SGDMColorTransferCharacteristicSG2FF(SGAVColorTransferCharacteristic foramt);
enum AVColorSpace SGDMColorSpaceSG2FF(SGAVColorSpace foramt);
enum AVChromaLocation SGDMChromaLocationSG2FF(SGAVChromaLocation foramt);
