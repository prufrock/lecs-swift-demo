//
// Created by David Kanenwisher on 2/23/23.
//

import simd

public struct ECSCamera: ECSComponent {
    var entityID: String

    var aspect: Float
    var fov: Float = .pi / 2
    var nearPlane: Float = 0.1
    var farPlane: Float = 20
    var position3d: F3 = F3(0.0, 0.0, 0.0)
    var rotation2d = Float2(0.0,-1.0)
    var rotation3d = Float4x4.identity()
    var speed: Float = 0
    var stationary = true

    var worldToView: (Self) -> Float4x4

    init(entityID: String,
         aspect: Float,
         speed: Float = 0,
         position3d: Float3,
         stationary: Bool,
         worldToView: @escaping (Self) -> Float4x4
    ) {
        self.entityID = entityID
        self.aspect = aspect
        self.speed = speed
        self.position3d = position3d
        self.stationary = stationary
        self.worldToView = worldToView
    }

    func projection() -> Float4x4 {
        worldToView(self)
    }

    mutating func update(input: GameInput, entity: inout ECSEntity, world: inout World) {
        if (!stationary) {
            let velocity: F2 = rotation2d * speed

            position3d = position3d + F3(velocity.x, velocity.y, 0.0) * input.externalInput.timeStep
            entity.receive(message: .UpdatePositionXyz(position3d))
        }
    }

    mutating func receive(message: ECSMessage) {
        switch message {
        case .UpdateAspectRatio(let aspect):
            self.aspect = aspect
        case .UpdateSpeed(let speed):
            self.speed = speed
        case .UpdateRotation(let rotation2d, let rotation3d):
            self.rotation2d = rotation2d * self.rotation2d
            self.rotation3d *= rotation3d
        case .UpdatePositionXy(let position):
            position3d = F3(position.x, position.y, position3d.z)
        case .UpdatePositionXyz(let position):
            position3d = position
        }
    }
}
