//
// Created by David Kanenwisher on 1/3/23.
//

import Foundation
import MetalKit
import lecs_swift


protocol RNDRRenderer {
    func render(game: Game, to view: MTKView, with screen: ScreenDimensions)
}

/**
 Knows how to render to the view with Metal.
 */
class RNDRMetalRenderer: RNDRRenderer {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let config: AppCoreConfig.Services.RenderService
    private let depthStencilState: MTLDepthStencilState
    private let vertexPipeline: MTLRenderPipelineState
    private let vertexIndexedPipeline: MTLRenderPipelineState
    private var drawable: MTLDrawable?
    private var renderEcs: Bool

    // TODO: Find a better home for these
    let model: Model
    let vertexBuffer: MTLBuffer
    let index: [UInt16]
    let indexBuffer: MTLBuffer

    public init(config: AppCoreConfig.Services.RenderService) {
        self.config = config
        renderEcs = true

        guard let newDevice = MTLCreateSystemDefaultDevice() else {
            fatalError("""
                       I looked in the computer and didn't find a device...sorry =/
                       """)
        }

        device = newDevice

        guard let newCommandQueue = device.makeCommandQueue() else {
            fatalError("""
                       What?! No comand queue. Come on!
                       """)
        }

        commandQueue = newCommandQueue

        guard let depthStencilState = device.makeDepthStencilState(descriptor: MTLDepthStencilDescriptor().apply {
            $0.depthCompareFunction = .less
            $0.isDepthWriteEnabled = true
        }) else {
            fatalError("""
                       Agh?! The depth stencil state didn't work.
                       """)
        }

        self.depthStencilState = depthStencilState

        guard let library = device.makeDefaultLibrary() else {
            fatalError("""
                       What in the what?! The library couldn't be loaded.
                       """)
        }

        vertexPipeline = try! device.makeRenderPipelineState(descriptor: MTLRenderPipelineDescriptor().apply {
            $0.vertexFunction = library.makeFunction(name: "vertex_main")
            $0.fragmentFunction = library.makeFunction(name: "fragment_main")
            $0.colorAttachments[0].pixelFormat = .bgra8Unorm
            $0.depthAttachmentPixelFormat = .depth32Float
            $0.vertexDescriptor = MTLVertexDescriptor().apply {
                // .position
                $0.attributes[0].format = MTLVertexFormat.float3
                $0.attributes[0].bufferIndex = 0
                $0.attributes[0].offset = 0
                $0.layouts[0].stride = MemoryLayout<Float3>.stride
            }
        })

        vertexIndexedPipeline = try! device.makeRenderPipelineState(descriptor: MTLRenderPipelineDescriptor().apply {
            $0.vertexFunction = library.makeFunction(name: "vertex_indexed")
            $0.fragmentFunction = library.makeFunction(name: "fragment_main")
            $0.colorAttachments[0].pixelFormat = .bgra8Unorm
            $0.depthAttachmentPixelFormat = .depth32Float
            $0.vertexDescriptor = MTLVertexDescriptor().apply {
                // .position
                $0.attributes[0].format = MTLVertexFormat.float3
                $0.attributes[0].bufferIndex = 0
                $0.attributes[0].offset = 0
                $0.layouts[0].stride = MemoryLayout<Float3>.stride
            }
        })

        model = Square()
        vertexBuffer = device.makeBuffer(bytes: model.v, length: MemoryLayout<Float3>.stride * model.v.count, options: [])!
        index = [0, 1, 2, 3, 4, 5]
        indexBuffer = device.makeBuffer(bytes: index, length: MemoryLayout<UInt16>.stride * index.count, options: [])!
    }

    public func render(game: Game, to view: MTKView, with screen: ScreenDimensions) {
        view.device = device
        view.clearColor = MTLClearColor(red: config.clearColor.0, green: config.clearColor.1, blue: config.clearColor.2, alpha: config.clearColor.3)
        view.depthStencilPixelFormat = .depth32Float

        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            fatalError("""
                       Ugh, no command buffer. They must be fresh out!
                       """)
        }

