//
//  Renderer.swift
//  Metal_VertexDescriptor_03
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
    var mtltexture01: MTLTexture?
    // 比 02 多的代码
    var vertexDescriptor: MTLVertexDescriptor
    
    init?(metalKitView: MTKView) {
        self.device = metalKitView.device!
        metalKitView.depthStencilPixelFormat = .depth32Float_stencil8
        metalKitView.colorPixelFormat = .bgra8Unorm_srgb
        metalKitView.sampleCount = 1
        
        /* AOS: Array Of Structure */
        // 比 02 多的代码
        vertexDescriptor = MTLVertexDescriptor()
        // pos
        vertexDescriptor.attributes[0].format = .float2
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        // uv
        vertexDescriptor.attributes[1].format = .float2
        // 0,    1.0, 0.5, 0,  前两个数是pos, 后两个是uv, uv的偏移是 MemoryLayout<Float>.size * 2
        vertexDescriptor.attributes[1].offset = MemoryLayout<Float>.size * 2
        vertexDescriptor.attributes[1].bufferIndex = 0
        // layout
        // 连续定义在同一个buffer中所以这里只配置了一个layouts[0]，
        //stride属性表示每次去取一个顶点数据的数据跨度，这里每个顶点数据占16字节，所以stride设置为16。
        // 另外关于stepRate和stepFunction的含义和作用，此处不展开讨论，主要用在Instance rendering和Tessellating等技术中。
        vertexDescriptor.layouts[0].stride = MemoryLayout<Float>.size * 4
        vertexDescriptor.layouts[0].stepRate = 1
        vertexDescriptor.layouts[0].stepFunction = .perVertex
        
        /* SOA: Structure Of Array */
        // 使用下面的作法的话，就要把顶点数据放到两个buffer里
//        vertexDescriptor = MTLVertexDescriptor()
//        // pos
//        vertexDescriptor.attributes[0].format = .float2
//        vertexDescriptor.attributes[0].offset = 0
//        vertexDescriptor.attributes[0].bufferIndex = 0
//        // uv
//        vertexDescriptor.attributes[1].format = .float2
//        // 0,    1.0, 0.5, 0,  前两个数是pos, 后两个是uv, uv的偏移是 MemoryLayout<Float>.size * 2
//        vertexDescriptor.attributes[1].offset = 0
//        vertexDescriptor.attributes[1].bufferIndex = 0
//        // layout
//        vertexDescriptor.layouts[0].stride = MemoryLayout<Float>.size * 2
//        vertexDescriptor.layouts[0].stepRate = 1
//        vertexDescriptor.layouts[0].stepFunction = .perVertex
//
//        vertexDescriptor.layouts[1].stride = MemoryLayout<Float>.size * 2
//        vertexDescriptor.layouts[1].stepRate = 1
//        vertexDescriptor.layouts[1].stepFunction = .perVertex
        
        let defaultLibrary = device.makeDefaultLibrary()
        let vertexFunction = defaultLibrary?.makeFunction(name: "vertexShader")
        let fragmentFunction = defaultLibrary?.makeFunction(name: "fragmentShader")
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.label = "MyPipeline"
        pipelineStateDescriptor.sampleCount = metalKitView.sampleCount
        pipelineStateDescriptor.vertexDescriptor = vertexDescriptor // 比 02 多的代码
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
            MTKTextureLoader.Option.textureUsage : MTLTextureUsage.shaderRead.rawValue,
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
           let renderPassDescriptor = view.currentRenderPassDescriptor {
            // 比 02 多的代码
            renderPassDescriptor.tileWidth = 16
            renderPassDescriptor.tileHeight = 16
            if let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
                renderEncoder.label = "AppRenderEncoder"
                renderEncoder.pushDebugGroup("DrawTriangle")
                renderEncoder.setRenderPipelineState(pipelineState)
                renderEncoder.setDepthStencilState(depthState)
                renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
                renderEncoder.setFragmentTexture(mtltexture01, index: 0)
                renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
                renderEncoder.popDebugGroup()
                renderEncoder.endEncoding()
                commandBuffer.present(view.currentDrawable!)
                
                commandBuffer.commit()
            }
        }
    }
}
