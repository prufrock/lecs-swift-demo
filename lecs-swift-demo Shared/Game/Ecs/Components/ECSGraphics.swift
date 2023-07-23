//
// Created by David Kanenwisher on 2/14/23.
//

import Foundation
import simd

struct ECSGraphics: ECSComponent {
    mutating func update(input: GameInput, entity: inout ECSEntity, world: inout World) {
    }
    
    var entityID: String
    var color: Float4 = Float4(Color.orange)
    var uprightToWorld: Float4x4 = Float4x4.identity()
    var camera: Camera = .hud
    var hidden: Bool = false
    var radius: Float = 0.25

    enum Camera {
        case hud
        case world
    }

    mutating func receive(message: ECSMessage) {
        switch message {
        case .UpdatePositionXy(let position):
            uprightToWorld = Float4x4.translate(F2(position.x, position.y)) * Float4x4.scale(x: radius, y: radius, z: 1.0)
        case .UpdatePositionXyz(let position):
            uprightToWorld = Float4x4.translate(x: position.x, y: position.y, z: 0.0) * Float4x4.scale(x: radius, y: radius, z: 1.0)
        default:
            break
        }
    }
}
