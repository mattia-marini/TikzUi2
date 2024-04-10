//
//  GPUTaskArray.metal
//  TikzUi
//
//  Created by Mattia Marini on 10/04/24.
//

#include <metal_stdlib>
using namespace metal;

kernel void set_array_int(device int64_t * v [[ buffer(0) ]],
                          constant int * value [[ buffer(1) ]],
                        uint id [[thread_position_in_grid]] ){
    v[id] = *value;
}

kernel void set_array_float(device float * v [[ buffer(0) ]],
                          constant float * value [[ buffer(1) ]],
                        uint id [[thread_position_in_grid]] ){
    v[id] = *value;
}

kernel void set_array_bool(device bool * v [[ buffer(0) ]],
                          constant bool * value [[ buffer(1) ]],
                        uint id [[thread_position_in_grid]] ){
    v[id] = *value;
}

kernel void merge_array_bool(constant bool * v1 [[ buffer(0) ]],
                             device bool * v2 [[ buffer(1) ]],
                        uint id [[thread_position_in_grid]] ){
    v2[id] = v1[id] || v2[id];
}
