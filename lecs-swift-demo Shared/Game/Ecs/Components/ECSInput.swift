//
// Created by David Kanenwisher on 4/7/23.
//

import Foundation

struct ECSInput: ECSComponent {
    var entityID: String

    mutating func update(input: GameInput, entity: inout ECSEntity, world: inout World) {
        entity.receive(message: .UpdateAspectRatio(input.externalInput.aspect))

        entity.receive(message: .UpdateSpeed(input.externalInput.speed))
        entity.receive(message: .UpdateRotation(input.externalInput.rotation, input.externalInput.rotation3d))
    }
}