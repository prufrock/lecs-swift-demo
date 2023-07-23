//
// Created by David Kanenwisher on 1/5/23.
//

import Foundation

public struct TileMap {
    private(set) var tiles: [Tile]
    let width: Int
    var height: Int {
        tiles.count / width
    }
    var size: Float2 {
        return Float2(x: Float(width), y: Float(height))
    }

    // for switching between levels
    let index: Int

    init(_ map: MapData, index: Int) {
        tiles = map.tiles
        width = map.width
        self.index = index
    }

    subscript(x: Int, y: Int) -> Tile {
        get { tiles[y * width + x] }
    }

    func getOrNil(x: Int, y: Int) -> Tile? {
        let index = y * width + x
        if x >= width || y >= height || index < 0 {
            return nil
        } else {
            return tiles[index]
        }
    }
}
