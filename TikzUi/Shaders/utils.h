//
//  utils.h
//  TikzUi
//
//  Created by Mattia Marini on 29/03/24.
//

#ifndef utils_h
#define utils_h
#include <metal_stdlib>

float2 actual_pos(float2 pos, float xoffset, float yoffset, float scale);

float2 actual_normalized_pos(float2 pos, float xoffset, float yoffset, float scale);

bool in_bounds(float2 point, float4 bounds);

#endif /* utils_h */
