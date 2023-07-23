//
// Created by David Kanenwisher on 2/17/23.
//

import Foundation

struct ECSWall: ECSComponent {
    var entityID: String

    init(entityID: String) {
        self.entityID = entityID
    }

    mutating func update(input: GameInput, entity: inout ECSEntity, world: inout World) {
        if world.playing {
            entity.graphics?.hidden = false
        } else {
            entity.graphics?.hidden = true
        }
    }

    public enum State {
        case NotToggled, Toggled
    }
}
