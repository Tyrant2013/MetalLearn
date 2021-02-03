//
//  Renderer.swift
//  Metal_Triangle_01
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
    var vertexBuffer: MTLBuffer
    
    init?(metalKitView: MTKView) {
        self.device = metalKitView.device!
        metalKitView.depthStencilPixelFormat = .depth32Float_stencil8
        metalKitView.colorPixelFormat = .bgra8Unorm_srgb
        metalKitView.sampleCount = 1
        
        let defaultLibrary = device.makeDefaultLibrary()
        let vertexFunction = defaultLibrary?.makeFunction(name: "vertexShader")
        let fragmentFunction = defaultLibrary?.makeFunction(name: "fragmentShader")
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.label = "MyPipeline"
        pipelineStateDescriptor.sampleCount = metalKitView.sampleCount
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
        
        let vert: [Float] = [
             0,    1.0,
             1.0, -1.0,
            -1.0, -1.0
        ]
        vertexBuffer = device.makeBuffer(bytes: vert, length: vert.count * MemoryLayout<Float>.size, options: .storageModeShared)!
        
        super.init()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
        if let commandBuffer = commandQueue.makeCommandBuffer(),
           let renderPassDescriptor = view.currentRenderPassDescriptor,
           let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
            renderEncoder.label = "AppRenderEncoder"
            renderEncoder.pushDebugGroup("DrawTriangle")
            renderEncoder.setRenderPipelineState(pipelineState)
            renderEncoder.setDepthStencilState(depthState)
            renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
            renderEncoder.popDebugGroup()
            renderEncoder.endEncoding()
            commandBuffer.present(view.currentDrawable!)
            
            commandBuffer.commit()
        }
    }
}
