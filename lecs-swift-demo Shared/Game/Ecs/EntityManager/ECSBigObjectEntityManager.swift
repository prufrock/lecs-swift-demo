//
// Created by David Kanenwisher on 2/14/23.
//

import Foundation
import simd
import os.signpost


/**
 * Manages Entities that are big objects composed of all their components rather than
 * all separate objects.
 */
struct ECSBigObjectEntityManager: ECSEntityManager {
    var entities: [ECSEntity]
    {
        entityMap.values.map({$0})
    }

    private var entityMap: [String:ECSEntity] = [:]

    //TODO: what if there were many scenes(hud, world), each with its own uniforms like camera?
    //rebuild the scene graph each time it's needed -- may only want to do when it's dirty
    var scene: ECSSceneGraph
    {
        var scene = ECSSceneGraph()
        for entity in entities {
            if let component = entity.graphics {
                scene.addChild(data: component)
            }
        }
        return scene
    }

    //TODO: convert to a quad tree
    //TODO: rebuild the collision list each time it's needed -- may only want to do when it's dirty
    private var collisions: [ECSCollision]
    {
        var collection: [ECSCollision] = []
        for entity in entities {
            if let component = entity.collision {
                collection.append(component)
            }
        }
        return collection
    }

    mutating func createDecoration(id: String, position: Float2) -> ECSEntity {
        let graphics = ECSGraphics(entityID: id, uprightToWorld: Float4x4.translate(position))
        let entity = ECSEntity(id: id, graphics: graphics)

        update(entity)

        return entity
    }

    mutating func createToggleButton(id: String, position: Float2) -> ECSEntity {
        let radius: Float = 0.5
        let toggleButton = ECSToggleButton(entityID: id, toggledAction: { _, _, _ in print("toggled")}, notToggledAction: { _, _, _ in print("not toggled")})
        let graphics = ECSGraphics(
            entityID: id,
            color: toggleButton.notToggledColor,
            uprightToWorld: Float4x4.translate(position) * Float4x4.scale(x: radius, y: radius, z: 1.0)
        )
        let collision = ECSCollision(entityID: id, radius: radius, position: position)
        let entity = ECSEntity(id: id, toggleButton: toggleButton, graphics: graphics, collision: collision)

        update(entity)

        return entity
    }

    mutating func createToggleButton(
        id: String,
        position: Float2,
        buttonState: ECSToggleButton.State = .NotToggled,
        toggledAction: @escaping (GameInput, inout ECSEntity, inout World) -> Void,
        notToggledAction: @escaping (GameInput, inout ECSEntity, inout World) -> Void
    ) -> ECSEntity {
        let radius: Float = 0.5
        let toggleButton = ECSToggleButton(entityID: id, buttonState: buttonState, toggledAction: toggledAction, notToggledAction: notToggledAction)
        let graphics = ECSGraphics(
            entityID: id,
            color: toggleButton.notToggledColor,
            uprightToWorld: Float4x4.translate(position) * Float4x4.scale(x: 0.5, y: 0.5, z: 1.0)
        )
        let collision = ECSCollision(entityID: id, radius: radius, position: position)
        let entity = ECSEntity(id: id, toggleButton: toggleButton, graphics: graphics, collision: collision)

        update(entity)

        return entity
    }

    mutating func createMapButton(
        id: String,
        position: Float2,
        buttonState: ECSMapButton.State = .NotToggled,
        toggledAction: @escaping (GameInput, inout ECSEntity, inout World) -> Void,
        notToggledAction: @escaping (GameInput, inout ECSEntity, inout World) -> Void
    ) -> ECSEntity {
        let radius: Float = 0.5
        let mapButton = ECSMapButton(entityID: id, buttonState: buttonState, toggledAction: toggledAction, notToggledAction: notToggledAction)
        let graphics = ECSGraphics(
            entityID: id,
            color: mapButton.notToggledColor,
            uprightToWorld: Float4x4.translate(position) * Float4x4.scale(x: 0.5, y: 0.5, z: 1.0)
        )
        let collision = ECSCollision(entityID: id, radius: radius, position: position)
        let entity = ECSEntity(id: id, mapButton: mapButton, graphics: graphics, collision: collision)

        update(entity)

        return entity
    }

