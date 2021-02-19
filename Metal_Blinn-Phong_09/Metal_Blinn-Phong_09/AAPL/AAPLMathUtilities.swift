//
//  AAPLMathUtilities.swift
//  Metal_AAPLMesh_04
//
//  Created by ZHXW on 2021/2/3.
//

//import Foundation
import simd

func matrix_make(m00: Float, m10: Float, m20: Float, m30: Float,
                 m01: Float, m11: Float, m21: Float, m31: Float,
                 m02: Float, m12: Float, m22: Float, m32: Float,
                 m03: Float, m13: Float, m23: Float, m33: Float) -> matrix_float4x4 {
    return matrix_float4x4(SIMD4<Float>(m00, m10, m20, m30),
                           SIMD4<Float>(m01, m11, m21, m31),
                           SIMD4<Float>(m02, m12, m22, m32),
                           SIMD4<Float>(m03, m13, m23, m33))
}

func matrix_perspective_left_hand(fovyRadians: Float, aspect: Float, nearZ: Float, farZ: Float) -> matrix_float4x4 {
    let ys = 1 / tanf(fovyRadians * 0.5)
    let xs = ys / aspect
    let zs = farZ / (farZ - nearZ)
    return matrix_make(m00: xs, m10: 0, m20: 0, m30: 0,
                       m01: 0, m11: ys, m21: 0, m31: 0,
                       m02: 0, m12: 0, m22: zs, m32: 1,
                       m03: 0, m13: 0, m23: -nearZ * zs, m33: 0)
}

func matrix4x4_translation(tx: Float, ty: Float, tz: Float) -> matrix_float4x4 {
    return matrix_make(m00: 1, m10: 0, m20: 0, m30: 0,
                       m01: 0, m11: 1, m21: 0, m31: 0,
                       m02: 0, m12: 0, m22: 1, m32: 0,
                       m03: tx, m13: ty, m23: tz, m33: 1)
}

func matrix4x4_rotation(radians: Float, axis: vector_float3) -> matrix_float4x4 {
    let axis_normalize = simd_normalize(axis)
    let ct = cosf(radians)
    let st = sinf(radians)
    let ci = 1 - ct
    let x = axis_normalize.x
    let y = axis_normalize.y
    let z = axis_normalize.z
    return matrix_make(m00: ct + x * x * ci, m10: y * x * ci + z * st, m20: z * x * ci - y * st, m30: 0,
                       m01: x * y * ci - z * st, m11: ct + y * y * ci, m21: z * y * ci + x * st, m31: 0,
                       m02: x * z * ci + y * st, m12: y * z * ci - x * st, m22: ct + z * z * ci, m32: 0,
                       m03: 0, m13: 0, m23: 0, m33: 1)
}

func matrix4x4_rotation(radians: Float, x: Float, y: Float, z: Float) -> matrix_float4x4 {
    return matrix4x4_rotation(radians: radians, axis: vector_float3(x, y, z))
}
