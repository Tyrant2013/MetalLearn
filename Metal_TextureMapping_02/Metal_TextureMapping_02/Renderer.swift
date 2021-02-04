//
//  Renderer.swift
//  Metal_TextureMapping_02
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
    // 比 01 多的代码
    var mtltexture01: MTLTexture?
    
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
             0,    1.0, 0.5, 0,
             1.0, -1.0, 1.0, 1.0,
            -1.0, -1.0, 0,   1.0
        ]
        vertexBuffer = device.makeBuffer(bytes: vert, length: vert.count * MemoryLayout<Float>.size, options: .storageModeShared)!
        
        // 比 01 多的代码
        let textureLoader = MTKTextureLoader(device: device)
        let textureLoaderOptions = [
            // 表示我们这张贴图是只读的，不可写入，符合我们只是采样读取贴图数据的需求，
            // 明确配置只读是为了让Metal内部做一些相关的优化，只有在必要的时候才设置可读可写
            MTKTextureLoader.Option.textureUsage : MTLTextureUsage.shaderRead.rawValue,
            // 表示我们张贴图只有GPU可以访问，CPU不可访问，这种模式下Metal可以进一步做一些优化，提高性能。
            MTKTextureLoader.Option.textureStorageMode : MTLStorageMode.private.rawValue
        ] as [MTKTextureLoader.Option : Any]
        guard let tt = try? textureLoader.newTexture(name: "texture01",
                                                     scaleFactor: 1.0,
                                                     bundle: nil,
                                                     options: textureLoaderOptions) else { return nil }
        mtltexture01 = tt
        // --> 到这里为止
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
            // 将我们的纹理贴图传递到片段着色器中，使用setFragmentTexture方法我们可以将贴图资源传入片段着色器的textrure buffer中，从而可以在片段着色器中访问，注意index要和片段着色器参数的语义绑定相对应。
            renderEncoder.setFragmentTexture(mtltexture01, index: 0) // 比 01 多的代码
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
            renderEncoder.popDebugGroup()
            renderEncoder.endEncoding()
            commandBuffer.present(view.currentDrawable!)
            
            commandBuffer.commit()
        }
    }
}