    /**
     * Create a prop: an entity that can be collided with.
     */
    mutating func createProp(id: String, position: Float2, radius: Float, camera: ECSGraphics.Camera = .world) -> ECSEntity {
        let graphics = ECSGraphics(
            entityID: id,
            color: Float4(0.0, 0.0, 1.0, 1.0),
            uprightToWorld: Float4x4.translate(position) * Float4x4.scale(x: radius, y: radius, z: 1.0),
            camera: camera
        )
        let collision = ECSCollision(entityID: id, radius: radius, position: position)
        let entity = ECSEntity(id: id, graphics: graphics, collision: collision)

        update(entity)

        return entity
    }

    mutating func createWall(id: String, position: Float2, radius: Float, camera: ECSGraphics.Camera) -> ECSEntity {
        var entity = createProp(id: id, position: position, radius: radius, camera: camera)

        entity.wall = ECSWall(entityID: id)
        entity.collision = ECSCollision(entityID: id, radius: radius, position: position)

        update(entity)

        return entity
    }

    mutating func createCamera(id: String, initialAspectRatio: Float, speed: Float = 0, position3d: F3, baseWorldToView: @escaping (ECSCamera) -> Float4x4) -> ECSEntity {
        let camera = ECSCamera(entityID: id, aspect: initialAspectRatio, speed: speed, position3d: position3d, stationary: true, worldToView: baseWorldToView)
        var entity = ECSEntity(id: id, camera: camera)
        //TODO: not all cameras should move
        entity.input = ECSInput(entityID: id)

        update(entity)

        return entity
    }

    mutating func createPlayer(id: String, initialAspectRatio: Float, speed: Float = 0, position3d: F3, radius: Float, baseWorldToView: @escaping (ECSCamera) -> Float4x4) -> ECSEntity {
        let camera = ECSCamera(entityID: id, aspect: initialAspectRatio, speed: speed, position3d: position3d, stationary: false, worldToView: baseWorldToView)
        var entity = ECSEntity(id: id, camera: camera)
        entity.input = ECSInput(entityID: id)

        entity.collision = ECSCollision(entityID: id, radius: 0.1, position: F2(position3d.x, position3d.y), collisionResponse: true)

        let graphics = ECSGraphics(
            entityID: id,
            color: Float4(0.0, 0.7, 1.0, 1.0),
            uprightToWorld: Float4x4.translate(F2(position3d.x, position3d.y)) * Float4x4.scale(x: 0.5, y: 0.5, z: 1.0),
            camera: .world
        )
        entity.graphics = graphics

        update(entity)

        return entity
    }

    // MARK: Entity Table

    public func find(_ entityId: String) -> ECSEntity? {
        entityMap[entityId]
    }

    mutating public func update(_ entity: ECSEntity) {
        entityMap[entity.id] = entity
    }

    mutating public func remove(_ entity: ECSEntity) {
        let removed = entityMap.removeValue(forKey: entity.id)
        print("removed \(removed?.id)")
    }

    // MARK: Collision Table

    public func collides(with rect: Rect, prefix: String = "") -> [ECSCollision] {
        collisions.filter { $0.entityID.starts(with: prefix) && rect.intersection(with: $0.rect) != nil }
    }

    public func pickCollision(at location: ECSCollision) -> ECSEntity? {
        var largestIntersectedButton: ECSEntity? = nil
        var largestIntersection: Float2?
        // TODO: Needs some touching up =|
        collides(with: location.rect).forEach { button in
            if button.hidden != true, location.entityID != button.entityID, let intersection = location.intersection(with: button.rect),
               intersection.length > (largestIntersection?.length ?? 0) {
                largestIntersection = intersection
                largestIntersectedButton = find(button.entityID)!
                print(button.entityID)
            }
        }

        return largestIntersectedButton
    }
}
