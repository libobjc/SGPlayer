//
//  SGMetalTypes.h
//  MetalTest
//
//  Created by Single on 2019/6/21.
//  Copyright © 2019 Single. All rights reserved.
//

#ifndef SGMetalTypes_h
#define SGMetalTypes_h

#include <simd/simd.h>

typedef struct {
    vector_float4 position;
    vector_float2 texCoord;
} SGMetalVertex;

typedef struct {
    matrix_float4x4 mvp;
} SGMetalMatrix;

#endif /* SGMetalTypes_h */
