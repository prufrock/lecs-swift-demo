//
// Created by David Kanenwisher on 1/5/23.
//

import Foundation

/**
 Game manages all of the logic of the game. The World is a part of Game because there may be time when Game needs to
 change World or interrupt it. If World wants to change itself, like change levels, or do something to Game it needs to
 pass a command up.

 - Going to see if I can get by with just the config from AppCore for now.
 */
class Game {
    private(set) var world: World
    private let levels: [TileMap]
    private let config: AppCoreConfig.Game

    init(config: AppCoreConfig.Game, levels: [TileMap]) {
        self.config = config
        self.levels = levels
        // Game manages the world
        // Seems like we should start at level 0
        world = World(config: config.world, map: levels[config.firstLevelIndex])
    }

    /**
     Update the game.
     - Parameters:
       - timeStep: The amount of time to move forward.
       - input: all of the stuff that could change from the ViewController that World needs to know about.
     */
    func update(timeStep: Float, input: Input) {
        world.update(timeStep: timeStep, input: input)
    }
}
