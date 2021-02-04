//
//  Shaders.metal
//  Metal_VertexDescriptor_03
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

// 比 02 多的代码
typedef struct {
    float2 pos[[attribute(0)]];
    float2 uv[[attribute(1)]];
} VertexAttr;

vertex ColorInOut vertexShader(VertexAttr in [[stage_in]]) { // 和 02 的不同，不是buffer(0)
    ColorInOut out;
    float4 position = vector_float4(in.pos, 0, 1.0);
    out.position = position;
    out.texCoord = in.uv;
    return out;
}
fragment half4 fragmentShader(ColorInOut in [[stage_in]],
                               texture2d<half> mtltexture01 [[texture(0)]]) {
    constexpr sampler textureSampler(mag_filter::linear, min_filter:: linear);
    const half4 color = mtltexture01.sample(textureSampler, in.texCoord);
    return color;
}
