//
// Created by David Kanenwisher on 1/5/23.
//

import Foundation

struct Input {
    var speed: Float
    var rotation: Float2x2
    var rotation3d: Float4x4
    var timeStep: Float = 0.0
    var isTouched: Bool
    var touchCoordinates: Float2
    var viewWidth: Float
    var viewHeight: Float
    var aspect: Float
}