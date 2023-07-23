//
// Created by David Kanenwisher on 2/4/23.
//

import Foundation

protocol CTSQuadTree {
    associatedtype Element
    func insert(_ element: Element) -> Bool
    func find(_ rect: Rect) -> [Element]
}