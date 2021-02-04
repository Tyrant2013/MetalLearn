//
//  Renderer.swift
//  Metal_UniformBuffer_05
//
//  Created by ZHXW on 2021/2/2.
//

// Our platform independent renderer class

import Metal
import MetalKit
import simd

class Renderer: NSObject, MTKViewDelegate {
    public let device: MTLDevice
    let commandQueue: MTLCommandQueue
    var pipelineState: MTLRenderPipelineState
    var depthState: MTLDepthStencilState
    
    var defaultVertexDescriptor: MTLVertexDescriptor
    var meshes: [AAPLMesh]
    
    var uniformBuffer: MTLBuffer
    var projectionMatrix: matrix_float4x4 = matrix_float4x4()
    var rotation: Float
    
    init?(metalKitView: MTKView) {
        self.device = metalKitView.device!
        metalKitView.depthStencilPixelFormat = .depth32Float_stencil8
        metalKitView.colorPixelFormat = .bgra8Unorm_srgb
        metalKitView.sampleCount = 1
        
        rotation = 0
        let storageMode = MTLResourceOptions.storageModeShared
        uniformBuffer = device.makeBuffer(length: MemoryLayout<Uniforms>.size, options: storageMode)!
        
        /* AOS: Array Of Structure */
        defaultVertexDescriptor = MTLVertexDescriptor()
        // pos
        defaultVertexDescriptor.attributes[0].format = .float3
        defaultVertexDescriptor.attributes[0].offset = 0
        defaultVertexDescriptor.attributes[0].bufferIndex = 0
        // uv
        defaultVertexDescriptor.attributes[1].format = .float2
        defaultVertexDescriptor.attributes[1].offset = 12
        defaultVertexDescriptor.attributes[1].bufferIndex = 0
        // layout
        defaultVertexDescriptor.layouts[0].stride = 44
        defaultVertexDescriptor.layouts[0].stepRate = 1
        defaultVertexDescriptor.layouts[0].stepFunction = .perVertex
        
        let defaultLibrary = device.makeDefaultLibrary()
        let vertexFunction = defaultLibrary?.makeFunction(name: "vertexShader")
        let fragmentFunction = defaultLibrary?.makeFunction(name: "fragmentShader")
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.label = "Forward Lighting"
        pipelineStateDescriptor.sampleCount = metalKitView.sampleCount
        pipelineStateDescriptor.vertexDescriptor = defaultVertexDescriptor
        pipelineStateDescriptor.vertexFunction = vertexFunction
        pipelineStateDescriptor.fragmentFunction = fragmentFunction
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = metalKitView.colorPixelFormat
        pipelineStateDescriptor.depthAttachmentPixelFormat = metalKitView.depthStencilPixelFormat
        pipelineStateDescriptor.stencilAttachmentPixelFormat = metalKitView.depthStencilPixelFormat
        
        guard let pipeState = try? device.makeRenderPipelineState(descriptor: pipelineStateDescriptor) else { return nil }
        self.pipelineState = pipeState
        let depthStateDesc = MTLDepthStencilDescriptor()
        depthStateDesc.depthCompareFunction = .less
        depthStateDesc.isDepthWriteEnabled = true
        depthState = device.makeDepthStencilState(descriptor: depthStateDesc)!
        
        commandQueue = device.makeCommandQueue()!
        
        let modelIOVertexDescriptor = MTKModelIOVertexDescriptorFromMetal(defaultVertexDescriptor)
        (modelIOVertexDescriptor.attributes[0] as! MDLVertexAttribute).name = MDLVertexAttributePosition
        (modelIOVertexDescriptor.attributes[1] as! MDLVertexAttribute).name = MDLVertexAttributeTextureCoordinate
        let modelFileURL = Bundle.main.url(forResource: "Temple.obj", withExtension: nil)!
        do {
            meshes = try AAPLMesh.newMesh(url: modelFileURL,
                                          modelIOVertexDescriptor: modelIOVertexDescriptor,
                                          metalDevice: device)
        }
        catch {
            print("error: ", error)
            meshes = [AAPLMesh]()
        }
        super.init()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // 屏幕宽高比
        let aspect = Float(size.width / size.height)
        // 透视相机参数， 视口的角度
        let fov = Float(65.0 * (.pi / 180.0))
        // 近裁面
        let nearPlane: Float = 1.0
        // 远裁面
        let farPlane: Float = 1500.0
        projectionMatrix = matrix_perspective_left_hand(fovyRadians: fov, aspect: aspect, nearZ: nearPlane, farZ: farPlane)
    }
    
