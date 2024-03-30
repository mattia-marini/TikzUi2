//
//  Util.metal
//  TikzUi
//
//  Created by Mattia Marini on 29/03/24.
//

#include "utils.h"
#include <metal_stdlib>
using namespace metal;

float2 actual_pos(float2 pos, float xoffset, float yoffset, float scale){
    return float2(xoffset + pos.x * scale, yoffset + pos.y * scale);
}

float2 actual_normalized_pos(float2 pos, float xoffset, float yoffset, float scale){
    return float2((pos.x + xoffset) * scale, (pos.y + yoffset) * scale);
}

bool in_bounds(float2 point, float4 bounds){
    return bounds.x < point.x  && point.x < bounds.z &&
    bounds.y < point.y  && point.y < bounds.w;
}
