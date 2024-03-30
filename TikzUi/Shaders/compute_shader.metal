//
//  ComputeShader.metal
//  TikzUi
//
//  Created by Mattia Marini on 29/03/24.
//

#include <metal_stdlib>
#include "utils.h"
using namespace metal;

kernel void computeFunction(constant float4 * rects[[ buffer(0) ]],
                            constant float2 * mousePos [[ buffer(1) ]],
                            device int * res [[ buffer(2) ]],
                            constant float * xoffset [[ buffer(3) ]],
                            constant float * yoffset [[ buffer(4) ]],
                            constant float * scale [[ buffer(5) ]],
                            device float * debug [[ buffer(6) ]],
                            uint index [[ thread_position_in_grid ]]
                            ){
    
    //float2 actualMousePos = actualPos(*mousePos, *xoffset, *yoffset, *scale);
    float2 rect0 = actual_pos(float2(rects[index].x, rects[index].y), *xoffset, *yoffset, *scale);
    float2 rect1 = actual_pos(float2(rects[index].z, rects[index].w), *xoffset, *yoffset, *scale);
    
    if (in_bounds(*mousePos,float4(rect0, rect1)))
        *res = 1;
    /*
     if( *xoffset == 0)
     *res = 3333333;
     else
     *res = *xoffset;
     */
    
    debug[0] = (*mousePos).x;
    
    /*
     debug[1] = rects[index].x;
     debug[2] = rects[index].y;
     debug[3] = rects[index].z;
     debug[4] = rects[index].w;
     debug[5] = index;
     */
    debug[1] = rect0.x;
    debug[2] = rect0.y;
    debug[3] = rect1.x;
    debug[4] = rect1.y;
    
    //debug[2] = rect1.x;
    //debug[3] = *xoffset;
}

