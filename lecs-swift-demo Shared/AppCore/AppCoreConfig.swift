//
// Created by David Kanenwisher on 1/3/23.
//

import Foundation

public struct AppCoreConfig {

    public let game: Game

    public let platform: Platform

    public let services: Services

    // Configuring how the platform interacts with the Game
    public struct Platform {
        public let maximumTimeStep: Float // the maximum length of a time step
        public let worldTimeStep: Float // number of steps to take each frame
    }

    // Need to be careful about the difference between configuration and levels.
    public struct Game {
        // The level to start the game at.
        public let firstLevelIndex: Int = 0

        public let world: World

        public struct World {
            public let playerTurningSpeed: Float = .pi/2
        }
    }

    public struct Services {
        public let renderService: AppCoreConfig.Services.RenderService
        public let fileService: AppCoreConfig.Services.FileService

        public struct RenderService {
            public let type: RenderServiceType
            public let clearColor: (Double, Double, Double, Double)
        }

        public struct FileService {
            public let levelsFile: FileDescriptor

            public struct FileDescriptor {
                public let name: String
                public let ext: String
            }
        }
    }
}
