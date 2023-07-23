//
//  Float2Exts.swift
//  DrawMaze
//
//  Created by David Kanenwisher on 1/3/23.
//

import Foundation
import simd

public typealias Float2 = SIMD2<Float>
public typealias F2 = Float2

public extension Float2 {
    var length: Float {
        (x * x + y * y).squareRoot()
    }

    var orthogonal: Self {
        Float2(x: -y, y: x)
    }

    var f3: Float3 {
        toFloat3()
    }

    init(_ x: Int, _ y: Int) {
        self.init(Float(x), Float(y))
    }

    init(_ x: Float) {
        self.init(x, x)
    }

    func toFloat3() -> Float3 {
        Float3(self)
    }

    func rotated(by rotation: Float2x2) -> Self {
        rotation * self
    }

    func toTranslation() -> Float4x4 {
        Float4x4.translate(x: x, y: y, z: 0.0)
    }

    /**
     Converts from screen to NDC.
     - Parameters:
       - screenWidth: The width of the screen that corresponds with the coordinates.
       - screenHeight: The height of the screen that corresponds with the coordinates.
       - flipY: macOS has an origin in the lower left while iOS has the origin in the upper right so you need to flip y.
     - Returns:
     */
    func screenToNdc(screenWidth: Float, screenHeight: Float, flipY: Bool = true) -> Float2 {
        // divide position.x by the screenWidth so number varies between 0 and 1
        // multiply that by 2 so that it varies between 0 and 2
        // subtract 1 because NDC x increases as you go to the right and this moves the value between -1 and 1.
        // remember the abs(-1 - 1) = 2 so multiplying by 2 is important
        let x = ((x / screenWidth) * 2) - 1
        // converting position.y is like converting position.x
        // multiply by -1 when flipY is set because on iOS the origin is in the upper left
        let y = (flipY ? -1 : 1) * (((y / screenHeight) * 2) - 1)
        // print("click screen:", String(format: "%.8f, %.8f", self.x, self.y))
        // print("click NDC:", String(format: "%.8f, %.8f", x, y))
        return Float2(x, y) // ndc space
    }

    /**
     Converts NDC space to world space
     - Parameters:
       - camera:  The camera to convert the point through.
     - Returns:
     */
    func ndcToWorld(camera: ECSCamera) -> Float2 {
        // Invert the Camera so that the position can go from NDC space to world space.
        let position4 = (camera.projection()).inverse * Float4(position: self)
        // print("ndc world:", String(format: "%.8f, %.8f, %.8f, %.8f", ndc.x, ndc.y, ndc.z, ndc.w))
        // print("click world:", String(format: "%.8f, %.8f, %.8f, %.8f", position4.x, position4.y, position4.z, position4.w))
        return Float2(position4.x, position4.y) // world space
    }
}