        guard let descriptor = view.currentRenderPassDescriptor, let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            fatalError("""
                       Dang it, couldn't create a command encoder.
                       """)
        }

//        renderSceneGraph(game.world.scene, game: game, screen: screen, encoder: encoder)
//        render(game: game, screen: screen, encoder: encoder)
        if (game.world.useEcs) {
            renderIndexed(game: game, screen: screen, encoder: encoder)
        } else {
            renderIndexed(game: game, entities: game.world.entities, screen: screen, encoder: encoder)
        }
        encoder.endEncoding()

        guard let drawable = view.currentDrawable else {
            fatalError("""
                       Wakoom! Attempted to get the view's drawable and everything fell apart! Boo!
                       """)
        }

        commandBuffer.present(drawable)
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }

    private func renderSceneGraph(_ graph: ECSSceneGraph, game: Game, screen: ScreenDimensions, encoder: MTLRenderCommandEncoder) {
        for graphic in graph {
            if graphic.hidden {
                continue
            }
            let model: Model = Square()

            let viewToClip = Float4x4.identity()
            let clipToNdc = Float4x4.identity()
            let ndcToScreen = Float4x4.identity()

            //TODO: This is a hack, need to find a better way to get the camera. Maybe in the scene the graphic is a child of?
            var finalTransform: Float4x4
            switch graphic.camera {
            case .hud:
                finalTransform = ndcToScreen
                    * clipToNdc
                    * viewToClip
                    * game.world.hudCamera!.camera!.projection()
                    * graphic.uprightToWorld
            case .world:
                finalTransform = ndcToScreen
                    * clipToNdc
                    * viewToClip
                    * game.world.camera!.camera!.projection()
                    * graphic.uprightToWorld
            }

            let buffer = device.makeBuffer(bytes: model.v, length: MemoryLayout<Float3>.stride * model.v.count, options: [])

            encoder.setRenderPipelineState(vertexPipeline)
            encoder.setDepthStencilState(depthStencilState)
            encoder.setVertexBuffer(buffer, offset: 0, index: 0)
            encoder.setVertexBytes(&finalTransform, length: MemoryLayout<Float4x4>.stride, index: 1)

            var fragmentColor = graphic.color

            encoder.setFragmentBuffer(buffer, offset: 0, index: 0)
            encoder.setFragmentBytes(&fragmentColor, length: MemoryLayout<Float3>.stride, index: 0)
            encoder.drawPrimitives(type: model.primitiveType, vertexStart: 0, vertexCount: model.v.count)
        }
    }

    private func render(game: Game, screen: ScreenDimensions, encoder: MTLRenderCommandEncoder) {
        let camera: ECSGraphics.Camera = .hud
        game.world.ecs.select([LECSPosition2d.self, EntityColor.self]) { world, components in
            let point = components[0] as! LECSPosition2d
            let color = components[1] as! EntityColor

            let model: Model = Square()

            let viewToClip = Float4x4.identity()
            let clipToNdc = Float4x4.identity()
            let ndcToScreen = Float4x4.identity()

            //TODO: This is a hack, need to find a better way to get the camera. Maybe in the scene the graphic is a child of?
            var finalTransform: Float4x4
            switch camera {
            case .hud:
                finalTransform = ndcToScreen
                    * clipToNdc
                    * viewToClip
                    * game.world.hudCamera!.camera!.projection()
                    * Float4x4.translate(Float2(point.x, point.y))
                    * Float4x4.scale(x: 0.1, y: 0.1, z: 0.1)
            case .world:
                finalTransform = ndcToScreen
                    * clipToNdc
                    * viewToClip
                    * game.world.camera!.camera!.projection()
                    * Float4x4.translate(Float2(point.x, point.y))
            }

            let buffer = device.makeBuffer(bytes: model.v, length: MemoryLayout<Float3>.stride * model.v.count, options: [])

            encoder.setRenderPipelineState(vertexPipeline)
            encoder.setDepthStencilState(depthStencilState)
            encoder.setVertexBuffer(buffer, offset: 0, index: 0)
            encoder.setVertexBytes(&finalTransform, length: MemoryLayout<Float4x4>.stride, index: 1)

            var fragmentColor = Float4(x: color.r, y: color.g, z: color.b, w: color.a)

            encoder.setFragmentBuffer(buffer, offset: 0, index: 0)
            encoder.setFragmentBytes(&fragmentColor, length: MemoryLayout<Float3>.stride, index: 0)
            encoder.drawPrimitives(type: model.primitiveType, vertexStart: 0, vertexCount: model.v.count)
        }
    }

    private func renderIndexed(game: Game, screen: ScreenDimensions, encoder: MTLRenderCommandEncoder) {
        let camera: ECSGraphics.Camera = .hud

        let model: Model = Square()
        let vertexBuffer = device.makeBuffer(bytes: model.v, length: MemoryLayout<Float3>.stride * model.v.count, options: [])
        let index: [UInt16] = [0, 1, 2, 3, 4, 5]
        let indexBuffer = device.makeBuffer(bytes: index, length: MemoryLayout<UInt16>.stride * index.count, options: [])!

        var finalTransforms: [Float4x4] = []
        var color: EntityColor = EntityColor(color: ColorA(Color.orange))

        game.world.ecs.select([LECSPosition2d.self, EntityColor.self]) { world, components in
            let point = components[0] as! LECSPosition2d
            color = components[1] as! EntityColor


            let viewToClip = Float4x4.identity()
            let clipToNdc = Float4x4.identity()
            let ndcToScreen = Float4x4.identity()

            var finalTransform: Float4x4
            switch camera {
            case .hud:
                finalTransform = ndcToScreen
                    * clipToNdc
                    * viewToClip
                    * game.world.hudCamera!.camera!.projection()
                    * Float4x4.translate(Float2(point.x, point.y))
                    * Float4x4.scale(x: 0.1, y: 0.1, z: 0.1)
            case .world:
                finalTransform = ndcToScreen
                    * clipToNdc
                    * viewToClip
                    * game.world.camera!.camera!.projection()
                    * Float4x4.translate(Float2(point.x, point.y))
            }
            finalTransforms.append(finalTransform)
        }
        var pixelSize: Float = 1.0

        encoder.setRenderPipelineState(vertexIndexedPipeline)
        encoder.setDepthStencilState(depthStencilState)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.setVertexBytes(&pixelSize, length: MemoryLayout<Float>.stride, index: 1)
        encoder.setVertexBytes(finalTransforms, length: MemoryLayout<Float4x4>.stride * finalTransforms.count, index: 2)

        var fragmentColor = Float4(x: color.r, y: color.g, z: color.b, w: color.a)

        encoder.setFragmentBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.setFragmentBytes(&fragmentColor, length: MemoryLayout<Float3>.stride, index: 0)
        encoder.drawIndexedPrimitives(
            type: model.primitiveType,
            indexCount: index.count,
            indexType: .uint16,
            indexBuffer: indexBuffer,
            indexBufferOffset: 0,
            instanceCount: finalTransforms.count
        )
    }

    private func render(game: Game, entities: [[LECSComponent]], screen: ScreenDimensions, encoder: MTLRenderCommandEncoder) {
        let camera: ECSGraphics.Camera = .hud
        for i in 0..<(entities[0].count - 1) {
            let point = entities[2][i] as! LECSPosition2d

            let model: Model = Square()

            let viewToClip = Float4x4.identity()
            let clipToNdc = Float4x4.identity()
            let ndcToScreen = Float4x4.identity()

            //TODO: This is a hack, need to find a better way to get the camera. Maybe in the scene the graphic is a child of?
            var finalTransform: Float4x4
            switch camera {
            case .hud:
                finalTransform = ndcToScreen
                    * clipToNdc
                    * viewToClip
                    * game.world.hudCamera!.camera!.projection()
                    * Float4x4.translate(Float2(point.x, point.y))
                    * Float4x4.scale(x: 0.1, y: 0.1, z: 0.1)
            case .world:
                finalTransform = ndcToScreen
                    * clipToNdc
                    * viewToClip
                    * game.world.camera!.camera!.projection()
                    * Float4x4.translate(Float2(point.x, point.y))
            }

            let buffer = device.makeBuffer(bytes: model.v, length: MemoryLayout<Float3>.stride * model.v.count, options: [])

            encoder.setRenderPipelineState(vertexPipeline)
            encoder.setDepthStencilState(depthStencilState)
            encoder.setVertexBuffer(buffer, offset: 0, index: 0)
            encoder.setVertexBytes(&finalTransform, length: MemoryLayout<Float4x4>.stride, index: 1)

            var fragmentColor = Float4(Color.orange)

            encoder.setFragmentBuffer(buffer, offset: 0, index: 0)
            encoder.setFragmentBytes(&fragmentColor, length: MemoryLayout<Float3>.stride, index: 0)
            encoder.drawPrimitives(type: model.primitiveType, vertexStart: 0, vertexCount: model.v.count)
        }
    }

    private func renderIndexed(game: Game, entities: [[LECSComponent]], screen: ScreenDimensions, encoder: MTLRenderCommandEncoder) {
        let camera: ECSGraphics.Camera = .hud

        let model: Model = Square()
        let vertexBuffer = device.makeBuffer(bytes: model.v, length: MemoryLayout<Float3>.stride * model.v.count, options: [])
        let index: [UInt16] = [0, 1, 2, 3, 4, 5]
        let indexBuffer = device.makeBuffer(bytes: index, length: MemoryLayout<UInt16>.stride * index.count, options: [])!

        var finalTransforms: [Float4x4] = []
        var color = Color.orange

        entities[2].forEach { component in
            let point = component as! LECSPosition2d


            let viewToClip = Float4x4.identity()
            let clipToNdc = Float4x4.identity()
            let ndcToScreen = Float4x4.identity()

            var finalTransform: Float4x4
            switch camera {
            case .hud:
                finalTransform = ndcToScreen
                    * clipToNdc
                    * viewToClip
                    * game.world.hudCamera!.camera!.projection()
                    * Float4x4.translate(Float2(point.x, point.y))
                    * Float4x4.scale(x: 0.1, y: 0.1, z: 0.1)
            case .world:
                finalTransform = ndcToScreen
                    * clipToNdc
                    * viewToClip
                    * game.world.camera!.camera!.projection()
                    * Float4x4.translate(Float2(point.x, point.y))
            }
            finalTransforms.append(finalTransform)
        }
        var pixelSize: Float = 1.0

        encoder.setRenderPipelineState(vertexIndexedPipeline)
        encoder.setDepthStencilState(depthStencilState)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.setVertexBytes(&pixelSize, length: MemoryLayout<Float>.stride, index: 1)
        encoder.setVertexBytes(finalTransforms, length: MemoryLayout<Float4x4>.stride * finalTransforms.count, index: 2)

        var fragmentColor = Float4(color)

        encoder.setFragmentBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.setFragmentBytes(&fragmentColor, length: MemoryLayout<Float3>.stride, index: 0)
        encoder.drawIndexedPrimitives(
            type: model.primitiveType,
            indexCount: index.count,
            indexType: .uint16,
            indexBuffer: indexBuffer,
            indexBufferOffset: 0,
            instanceCount: finalTransforms.count
        )
    }
}

/**
 Does nothing, useful for testing in iCloud which doesn't support Metal.
 */
class RNDRErsatzRenderer: RNDRRenderer {
    public func render(game: Game, to view: MTKView, with screen: ScreenDimensions) {
        //no-op
    }
}
