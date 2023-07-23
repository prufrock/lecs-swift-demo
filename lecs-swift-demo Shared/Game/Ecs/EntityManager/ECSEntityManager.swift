//
// Created by David Kanenwisher on 2/14/23.
//

import Foundation

protocol ECSEntityManager {
    var entities: [ECSEntity] { get }

    // one day it will be a graph
    var scene: ECSSceneGraph { get }

    @discardableResult
    mutating func createDecoration(id: String, position: Float2) -> ECSEntity

    @discardableResult
    mutating func createToggleButton(id: String, position: Float2) -> ECSEntity

    @discardableResult
    mutating func createToggleButton(id: String, position: Float2, buttonState: ECSToggleButton.State, toggledAction: @escaping (GameInput, inout ECSEntity, inout World) -> Void, notToggledAction: @escaping (GameInput, inout ECSEntity, inout World) -> Void) -> ECSEntity

    @discardableResult
    mutating func createMapButton(id: String, position: Float2, buttonState: ECSMapButton.State, toggledAction: @escaping (GameInput, inout ECSEntity, inout World) -> Void, notToggledAction: @escaping (GameInput, inout ECSEntity, inout World) -> Void) -> ECSEntity

    @discardableResult
    mutating func createProp(id: String, position: Float2, radius: Float, camera: ECSGraphics.Camera) -> ECSEntity

    @discardableResult
    mutating func createWall(id: String, position: Float2, radius: Float, camera: ECSGraphics.Camera) -> ECSEntity

    @discardableResult
    mutating func createCamera(id: String, initialAspectRatio: Float, speed: Float, position3d: F3, baseWorldToView: @escaping (ECSCamera) -> Float4x4) -> ECSEntity

    @discardableResult
    mutating func createPlayer(id: String, initialAspectRatio: Float, speed: Float, position3d: F3, radius: Float, baseWorldToView: @escaping (ECSCamera) -> Float4x4) -> ECSEntity

    //MARK: Entity Table

    func find(_ entityId: String) -> ECSEntity?

    mutating func update(_: ECSEntity)

    mutating func remove(_: ECSEntity)

    //MARK: Collision Table

    @discardableResult
    func collides(with rect: Rect, prefix: String) -> [ECSCollision]

    func pickCollision(at location: ECSCollision) -> ECSEntity?
}
