//
//  Shaders.metal
//  Metal_DiffuseRefulection_06
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
    float4 normal;
} ColorInOut;

typedef struct {
    float3 position [[attribute(0)]];
    float2 texCoord [[attribute(1)]];
    half3 normal [[attribute(2)]];
} VertexAttr;

vertex ColorInOut vertexShader(VertexAttr in [[stage_in]],
                               constant Uniforms &uniforms [[buffer(1)]]) {
    ColorInOut out;
    float4 position = float4(in.position, 1.0);
    out.position = uniforms.projectionMatrix * uniforms.modelViewMatrix * position;
    out.texCoord = in.texCoord;
    out.normal = normalize(uniforms.modelMatrix * float4((float3)in.normal, 0));
    return out;
}
fragment half4 fragmentShader(ColorInOut in [[stage_in]],
                              constant Uniforms &uniforms [[buffer(1)]],
                               texture2d<half> mtltexture01 [[texture(0)]]) {
    // 光照的计算我们在片段着色器逐像素进行。参与计算的法向量为N，入射光方向取反和法线同向，向量都单位化。
    // 法线和入射光向量点积乘以反射系数Kd即为当前片段的漫反射光强度系数，乘以光强IL得到当前片段最终的漫反射光强度。
    // 最后片段纹理颜色乘以光源颜色进行颜色叠加，然后乘以漫反射强度得到片段最终的漫反射颜色值，直接返回。
    
    constexpr sampler textureSampler(mip_filter:: linear,
                                     mag_filter:: linear,
                                     min_filter:: linear,
                                     s_address:: repeat,
                                     t_address:: repeat);
    half4 color = mtltexture01.sample(textureSampler, in.texCoord.xy);
    
    float3 N = float3(in.normal.xyz);
    float3 L = normalize(-uniforms.directionalLightDirection);
    
    float diffuse = uniforms.IL * uniforms.Kd * max(dot(N, L), 0.0);
    float3 out = float3(uniforms.directionalLightColor) * float3(color.xyz) * diffuse;
    return half4(half3(out.xyz), 1.0);
}
