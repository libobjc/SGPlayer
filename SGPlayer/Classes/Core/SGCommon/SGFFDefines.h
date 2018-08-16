//
//  SGFFDefines.h
//  SGPlayer iOS
//
//  Created by Single on 2018/8/16.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, SGAVSampleFormat)
{
    SG_AV_SAMPLE_FMT_NONE = -1,
    SG_AV_SAMPLE_FMT_U8,          ///< unsigned 8 bits
    SG_AV_SAMPLE_FMT_S16,         ///< signed 16 bits
    SG_AV_SAMPLE_FMT_S32,         ///< signed 32 bits
    SG_AV_SAMPLE_FMT_FLT,         ///< float
    SG_AV_SAMPLE_FMT_DBL,         ///< double
    
    SG_AV_SAMPLE_FMT_U8P,         ///< unsigned 8 bits, planar
    SG_AV_SAMPLE_FMT_S16P,        ///< signed 16 bits, planar
    SG_AV_SAMPLE_FMT_S32P,        ///< signed 32 bits, planar
    SG_AV_SAMPLE_FMT_FLTP,        ///< float, planar
    SG_AV_SAMPLE_FMT_DBLP,        ///< double, planar
    SG_AV_SAMPLE_FMT_S64,         ///< signed 64 bits
    SG_AV_SAMPLE_FMT_S64P,        ///< signed 64 bits, planar
    
    SG_AV_SAMPLE_FMT_NB           ///< Number of sample formats. DO NOT USE if linking dynamically
};
