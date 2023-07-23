//
// Created by David Kanenwisher on 1/3/23.
//

import Foundation
import MetalKit


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

    public init(config: AppCoreConfig.Services.RenderService) {
        self.config = config

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

        renderSceneGraph(game.world.scene, game: game, screen: screen, encoder: encoder)
        encoder.endEncoding()

        guard let drawable = view.currentDrawable else {
            fatalError("""
                       Wakoom! Attempted to get the view's drawable and everything fell apart! Boo!
                       """)
        }

        commandBuffer.present(drawable)
        commandBuffer.commit()
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
}

/**
 Does nothing, useful for testing in iCloud which doesn't support Metal.
 */
class RNDRErsatzRenderer: RNDRRenderer {
    public func render(game: Game, to view: MTKView, with screen: ScreenDimensions) {
        //no-op
    }
}
