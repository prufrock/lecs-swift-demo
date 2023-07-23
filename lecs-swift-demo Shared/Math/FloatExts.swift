//
//  FloatExts.swift
//  DrawMaze
//
//  Created by David Kanenwisher on 1/3/23.
//

import Foundation

extension Float {
    func roundDown() -> Int {
        var value = self
        value.round(.down)
        return Int(value)
    }

    func toRadians() -> Float {
        self * (.pi / 180)
    }
}
