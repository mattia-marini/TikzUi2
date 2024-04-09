//
//  bridging.h
//  TikzUi
//
//  Created by Mattia Marini on 08/04/24.
//

#ifndef bridging_h
#define bridging_h
#include <simd/simd.h>
#include "stdbool.h"


struct simd_rect {
    vector_float4 bounds;
    char status;
};

#endif /* bridging_h */

