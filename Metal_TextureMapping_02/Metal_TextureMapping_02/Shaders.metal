//
//  Shaders.metal
//  Metal_TextureMapping_02
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
    // 比 01 多的代码
    out.texCoord = vertexArr[vid].uv;
    return out;
}
// 返回值从 01 的float4 改成 half4
fragment half4 fragmentShader(ColorInOut in [[stage_in]],
                               // 比 01 多了一个参数
                               texture2d<half> mtltexture01 [[texture(0)]]) {
//    return float4(1.0, 0, 0, 0);  // 这是 01 的代码， 注释掉
    
    constexpr sampler textureSampler(mag_filter::linear, min_filter:: linear);
    const half4 color = mtltexture01.sample(textureSampler, in.texCoord);
    return color;
}
