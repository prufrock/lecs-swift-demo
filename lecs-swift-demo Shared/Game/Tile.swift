//
// Created by David Kanenwisher on 1/5/23.
//

import Foundation

enum Tile: Int, Decodable, CaseIterable {
    // Floors
    case floor = 0

    // Walls
    case wall = 1

    var isWall: Bool {
        switch self {
        case .wall:
            return true
        case .floor:
            return false
        }
    }
}
