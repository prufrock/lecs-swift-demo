//
// Created by David Kanenwisher on 1/3/23.
//

import Foundation
import MetalKit

public class RenderService {
    private let config: AppCoreConfig.Services.RenderService
    private var renderer: RNDRRenderer? = nil

    public init(_ config: AppCoreConfig.Services.RenderService) {
        self.config = config
    }

    public func sync(_ command: RenderCommand) {
        if renderer == nil {
            switch config.type {
            case .ersatz:
                renderer = RNDRErsatzRenderer()
            case .metal:
                renderer = RNDRMetalRenderer(config: config)
            }
        }
        renderer?.render(
            game: command.game,
            to: command.metalView,
            with: command.screenDimensions
        )
    }
}

public struct RenderCommand: ServiceCommand {
    let metalView: MTKView
    let screenDimensions: ScreenDimensions
    let game: Game
}

public enum RenderServiceType {
    case ersatz, metal
}
