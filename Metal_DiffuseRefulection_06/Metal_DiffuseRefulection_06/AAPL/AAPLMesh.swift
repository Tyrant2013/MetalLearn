//
//  AAPLMesh.swift
//  Metal_AAPLMesh_04
//
//  Created by ZHXW on 2021/2/3.
//

import Foundation
import simd
import MetalKit

class AAPLSubmesh {
    var metalKitSubmmesh: MTKSubmesh
    var textures: [MTLTexture]
    
    class func createMetalTexture(material: MDLMaterial, modelIOMaterialSemantic: MDLMaterialSemantic, metalKitTextureLoader: MTKTextureLoader) throws -> MTLTexture? {
        let propertiesWithSemantic = material.properties(with: modelIOMaterialSemantic)
        for property in propertiesWithSemantic {
            if property.type == .string || property.type == .URL {
                let textureLoaderOptions = [
                    MTKTextureLoader.Option.textureUsage : MTLTextureUsage.shaderRead.rawValue,
                    MTKTextureLoader.Option.textureStorageMode : MTLStorageMode.private.rawValue,
                    MTKTextureLoader.Option.SRGB : false
                ] as [MTKTextureLoader.Option : Any]
                let url = property.urlValue
                var urlString = ""
                if property.type == .URL {
                    urlString = url?.absoluteString ?? ""
                }
                else {
                    urlString = "file://" + (property.stringValue ?? "")
                }
                let textureURL = URL(string: urlString)!
                if let texture = try? metalKitTextureLoader.newTexture(URL: textureURL, options: textureLoaderOptions) {
                    return texture
                }
                let lastComponent = urlString.components(separatedBy: "/").last!
                if let texture = try? metalKitTextureLoader.newTexture(name: lastComponent, scaleFactor: 1.0, bundle: nil, options: textureLoaderOptions) {
                    return texture
                }
                NSException(name: NSExceptionName("Texture data for material property not found"),
                            reason: "Requested material property semantic: \(modelIOMaterialSemantic), string: \(property.stringValue ?? "")",
                            userInfo: nil).raise()
            }
        }
        NSException(name: NSExceptionName("No appropriate material property from which to create texture"),
                    reason: "Requested material property semantic: \(modelIOMaterialSemantic)",
                    userInfo: nil).raise()
        return nil
    }
    
    init(modelIOSubmesh: MDLSubmesh, metalKitSubmesh: MTKSubmesh, metalKitTextureLoader: MTKTextureLoader) {
        self.metalKitSubmmesh = metalKitSubmesh
        textures = [MTLTexture]()
        do {
            textures.append(try AAPLSubmesh.createMetalTexture(material: modelIOSubmesh.material!,
                                                               modelIOMaterialSemantic: MDLMaterialSemantic.baseColor,
                                                               metalKitTextureLoader: metalKitTextureLoader)!)
            textures.append(try AAPLSubmesh.createMetalTexture(material: modelIOSubmesh.material!,
                                                               modelIOMaterialSemantic: MDLMaterialSemantic.specular,
                                                               metalKitTextureLoader: metalKitTextureLoader)!)
            textures.append(try AAPLSubmesh.createMetalTexture(material: modelIOSubmesh.material!,
                                                               modelIOMaterialSemantic: MDLMaterialSemantic.tangentSpaceNormal,
                                                               metalKitTextureLoader: metalKitTextureLoader)!)
        }
        catch {
            print("error: ", error)
        }
    }
}

class AAPLMesh {
    private(set) var metalKitMesh: MTKMesh
    private(set) var submeshes: [AAPLSubmesh]
    init(modelIOMesh: MDLMesh, modelIOVertexDescriptor: MDLVertexDescriptor, metalKitTextureLoader: MTKTextureLoader, metalDevice: MTLDevice) throws {
        modelIOMesh.addTangentBasis(forTextureCoordinateAttributeNamed: MDLVertexAttributeTextureCoordinate,
                                    normalAttributeNamed: MDLVertexAttributeNormal,
                                    tangentAttributeNamed: MDLVertexAttributeTangent)
        modelIOMesh.addTangentBasis(forTextureCoordinateAttributeNamed: MDLVertexAttributeTextureCoordinate,
                                    tangentAttributeNamed: MDLVertexAttributeTangent,
                                    bitangentAttributeNamed: MDLVertexAttributeBitangent)
        modelIOMesh.vertexDescriptor = modelIOVertexDescriptor
        let metalKitMesh = try MTKMesh(mesh: modelIOMesh, device: metalDevice)
        self.metalKitMesh = metalKitMesh
        assert(metalKitMesh.submeshes.count == modelIOMesh.submeshes!.count)
        self.submeshes = [AAPLSubmesh]()
        for index in 0..<metalKitMesh.submeshes.count {
            let submesh = AAPLSubmesh(modelIOSubmesh: modelIOMesh.submeshes![index] as! MDLSubmesh,
                                      metalKitSubmesh: metalKitMesh.submeshes[index],
                                      metalKitTextureLoader: metalKitTextureLoader)
            submeshes.append(submesh)
        }
    }
    
    class func newMesh(url: URL, modelIOVertexDescriptor: MDLVertexDescriptor, metalDevice: MTLDevice) throws -> [AAPLMesh] {
        var meshs = [AAPLMesh]()
        let bufferAllocator = MTKMeshBufferAllocator(device: metalDevice)
        let asset = MDLAsset(url: url, vertexDescriptor: nil, bufferAllocator: bufferAllocator)
        let textureLoader = MTKTextureLoader(device: metalDevice)
        for objectIndex in 0..<asset.count {
            let object = asset.object(at: objectIndex)
            let assetMeshes = try AAPLMesh.newMesh(object: object,
                                                   modelIOVertexDescriptor: modelIOVertexDescriptor,
                                                   metalKitTextureLoader: textureLoader,
                                                   metalDevice: metalDevice)
            meshs.append(contentsOf: assetMeshes)
        }
        return meshs
    }
    
    class func newMesh(object: MDLObject, modelIOVertexDescriptor: MDLVertexDescriptor, metalKitTextureLoader: MTKTextureLoader, metalDevice: MTLDevice) throws -> [AAPLMesh] {
        var meshs = [AAPLMesh]()
        if object.isKind(of: MDLMesh.self) {
            let mesh = object as! MDLMesh
            let newMesh = try AAPLMesh(modelIOMesh: mesh,
                                       modelIOVertexDescriptor: modelIOVertexDescriptor,
                                       metalKitTextureLoader: metalKitTextureLoader,
                                       metalDevice: metalDevice)
            meshs.append(newMesh)
            
        }
        for child in object.children.objects {
            let childMeshes = try AAPLMesh.newMesh(object: child,
                                                   modelIOVertexDescriptor: modelIOVertexDescriptor,
                                                   metalKitTextureLoader: metalKitTextureLoader,
                                                   metalDevice: metalDevice)
            meshs.append(contentsOf: childMeshes)
        }
        return meshs
    }
}
