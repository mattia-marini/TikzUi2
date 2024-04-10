//
//  bridging.h
//  TikzUi
//
//  Created by Mattia Marini on 08/04/24.
//

#ifndef bridging_h
#define bridging_h
#include <simd/simd.h>


struct SimdRect {
    vector_float4 bounds;
};

struct CanvasInfos {
    float xoffset;
    float yoffset;
    float width;
    float height;
    float scale;
};

#endif /* bridging_h */

