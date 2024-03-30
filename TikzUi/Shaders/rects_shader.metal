//
//  RectsShaders.metal
//  TikzUi
//
//  Created by Mattia Marini on 25/03/24.
//

#include <metal_stdlib>
using namespace metal;


struct Fragment{
    float4 position [[position]];
    float2 center;
    float radius;
    float4 normalized_pos;
};

vertex Fragment rects_vertex_function (unsigned int instanceID [[instance_id]],
                                       constant float * width [[buffer(0)]],
                                       constant float * height [[buffer(1)]],
                                       constant float * scale [[buffer(2)]],
                                       constant float * xoffset [[buffer(3)]],
                                       constant float * yoffset [[buffer(4)]],
                                       constant float * spacing[[buffer(5)]],
                                       constant float4 * rects[[buffer(6)]],
                                       uint v_id [[vertex_id]]
                                       )
{
    
    float x0 = (*xoffset/ *width * 2 ) + ((rects[instanceID].x )/ *width *2 ) * *scale -1;
    float y0 = (*yoffset / *height * 2 ) + ((rects[instanceID].y )/ *height *2 ) * *scale -1;
    
    float x1 = (*xoffset/ *width * 2 ) + ((rects[instanceID].z )/ *width *2 ) * *scale -1;
    float y1 = (*yoffset/ *height * 2 ) + ((rects[instanceID].w )/ *height *2 ) * *scale -1;
   /*
    float x0 =  ((rects[instanceID].x )/ *width *2 -1) * *scale;
    float y0 =  ((rects[instanceID].y )/ *height *2 -1) * *scale;
    
    float x1 = ((rects[instanceID].z )/ *width *2 -1) * *scale;
    float y1 = ((rects[instanceID].w )/ *height *2 -1) * *scale;
    */
    Fragment f;
    
    if (v_id == 0 || v_id == 3)
        f.position  = float4(x0, y0, 0,1);
    else if(v_id == 1 || v_id == 4)
        f.position  = float4(x1, y1, 0,1);
    else if(v_id == 2 )
        f.position  = float4(x0, y1, 0,1);
    else if(v_id == 5)
        f.position  = float4(x1, y0, 0,1);
   /*
    if (v_id == 0 || v_id == 3)
        f.position  = float4(-1, -1, 0,1);
    else if(v_id == 1 || v_id == 4)
        f.position  = float4(0, 0, 0,1);
    else if(v_id == 2 )
        f.position  = float4(-1, 0, 0,1);
    else if(v_id == 5)
        f.position  = float4(0, -1, 0,1);
    */
    /*
     f.position = float4(rects[instanceID].x / *width * 2 -1,
     rects[instanceID].y / *height * 2 -1,
     0,1);
     */
    f.center = float2( (((x0 + x1)/2 + 1)/2 * *width) * 2 ,
                       (*height - ((y0 + y1)/2 + 1)/2 * *height)*2
                      );
    
    f.radius = ((x0 + 1)/2 * *width) * 2 - f.center.x;
    return f;
}

fragment float4 rects_fragment_function(Fragment f [[stage_in]])
{
    /*
    float distance =
    (f.position.x - f.center.x) * (f.position.x - f.center.x) +
    (f.position.y - f.center.y) * (f.position.y - f.center.y);
     */
    
    
    //float max_distance =  (f.normalized_pos.x - f.normalized_pos.z) * (f.normalized_pos.x - f.normalized_pos.z) / 4;
    //float max_distance = 100;
    /*
    if ((int)f.position.x % 10 < 5)
        return float4(0,1,0,1);
    else
     */
    /*
    if (distance > max_distance)
        return float4(0,0,0,0);
    else
        return float4(0,1,0,1);
     */
    
    /*
    float distance = (f.position.x - f.center.x) * (f.position.x - f.center.x) + (f.position.y - f.center.y) * (f.position.y - f.center.y);
    float max_distance = f.radius * f.radius;
    float scale = 1 - distance/max_distance;
    
    return float4(0.8,scale,scale, scale);
     */
    
    return float4(0.8,0.8,0.8,1);
}
