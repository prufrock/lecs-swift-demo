//
// Created by David Kanenwisher on 2/17/23.
//

import Foundation

struct ECSCollision: ECSComponent {
    var entityID: String
    var radius: Float = 0.5
    var position: F2 = F2(0.0, 0.0)
    var hidden = false
    var collisionResponse = false

    var rect: Rect {
        let halfSize = Float2(radius, radius)
        // the rectangle is centered on the position
        return Rect(min: position - halfSize, max: position + halfSize)
    }

    mutating func update(input: GameInput, entity: inout ECSEntity, world: inout World) {
        if collisionResponse {
            world.entityManager.collides(with: rect, prefix: "wall").filter { $0.entityID != entityID }.forEach {
                print("thump! collided with \($0.entityID)")
                var limit = 10

                while (limit > 0) {
                    let intersection = rect.intersection(with: $0.rect)
                    if let intersection = intersection {
                        position -= intersection
                    }
                    limit -= 1
                }
                position = F2(position.x, position.y)
            }
            entity.receive(message: .UpdatePositionXy(position))
        }
    }

    func intersection(with other: Rect) -> Float2? {
        rect.intersection(with: other)
    }

    mutating func receive(message: ECSMessage) {
        switch message {
        case let .UpdatePositionXyz(position):
            self.position = position.xy
        default:
            break
        }
    }
}
