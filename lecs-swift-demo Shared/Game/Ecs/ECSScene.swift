//
// Created by David Kanenwisher on 2/16/23.
//

import Foundation

protocol ECSScene: Sequence<ECSGraphics>  {

    mutating func addChild(data: ECSGraphics)
}

struct ECSSceneGraph: ECSScene {
    // one day it'll be a graph
    var list: [ECSGraphics] = []

    mutating func addChild(data: ECSGraphics) {
        list.append(data)
    }

    func makeIterator() -> ECSSceneGraphIterator {
        ECSSceneGraphIterator(list)
    }
}

struct ECSSceneGraphIterator:IteratorProtocol {
    var index = 0
    let list: [ECSGraphics]

    init(_ list: [ECSGraphics]) {
        self.list = list
    }

    mutating func next() -> ECSGraphics? {
        guard index < list.count else {
            return nil
        }

        let i = index
        index += 1

        return list[i]
    }
}
