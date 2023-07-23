//
// Created by David Kanenwisher on 1/4/23.
//

import Foundation
import simd

public typealias Float3x3 = simd_float3x3

public extension Float3x3 {
    static func scale(x: Float, y: Float, z: Float = 1.0) -> Self {
        Self(
            [x, 0, 0],
            [0, y, 0],
            [0, 0, z]
        )
    }

    static func translate(x: Float, y: Float, z: Float = 1.0) -> Self {
        Self(
            [1, 0, 0],
            [0, 1, 0],
            [x, y, z]
        )
    }
}