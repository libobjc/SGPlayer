//
//  SGMetalShader.metal
//  MetalTest
//
//  Created by Single on 2019/6/21.
//  Copyright © 2019 Single. All rights reserved.
//

#include <metal_stdlib>

using namespace metal;

#import "SGMetalTypes.h"

typedef struct {
    float4 position [[position]];
    float2 texCoord;
} ColorInOut;

/**
 *  Vertex
 */
vertex ColorInOut vertexShader(         uint            vertexID [[ vertex_id ]],
                               constant SGMetalVertex * in       [[ buffer(0) ]],
                               constant SGMetalMatrix & uniforms [[ buffer(1) ]])
{
    ColorInOut out;
    out.position = uniforms.mvp * in[vertexID].position;
    out.texCoord = in[vertexID].texCoord;
    return out;
}

/**
 *  Fragment - BGRA
 */
fragment float4 fragmentShaderBGRA(ColorInOut      in      [[ stage_in ]],
                                   texture2d<half> texture [[ texture(0) ]])
{
    constexpr sampler linearSampler(mip_filter::nearest,
                                    mag_filter::linear,
                                    min_filter::linear);
    return float4(texture.sample(linearSampler, in.texCoord));
}

/**
 *  Fragment - NV12
 */
fragment float4 fragmentShaderNV12(ColorInOut      in        [[ stage_in ]],
                                   texture2d<half> textureY  [[ texture(0) ]],
                                   texture2d<half> textureUV [[ texture(1) ]])
{
    constexpr sampler linearSampler(mip_filter::nearest,
                                    mag_filter::linear,
                                    min_filter::linear);
    float y = textureY .sample(linearSampler, in.texCoord).r;
    float u = textureUV.sample(linearSampler, in.texCoord).r - 0.5;
    float v = textureUV.sample(linearSampler, in.texCoord).g - 0.5;
    float r = y +             1.402 * v;
    float g = y - 0.344 * u - 0.714 * v;
    float b = y + 1.772 * u;
    return float4(r, g, b, 1.0);
}

/**
 *  Fragment - YUV
 */
fragment float4 fragmentShaderYUV(ColorInOut      in       [[ stage_in ]],
                                  texture2d<half> textureY [[ texture(0) ]],
                                  texture2d<half> textureU [[ texture(1) ]],
                                  texture2d<half> textureV [[ texture(2) ]])
{
    constexpr sampler linearSampler(mip_filter::nearest,
                                    mag_filter::linear,
                                    min_filter::linear);
    float y = textureY.sample(linearSampler, in.texCoord).r;
    float u = textureU.sample(linearSampler, in.texCoord).r - 0.5;
    float v = textureV.sample(linearSampler, in.texCoord).r - 0.5;
    float r = y +             1.402 * v;
    float g = y - 0.344 * u - 0.714 * v;
    float b = y + 1.772 * u;
    return float4(r, g, b, 1.0);
}
