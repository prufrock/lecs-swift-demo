//
//  Shaders.metal
//  DrawMaze
//
//  Created by David Kanenwisher on 1/9/23.
//

#include <metal_stdlib>
#include <simd/simd.h>
using namespace metal;

struct Vertex
{
    float3 position [[attribute(0)]];
};

struct VertexOut {
    float4 position [[position]];
    // when rendering points you need to specify the point_size or else it grabs it from a random place.
    float point_size [[point_size]];
};

vertex VertexOut vertex_main(Vertex v [[stage_in]],
                             constant matrix_float4x4 &transform [[buffer(1)]]
                             ) {
    VertexOut vertex_out {
        .position = transform * float4(v.position, 1),
        .point_size = 20.0
    };

    return vertex_out;
}

vertex VertexOut vertex_indexed(Vertex in [[stage_in]],
                             constant float &point_size [[buffer(1)]],
                             constant matrix_float4x4 &camera [[buffer(2)]],
                             constant matrix_float4x4 *indexedModelMatrix [[buffer(3)]],
                             uint vid [[vertex_id]],
                             uint iid [[instance_id]]
                             ) {
    VertexOut vertex_out {
        .position = camera * indexedModelMatrix[iid] * float4(in.position, 1),
        .point_size = point_size,
    };

    return vertex_out;
}

fragment float4 fragment_main(constant float4 &color [[buffer(0)]]) {
    return color;
}
