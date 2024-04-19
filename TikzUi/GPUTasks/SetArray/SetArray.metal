//
//  SetArray.metal
//  TikzUi
//
//  Created by Mattia Marini on 19/04/24.
//

#include <metal_stdlib>
using namespace metal;

template <typename T>
kernel void set_array(device T * v [[ buffer(0) ]],
                      constant T * value [[ buffer(1) ]],
                      uint id [[thread_position_in_grid]] ){
    v[id] = *value;
}

template [[host_name("set_array_int")]] kernel void set_array(device int64_t * v [[ buffer(0) ]],
                                                              constant int64_t * value [[ buffer(1) ]],
                                                              uint id [[thread_position_in_grid]] );

template [[host_name("set_array_float")]] kernel void set_array(device float * v [[ buffer(0) ]],
                                                                constant float * value [[ buffer(1) ]],
                                                                uint id [[thread_position_in_grid]] );

template [[host_name("set_array_bool")]] kernel void set_array(device bool * v [[ buffer(0) ]],
                                                               constant bool * value [[ buffer(1) ]],
                                                               uint id [[thread_position_in_grid]] );
