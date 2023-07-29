//
// Created by David Kanenwisher on 1/5/23.
//

import Foundation
import simd
import lecs_swift
import os.log

/**
 - Going to see if I can get by with just the config from AppCore for now.
 */
struct World {
    let signpostID: OSSignpostID
    let pointsOfInterest = OSLog(subsystem: "com.dkanen.lecs-swift-demo", category: .pointsOfInterest)
    let signposter: OSSignposter

    // the entity manager only needs to update one to get the camera situated
    private var entityManagerUpdated = false
    public let useEcs: Bool
    private let entityCount: Int

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
        self.signposter = OSSignposter()
        self.signpostID = signposter.makeSignpostID(from: pointsOfInterest)

        self.config = config
        self.useEcs = config.useEcs
        self.entityCount = config.entityCount
        self.map = map
        self.entityManager = ECSBigObjectEntityManager()
        self.entities = Array<[LECSComponent]>(repeating: [
                LECSId(id: 0),
                LECSName(name: ""),
                LECSPosition2d(x: 0, y: 0),
                LECSVelocity2d(x: 0, y: 0)
            ], count: self.entityCount)


        ecs = LECSWorldFixedSize(archetypeSize: self.entityCount)
        if useEcs {
            for i in 0..<self.entityCount {
                let b = try! ecs.createEntity("b\(i)")
                let column = Float.random(in: 0..<19)
                let row = Float.random(in: 0..<19) + 0.5
                try! ecs.addComponent(b, LECSPosition2d(x: column, y: row))
                try! ecs.addComponent(b, LECSVelocity2d(x: Float.random(in: -0.01..<0.01), y: Float.random(in: -0.01..<0.01)))
                let color = ColorA(Color.red)
                try! ecs.addComponent(b, EntityColor(color: color))
            }
        } else {
            for i in 0..<self.entityCount {
                let column = Float.random(in: 0..<19)
                let row = Float.random(in: 0..<19) + 0.5
                let id = LECSId(id: UInt(i))
                let name = LECSName(name: "b\(i)")
                let position = LECSPosition2d(x: column, y: row)
                let velocity = LECSVelocity2d(x: Float.random(in: -0.01..<0.01), y: Float.random(in: -0.01..<0.01))
                entities[i][0] = id
                entities[i][1] = name
                entities[i][2] = position
                entities[i][3] = velocity
            }
        }

        updatePositionSystem = ecs.addSystem(
            "UpdatePosition",
            selector: [LECSPosition2d.self, LECSVelocity2d.self]) { world, components, columns in
                var position = components[columns[0]] as! LECSPosition2d
                var velocity = components[columns[1]] as! LECSVelocity2d

                position.x = position.x + velocity.velocity.x
                if position.x > 9 {
                    velocity.velocity = Float2(-1 * velocity.velocity.x, velocity.velocity.y)
                } else if position.x < 0 {
                    velocity.velocity = Float2(-1 * velocity.velocity.x, velocity.velocity.y)
                }

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
            selector: [EntityColor.self]) { world, components, columns in
                var color = components[columns[0]] as! EntityColor

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

            position.x = position.x + velocity.velocity.x
            if position.x > 9 {
                velocity.velocity = Float2(-1 * velocity.velocity.x, velocity.velocity.y)
            } else if position.x < 0 {
                velocity.velocity = Float2(-1 * velocity.velocity.x, velocity.velocity.y)
            }

            position.y = position.y + velocity.velocity.y
            if position.y > 20 {
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

        if (useEcs) {
            os_signpost(.begin, log: pointsOfInterest, name: "process ecs", signpostID: signpostID)
            ecs.process(system: updatePositionSystem)
            //ecs.process(system: updateColorSystem)
            os_signpost(.end, log: pointsOfInterest, name: "process ecs", signpostID: signpostID)
        } else {
            os_signpost(.begin, log: pointsOfInterest, name: "process arrays", signpostID: signpostID)
            for i in 0..<(entities.count) {
                let updated = entitiesUpdatePositionSystem([entities[i][2], entities[i][3]])
                entities[i][2] = updated[0]
                entities[i][3] = updated[1]
            }
            os_signpost(.end, log: pointsOfInterest, name: "process arrays", signpostID: signpostID)
        }

        // Update all of the entities
        if !entityManagerUpdated {
            entityManager.entities.forEach { entity in
                // TODO: using this until I find a better way to skip drawing a wall that's now a floor.
                if var newEntity = entityManager.find(entity.id) {
                    entityManager.update(newEntity.update(input: gameInput, world: &self))
                }
            }
            entityManagerUpdated = true
        }

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

    public init() {
        r = 0
        g = 0
        b = 0
        a = 0
        self.increasing = false
    }

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
