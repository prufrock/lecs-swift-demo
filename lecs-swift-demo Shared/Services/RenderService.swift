//
// Created by David Kanenwisher on 1/3/23.
//

import Foundation
import MetalKit

public class RenderService {
    private let config: AppCoreConfig.Services.RenderService

    public init(_ config: AppCoreConfig.Services.RenderService) {
        self.config = config
    }

    public func sync(_ command: RenderCommand) {
        // Not sure about creating this on every render request. Where does renderer cache stuff at then?
        let renderer: RNDRRenderer
        switch config.type {
        case .ersatz:
            renderer = RNDRErsatzRenderer()
        case .metal:
            renderer = RNDRMetalRenderer(config: config)
        }
        renderer.render(
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
