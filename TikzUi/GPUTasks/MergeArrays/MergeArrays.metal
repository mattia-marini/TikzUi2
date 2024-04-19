//
//  MergeArrays.metal
//  TikzUi
//
//  Created by Mattia Marini on 19/04/24.
//

#include <metal_stdlib>
using namespace metal;

template <typename T>
kernel void merge_array(constant T * v1 [[ buffer(0) ]],
                        device T * v2 [[ buffer(1) ]],
                        uint id [[thread_position_in_grid]] ){
    v2[id] = v1[id] || v2[id];
}

template [[host_name("merge_array_bool")]] kernel void merge_array(constant bool * v1 [[ buffer(0) ]],
                                                                   device bool * v2 [[ buffer(1) ]],
                                                                   uint id [[thread_position_in_grid]] );

template [[host_name("merge_array_float")]] kernel void merge_array(constant float * v1 [[ buffer(0) ]],
                                                                    device float * v2 [[ buffer(1) ]],
                                                                    uint id [[thread_position_in_grid]] );

template [[host_name("merge_array_int")]] kernel void merge_array(constant int64_t * v1 [[ buffer(0) ]],
                                                                  device int64_t * v2 [[ buffer(1) ]],
                                                                  uint id [[thread_position_in_grid]] );
