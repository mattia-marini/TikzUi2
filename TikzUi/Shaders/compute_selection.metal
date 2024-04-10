//
//  compute_selection.metal
//  TikzUi
//
//  Created by Mattia Marini on 09/04/24.
//

#include <metal_stdlib>
#include "bridging.h"
#include "utils.h"

using namespace metal;


kernel void compute_selection(device SimdRect * rects [[ buffer(0) ]],
                            constant CanvasInfos * canvasInfos [[ buffer(1) ]],
                            constant float4 * selection [[ buffer(2) ]],
                            device bool * rectsLiveSelectionBuffer [[ buffer(3) ]],
                            device bool * setNeedsDisplay [[ buffer(4) ]],
                            uint id [[ thread_position_in_grid ]]
                            ){
    //float2 rect0 = actual_pos(float2(rects[id].x, rects[index].y), *xoffset, *yoffset, *scale);
    //float2 rect0 = actual_pos(rects[id].bounds.xy, *canvasInfos);
    //float2 rect1 = actual_pos(rects[id].bounds.zw, *canvasInfos);
    
    float4 rect = actual_pos(rects[id].bounds, *canvasInfos);
    bool is_in_bounds = in_bounds(rect.xy, *selection) && in_bounds(rect.zw, *selection);
    
    if (rectsLiveSelectionBuffer[id]  != is_in_bounds){
        rectsLiveSelectionBuffer[id] = is_in_bounds;
        *setNeedsDisplay = true;
    }
    /*
    if (is_in_bounds != rects[id].status){
        *needsDisplay = true;
    }
    if (*retainOldSelection && is_in_bounds)
        rects[id].status = 1;
    else
        rects[id].status = is_in_bounds;
    
     */
    //float2 rect1 = actual_pos(float2(rects[id].z, rects[index].w), *xoffset, *yoffset, *scale);
    
}
