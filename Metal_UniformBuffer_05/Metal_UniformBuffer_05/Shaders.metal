//
//  Shaders.metal
//  Metal_UniformBuffer_05
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

typedef struct {
    float3 position [[attribute(0)]];
    float2 texCoord [[attribute(1)]];
} VertexAttr;

vertex ColorInOut vertexShader(VertexAttr in [[stage_in]],
                               constant Uniforms &uniforms [[buffer(1)]]) {
    ColorInOut out;
    float4 position = float4(in.position, 1.0);
    out.position = uniforms.projectionMatrix * uniforms.modelViewMatrix * position;
    out.texCoord = in.texCoord;
    return out;
}
fragment half4 fragmentShader(ColorInOut in [[stage_in]],
                               texture2d<half> mtltexture01 [[texture(0)]]) {
    constexpr sampler textureSampler(mip_filter:: linear,
                                     mag_filter:: linear,
                                     min_filter:: linear,
                                     s_address:: repeat);
    const half4 color = mtltexture01.sample(textureSampler, in.texCoord.xy);
    return color;
}
