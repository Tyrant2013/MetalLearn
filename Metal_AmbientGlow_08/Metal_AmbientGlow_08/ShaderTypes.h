//
//  ShaderTypes.h
//  Metal_AmbientGlow_08
//
//  Created by ZHXW on 2021/2/2.
//

//
//  Header containing types and enum constants shared between Metal shaders and Swift/ObjC source
//
#ifndef ShaderTypes_h
#define ShaderTypes_h

#ifdef __METAL_VERSION__
#define NS_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
#define NSInteger metal::int32_t
#else
#import <Foundation/Foundation.h>
#endif

#include <simd/simd.h>

typedef NS_ENUM(NSInteger, BufferIndex)
{
    BufferIndexMeshPositions = 0,
    BufferIndexMeshGenerics  = 1,
    BufferIndexUniforms      = 2
};

typedef NS_ENUM(NSInteger, VertexAttribute)
{
    VertexAttributePosition  = 0,
    VertexAttributeTexcoord  = 1,
};

typedef NS_ENUM(NSInteger, TextureIndex)
{
    TextureIndexColor    = 0,
};

typedef struct
{
    matrix_float4x4 projectionMatrix;
    matrix_float4x4 modelViewMatrix;
    matrix_float4x4 modelMatrix;
    matrix_float4x4 viewMatrix;
    
    float IL; // 光源强度
    float Kd; // 漫反射系数  (0 ~ 1)
    float Ks; // 镜面反射系数
    float shininess; // 镜面反射高光指数
    float Ia; // 环境光强度
    float Ka; // 环境光系数
    
    vector_float3 directionalLightDirection;
    vector_float3 directionalLightColor;
    
    vector_float3 cameraPos; // 相机世界坐标
} Uniforms;

#endif /* ShaderTypes_h */

