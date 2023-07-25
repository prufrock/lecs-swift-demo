//
// Created by David Kanenwisher on 1/5/23.
//

import Foundation
import simd
import lecs_swift

/**
 - Going to see if I can get by with just the config from AppCore for now.
 */
struct World {
    private let config: AppCoreConfig.Game.World

    //TODO: don't commit this...
    public var entityManager: ECSEntityManager

    public var ecs: LECSWorld

    public var map: TileMap

    var scene: ECSSceneGraph {
        get {
            entityManager.scene
        }
    }

    var updatePositionSystem: LECSSystemId
    var updateColorSystem: LECSSystemId

    var entities: [[LECSComponent]]

    var entitiesUpdatePositionSystem: ([LECSComponent]) -> [LECSComponent]

    public var playing = false

    public var camera: ECSEntity?
    public var hudCamera: ECSEntity?
    public var overHeadCamera: ECSEntity?
    public var floatingCamera: ECSEntity?

    private var mapData: MapData = MapData(tiles: (0..<81).map { _ in .floor }, width: 9)

    init(config: AppCoreConfig.Game.World, map: TileMap) {
        self.config = config
        self.map = map
        self.entityManager = ECSBigObjectEntityManager()
        self.entities = [
            Array<LECSId>(repeating: LECSId(id: 0), count: 300),
            Array<LECSName>(repeating: LECSName(name: ""), count: 300),
            Array<LECSPosition2d>(repeating: LECSPosition2d(x: 0, y: 0), count: 300),
            Array<LECSVelocity2d>(repeating: LECSVelocity2d(x: 0, y: 0), count: 300)
        ]

        ecs = LECSWorldFixedSize(archetypeSize: 400)
        for i in 0..<40 {
            let b = try! ecs.createEntity("b\(i)")
            let column = Float(Int(i % 10))
            let row = Float(Int(i / 10)) + 10
            try! ecs.addComponent(b, LECSPosition2d(x: column, y: row))
            try! ecs.addComponent(b, LECSVelocity2d(x: 0, y: 0.01))
            let color = ColorA(Color.red)
            try! ecs.addComponent(b, EntityColor(color: color))
        }
        let bunny = try! ecs.createEntity("bunny")
        try! ecs.addComponent(bunny, LECSPosition2d(x: 3, y: 4))
        try! ecs.addComponent(bunny, LECSVelocity2d(x: 0, y: 0.01))
        let fox = try! ecs.createEntity("fox")
        try! ecs.addComponent(fox, LECSPosition2d(x: 2, y: 7))
        try! ecs.addComponent(fox, LECSVelocity2d(x: 0, y: 0.01))

        for i in 0..<40 {
            let column = Float(Int(i % 10))
            let row = Float(Int(i / 10))
            let id = LECSId(id: UInt(i))
            let name = LECSName(name: "b\(i)")
            let position = LECSPosition2d(x: column, y: row)
            let velocity = LECSVelocity2d(x: 0, y: 0.01)
            entities[0][i] = id
            entities[1][i] = name
            entities[2][i] = position
            entities[3][i] = velocity
        }

        updatePositionSystem = ecs.addSystem(
            "UpdatePosition",
            selector: [LECSPosition2d.self, LECSVelocity2d.self]) { world, components in
                var position = components[0] as! LECSPosition2d
                var velocity = components[1] as! LECSVelocity2d

                position.y = position.y + velocity.velocity.y
                if position.y > 20 {
                    velocity.velocity = Float2(velocity.velocity.x, -1 * velocity.velocity.y)
                } else if position.y < 0 {
                    velocity.velocity = Float2(velocity.velocity.x, -1 * velocity.velocity.y)
                }

                return [position, velocity]
        }


        updateColorSystem = ecs.addSystem(
            "UpdateColor",
            selector: [EntityColor.self]) { world, components in
                var color = components[0] as! EntityColor

                if color.increasing {
                    color.g = color.g + 0.001
                } else {
                    color.g = color.g - 0.001
                }

                if (color.g <= 0.1) {
                    color.increasing = true
                } else if (color.g >= 1) {
                    color.increasing = false
                }

                return [color]
        }

        entitiesUpdatePositionSystem = { components in
            var position = components[0] as! LECSPosition2d
            var velocity = components[1] as! LECSVelocity2d

            position.y = position.y + velocity.velocity.y
            if position.y > 10 {
                velocity.velocity = Float2(velocity.velocity.x, -1 * velocity.velocity.y)
            } else if position.y < 0 {
                velocity.velocity = Float2(velocity.velocity.x, -1 * velocity.velocity.y)
            }

            return [position, velocity]
        }
        reset()
    }

