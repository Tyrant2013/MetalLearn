//
//  Shaders.metal
//  Metal_Triangle_01
//
//  Created by ZHXW on 2021/2/2.
//

// File for Metal kernel and shader functions

#include <metal_stdlib>
#include <simd/simd.h>

// Including header shared between this Metal shader code and Swift/C code executing Metal API commands
#import "ShaderTypes.h"

using namespace metal;

typedef struct {
    float4 position [[position]];
    float2 texCoord;
} ColorInOut;

vertex ColorInOut vertexShader(constant Vertex *vertexArr [[buffer(0)]],
                               uint vid [[vertex_id]]) {
    ColorInOut out;
    float4 position = vector_float4(vertexArr[vid].pos, 0, 1.0);
    out.position = position;
    return out;
}

//typedef struct
//{
//    float3 position [[attribute(VertexAttributePosition)]];
//    float2 texCoord [[attribute(VertexAttributeTexcoord)]];
//} Vertex;
//
//typedef struct
//{
//    float4 position [[position]];
//    float2 texCoord;
//} ColorInOut;
//
//vertex ColorInOut vertexShader(Vertex in [[stage_in]],
//                               constant Uniforms & uniforms [[ buffer(BufferIndexUniforms) ]])
//{
//    ColorInOut out;
//
//    float4 position = float4(in.position, 1.0);
//    out.position = uniforms.projectionMatrix * uniforms.modelViewMatrix * position;
//    out.texCoord = in.texCoord;
//
//    return out;
//}
//
//fragment float4 fragmentShader(ColorInOut in [[stage_in]],
//                               constant Uniforms & uniforms [[ buffer(BufferIndexUniforms) ]],
//                               texture2d<half> colorMap     [[ texture(TextureIndexColor) ]])
//{
//    constexpr sampler colorSampler(mip_filter::linear,
//                                   mag_filter::linear,
//                                   min_filter::linear);
//
//    half4 colorSample   = colorMap.sample(colorSampler, in.texCoord.xy);
//
//    return float4(colorSample);
//}
