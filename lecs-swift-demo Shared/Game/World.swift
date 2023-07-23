//
// Created by David Kanenwisher on 1/5/23.
//

import Foundation
import simd

/**
 - Going to see if I can get by with just the config from AppCore for now.
 */
struct World {
    private let config: AppCoreConfig.Game.World

    //TODO: don't commit this...
    public var entityManager: ECSEntityManager

    public var map: TileMap

    var scene: ECSSceneGraph {
        get {
            entityManager.scene
        }
    }

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
        entityManager.createToggleButton(
            id: "btn-play",
            position: F2(7.5.f, 17.5.f),
            buttonState: ECSToggleButton.State.NotToggled,
            toggledAction: {
                gameInput, ecsEntity, world in
                world.playing.toggle()
                world.map = TileMap(world.mapData, index: 0)
                for y in 0..<world.map.height {
                    for x in 0..<world.map.width {
                        let position = Float2(x: Float(x) + 0.5, y: Float(y) + 0.5) // world, in the center of the tile
                        let tile = world.map[x, y]
                        switch tile {
                        case .floor:
                            if let entity = world.entityManager.find("wall" + String(x) + String(y)) {
                                world.entityManager.remove(entity)
                            }
                            break
                        case .wall:
                            world.entityManager.createWall(
                                id: "wall" + String(x) + String(y),
                                position: position,
                                radius: 0.5,
                                camera: .world
                            )
                        }
                    }
                }
            },
            notToggledAction: { gameInput, ecsEntity, world in
                world.playing.toggle()
            }
        )

        // whole iphone 14 screen is 10 across and 20 down
        let gridWidth = 9
        let gridHeight = 9
        let horizontalStart = 7
        let totalButtons = (gridWidth * gridHeight)
        let radius = 0.5.f
        for i in 0..<totalButtons { // one less than total cuz grid starts at 0,0
            let x = i % gridWidth
            let y = (i / gridHeight)
            entityManager.createMapButton(
                id: "btn-map" + String(x) + "," + String(y),
                position: Float2(x.f + radius,  y.f + radius + horizontalStart.f),
                buttonState: mapData.tiles[x + y * mapData.width] == .floor ? .NotToggled : .Toggled,
                toggledAction: { gameInput, ecsEntity, world in
                    var tiles = world.mapData.tiles
                    tiles[x + y * world.mapData.width] = .wall
                    world.mapData = MapData(tiles: tiles, width: world.mapData.width)
                },
                notToggledAction: { gameInput, ecsEntity, world in
                    var tiles = world.mapData.tiles
                    tiles[x + y * world.mapData.width] = .floor
                    world.mapData = MapData(tiles: tiles, width: world.mapData.width)
                }
            )
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

        if (input.isTouched) {
            let position = input.touchCoordinates
                    .screenToNdc(screenWidth: input.viewWidth, screenHeight: input.viewHeight, flipY: true)
                    .ndcToWorld(camera: hudCamera!.camera!)
            let eLocation = entityManager.createProp(id: "touchLocation", position: position, radius: 0.12, camera: .hud)

            if let collision = eLocation.collision {
                if let selected = entityManager.pickCollision(at: collision) {
                    print("collided entity \(selected.id)")
                    gameInput.selectedButton = selected
                }
            }
        }

        // Update all of the entities
        entityManager.entities.forEach { entity in
            // TODO: using this until I find a better way to skip drawing a wall that's now a floor.
            if var newEntity = entityManager.find(entity.id) {
                entityManager.update(newEntity.update(input: gameInput, world: &self))
            }
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