    /**
     Set the world back to how it all began...
     */
    private mutating func reset() {

        floatingCamera = entityManager.createPlayer(
            id: "floating-camera",
            initialAspectRatio: 1.0,
            speed: 1.0,
            position3d: F3(0.0, 0.0, 1.5),
            radius: 0.25,
            baseWorldToView: { component in
                Float4x4.perspectiveProjection(fov: component.fov, aspect: component.aspect, nearPlane: component.nearPlane, farPlane: component.farPlane)
                    * ( Float4x4.translate(x: component.position3d.x, y: component.position3d.y, z: component.position3d.z)
                        * Float4x4.translate(x: 0, y: 0, z: -1.0)
                        * Float4x4.rotateX(.pi/2)
                        * component.rotation3d).inverse // flip all of these things around because the camera stays put while the world moves
            })


        overHeadCamera = entityManager.createCamera(
            id: "overhead-camera",
            initialAspectRatio: 1.0,
            speed: 0.0,
            position3d: F3(5.0, 1.0, -10.5),
            baseWorldToView: { component in
                Float4x4.perspectiveProjection(fov: component.fov, aspect: component.aspect, nearPlane: component.nearPlane, farPlane: component.farPlane)
                    * Float4x4.scale(x: 1.0, y: -1.0, z: 1.0) // flip on the y-axis so the origin is the upper-left
                    * Float4x4.translate(x: component.position3d.x, y: component.position3d.y, z: component.position3d.z).inverse //invert because we look out of the camera
            })

        camera = floatingCamera

        hudCamera = entityManager.createCamera(
            id: "hud-camera",
            initialAspectRatio: 1.0,
            speed: 1.0,
            position3d: F3(0.0, 0.0, 0.0),
            baseWorldToView: { component in
                Float4x4.translate(x: -1, y: 1, z: 0.0) * // 0,0 in world space should be -1, 1 or the upper left corner in NDC.
                    Float4x4.scale(x: 0.1, y: 0.1, z: 1.0) *
                    Float4x4.scale(x: 1 / component.aspect, y: -1.0, z: 1.0)
            })
    }

    /**
     Update the game.
     - Parameters:
       - timeStep: The amount of time to move it forward.
       - input: The actionable changes in the game from the ViewController.
     */
    mutating func update(timeStep: Float, input: Input) {
        var gameInput = GameInput(externalInput: input, selectedButtonId: nil)

//        if (input.isTouched) {
//            let position = input.touchCoordinates
//                    .screenToNdc(screenWidth: input.viewWidth, screenHeight: input.viewHeight, flipY: true)
//                    .ndcToWorld(camera: hudCamera!.camera!)
//            let eLocation = entityManager.createProp(id: "touchLocation", position: position, radius: 0.12, camera: .hud)
//
//            if let collision = eLocation.collision {
//                if let selected = entityManager.pickCollision(at: collision) {
//                    print("collided entity \(selected.id)")
//                    gameInput.selectedButton = selected
//                }
//            }
//        }

        ecs.process(system: updatePositionSystem)
        ecs.process(system: updateColorSystem)

        // Update all of the entities
        entityManager.entities.forEach { entity in
            // TODO: using this until I find a better way to skip drawing a wall that's now a floor.
            if var newEntity = entityManager.find(entity.id) {
                entityManager.update(newEntity.update(input: gameInput, world: &self))
            }
        }

//        for i in 0..<(entities[0].count - 1) {
//            let updated = entitiesUpdatePositionSystem([entities[2][i], entities[3][i]])
//            entities[2][i] = updated[0]
//            entities[3][i] = updated[1]
//        }

        if let camera = hudCamera {
            hudCamera = entityManager.find(camera.id)
        }

        if let camera = overHeadCamera {
            overHeadCamera = entityManager.find(camera.id)
        }

        if let camera = floatingCamera {
            floatingCamera = entityManager.find(camera.id)
        }

        // silly quick work around
        if (playing) {
            camera = floatingCamera
        } else {
            camera = overHeadCamera
        }
    }
}

struct EntityColor: LECSComponent {
    var r: Float
    var g: Float
    var b: Float
    var a: Float
    var increasing: Bool

    public init(color: ColorA, increasing: Bool = false) {
        r = color.r
        g = color.g
        b = color.b
        a = color.a
        self.increasing = increasing
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(self.r)
        try container.encode(self.g)
        try container.encode(self.b)
        try container.encode(self.a)
        try container.encode(self.increasing)
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        r = try container.decode(Float.self)
        g = try container.decode(Float.self)
        b = try container.decode(Float.self)
        a = try container.decode(Float.self)
        increasing = try container.decode(Bool.self)
    }
}
