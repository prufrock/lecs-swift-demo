//
// Created by David Kanenwisher on 2/9/23.
//

import Foundation

/**
 A quad tree that only works on points.
 */
public class CTSQuadTreePoint: CTSQuadTree {
    typealias Element = Float2

    // node capacity
    private var capacity = 4

    // points in this quad tree node
    private var points: [Float2] = []

    // partitions of 2D space
    private var nodes: [CTSQuadTreePoint] = []

    private var boundary: Rect

    private var level: Int

    public init(boundary: Rect, level: Int = 0) {
        self.boundary = boundary
        self.level = level
    }

    public func insert(_ element: Float2) -> Bool {
        // it it's outside the quadtree reject it
        if !boundary.contains(element) {
            return false
        }

        if hasVacancies() && !divided() {
            points.append(element)
            return true
        }

        if !divided() {
            _ = subDivide()
        }

        var inserted = false
        var treeIterator = nodes.makeIterator()
        while let tree = treeIterator.next(), inserted == false {
            inserted = tree.insert(element)
        }

        return inserted
    }

    public func find(_ rect: Rect) -> [Float2] {
        var found: [Float2] = []

        // Look, if the rect doesn't intersect with the boundary, what are we evening doing here?
        if boundary.intersection(with: rect) == nil {
            return found
        }

        // Check the points in this node
        if !points.isEmpty {
            points.forEach { point in
                if rect.contains(point) {
                    found.append(point)
                }
            }
        }

        // No more partitions to check then head home
        if !divided() {
            return found
        }

        // Check with the partitions
        nodes.forEach { tree in
            found.append(contentsOf: tree.find(rect))
        }

        return found
    }

    private func hasVacancies() -> Bool {
        points.count < capacity
    }

    private func divided() -> Bool {
        !nodes.isEmpty
    }

    private func subDivide() -> Bool {
        let (ab, cd) = boundary.divide(.horizontal)
        let (a, b) = ab.divide(.vertical)
        let (c, d) = cd.divide(.vertical)

        nodes.append(CTSQuadTreePoint(boundary: a, level: level + 1))
        nodes.append(CTSQuadTreePoint(boundary: b, level: level + 1))
        nodes.append(CTSQuadTreePoint(boundary: c, level: level + 1))
        nodes.append(CTSQuadTreePoint(boundary: d, level: level + 1))

        //TODO: Consider checking when they get too small
        return true
    }
}