//
//  Shaders.metal
//  Metal_SpecularReflection_07
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
    float4 worldPos;
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
    out.worldPos = uniforms.modelMatrix * position;
    out.texCoord = in.texCoord;
    out.normal = normalize(uniforms.modelMatrix * float4((float3)in.normal, 0));
    return out;
}
fragment half4 fragmentShader(ColorInOut in [[stage_in]],
                              constant Uniforms &uniforms [[buffer(1)]],
                               texture2d<half> mtltexture01 [[texture(0)]]) {
    
    constexpr sampler textureSampler(mip_filter:: linear,
                                     mag_filter:: linear,
                                     min_filter:: linear,
                                     s_address:: repeat,
                                     t_address:: repeat);
    half4 color = mtltexture01.sample(textureSampler, in.texCoord.xy);
    
    // 法线
    float3 N = in.normal.xyz;
    // 入射光方向
    float3 L = -normalize(uniforms.directionalLightDirection);
    // 视线方向
    float3 V = normalize(uniforms.cameraPos - in.worldPos.xyz);
    // 反射光方向
    float3 R = normalize(2 * fmax(dot(N, L), 0) * N - L);
    
    // Lambert difuse
    float diffuse = uniforms.IL * uniforms.Kd * max(dot(float3(in.normal.xyz), L), 0.0);
    
    // Specular
    float specular = uniforms.IL * uniforms.Ks * pow(fmax(dot(V, R), 0), uniforms.shininess);
    
    // Phong Model
    float3 out = float3(uniforms.directionalLightColor) * float3(color.xyz) * (diffuse + specular);
    
    return half4(half3(out.xyz), 1.0);
}
