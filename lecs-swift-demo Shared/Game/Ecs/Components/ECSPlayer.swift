//
// Created by David Kanenwisher on 3/28/23.
//

import Foundation

struct ECSPlayer {
    var position3d: F3 = F3(0.0, 0.0, 0.0)
    var rotation2d = Float2(0.0,-1.0)
    var rotation3d = Float4x4.identity()
    var speed: Float = 0
}
