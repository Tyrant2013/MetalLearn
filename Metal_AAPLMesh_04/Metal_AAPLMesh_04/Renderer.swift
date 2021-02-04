//
//  Renderer.swift
//  Metal_AAPLMesh_04
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
//    var vertexBuffer: MTLBuffer
    
    var defaultVertexDescriptor: MTLVertexDescriptor
    var meshes: [AAPLMesh]
    
    init?(metalKitView: MTKView) {
        self.device = metalKitView.device!
        metalKitView.depthStencilPixelFormat = .depth32Float_stencil8
        metalKitView.colorPixelFormat = .bgra8Unorm_srgb
        metalKitView.sampleCount = 1
        
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
        pipelineStateDescriptor.label = "MyPipeline"
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
        
    }
    
    func draw(in view: MTKView) {
        if let commandBuffer = commandQueue.makeCommandBuffer(),
           let renderPassDescriptor = view.currentRenderPassDescriptor {
            if let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
                renderEncoder.setCullMode(.back)
                
                renderEncoder.pushDebugGroup("Render Forward Lighting")
                
                renderEncoder.setRenderPipelineState(pipelineState)
                renderEncoder.setDepthStencilState(depthState)
                
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
