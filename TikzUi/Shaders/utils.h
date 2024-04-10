//
//  utils.h
//  TikzUi
//
//  Created by Mattia Marini on 29/03/24.
//

#ifndef utils_h
#define utils_h
#include <metal_stdlib>
#include "bridging.h"

float2 actual_pos(float2 pos, float xoffset, float yoffset, float scale);

float2 actual_normalized_pos(float2 pos, float xoffset, float yoffset, float scale);

float2 actual_pos(float2 pos, CanvasInfos ci);
   
float2 actual_normalized_pos(float2 pos, CanvasInfos ci);

float4 actual_pos(float4 rect, CanvasInfos ci);

float4 actual_normalized_pos(float4 rect, CanvasInfos ci);
    
float2 norm_to_pixel(float2 pos, float width, float height);

bool in_bounds(float2 point, float4 bounds);

#endif /* utils_h */