    private func updateGameState() {
        // 将相机往后拉开1000的距离，然后绕x轴逆时针渲染一定角度略微抬高相机俯视原点，
        // 然后绕y轴旋转_rotation角度，是相机围绕原点旋转。
        // ModelMatrix保持模型在原点不动，当然也可以让相机固定，让模型自身旋转。
        
        let uniforms = uniformBuffer.contents().assumingMemoryBound(to: Uniforms.self)
        uniforms.pointee.projectionMatrix = projectionMatrix
        
        let __x = matrix4x4_translation(tx: 0.0, ty: 0, tz: 1000)
        
        let ___x = matrix4x4_rotation(radians: -0.5, axis: vector_float3(1, 0, 0))
        let ___y = matrix4x4_rotation(radians: rotation, axis: vector_float3(0, 1, 0))
        let __y = matrix_multiply(___x, ___y)
        
        let viewMatrix = matrix_multiply(__x, __y)
        
        let rotationAxis = vector_float3(0, 1, 0)
        var modelMatrix = matrix4x4_rotation(radians: 0, axis: rotationAxis)
        let translation = matrix4x4_translation(tx: 0.0, ty: 0.0, tz: 0.0)
        modelMatrix = matrix_multiply(modelMatrix, translation)
        uniforms.pointee.modelViewMatrix = matrix_multiply(viewMatrix, modelMatrix)
        
        rotation += 0.002
    }
    
    func draw(in view: MTKView) {
        updateGameState()
        
        if let commandBuffer = commandQueue.makeCommandBuffer(),
           let renderPassDescriptor = view.currentRenderPassDescriptor {
            if let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
                renderEncoder.setCullMode(.back)
                
                renderEncoder.pushDebugGroup("Render Forward Lighting")
                
                renderEncoder.setRenderPipelineState(pipelineState)
                renderEncoder.setDepthStencilState(depthState)
                renderEncoder.setVertexBuffer(uniformBuffer, offset: 0, index: 1)
                
                self .drawMeshes(renderEncoder: renderEncoder)
                
                renderEncoder.popDebugGroup()
                renderEncoder.endEncoding()
                
                commandBuffer.present(view.currentDrawable!)
                
                commandBuffer.commit()
            }
        }
    }
    
    private func drawMeshes(renderEncoder: MTLRenderCommandEncoder) {
        for mesh in meshes {
            let metalKitMesh = mesh.metalKitMesh
            for bufferIndex in 0..<metalKitMesh.vertexBuffers.count {
                let vertexBuffer = metalKitMesh.vertexBuffers[bufferIndex]
                renderEncoder.setVertexBuffer(vertexBuffer.buffer,
                                              offset: vertexBuffer.offset,
                                              index: bufferIndex)
            }
            
            for submesh in mesh.submeshes {
                renderEncoder.setFragmentTexture(submesh.textures[0], index: 0)
                renderEncoder.setFragmentTexture(submesh.textures[1], index: 1)
                renderEncoder.setFragmentTexture(submesh.textures[2], index: 2)
                let metalKitSubmesh = submesh.metalKitSubmmesh
                renderEncoder.drawIndexedPrimitives(type: metalKitSubmesh.primitiveType,
                                                    indexCount: metalKitSubmesh.indexCount,
                                                    indexType: metalKitSubmesh.indexType,
                                                    indexBuffer: metalKitSubmesh.indexBuffer.buffer,
                                                    indexBufferOffset: metalKitSubmesh.indexBuffer.offset)
            }
        }
    }
}
