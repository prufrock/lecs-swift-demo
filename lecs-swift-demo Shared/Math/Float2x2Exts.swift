//
// Created by David Kanenwisher on 1/4/23.
//

import Foundation
import simd

public typealias Float2x2 = simd_float2x2

public extension Float2x2 {

    static func identity() -> Self {
        matrix_identity_float2x2
    }

    static func rotate(_ angle: Float) -> Self {
        Self(
            [ cos(angle), sin(angle)],
            [-sin(angle), cos(angle)]
        )
    }

    static func rotate(sine: Float, cosine: Float) -> Self {
        Self(
            [ cosine, sine],
            [-sine, cosine]
        )
    }

    static func scale(x: Float, y: Float) -> Self {
        Self(
            [x, 0],
            [0, y]
        )
    }
}
