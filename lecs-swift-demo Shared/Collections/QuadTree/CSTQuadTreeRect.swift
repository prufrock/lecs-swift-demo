//
// Created by David Kanenwisher on 2/9/23.
//

import Foundation

/**
 A quad tree that only works on points.
 */
public class CTSQuadTreeRect: CTSQuadTree {
    typealias Element = Rect

    private let boundary: Rect
    private let level: Int
    private let maxElements: Int
    private let maxLevels: Int

    private var elements: [Rect] = []
    private var partitions: [CTSQuadTreeRect] = []

    init(boundary: Rect, level: Int = 0, maxElements: Int = 10, maxLevels: Int = 5) {
        self.boundary = boundary
        self.level = level
        self.maxElements = maxElements
        self.maxLevels = maxLevels
    }

    public func insert(_ element: Rect) -> Bool {
        // if it's outside the quadtree reject it
        if (!boundary.contains(element)) {
            return false
        }

        // if the tree hasn't split yet store it here
        if (!hasSplit() && hasVacancies()) {
            elements.append(element)
            return true
        }

        // if there are no vacancies then it's time to split.
        if (!hasSplit()) {
            _ = split()
        }

        // if it doesn't fit in a partition add it to this level.
        if (partitionInsert(rect: element)) {
            return true
        } else {
            if (hasVacancies()) {
                elements.append(element)
                return true
            } else {
                return false
            }
        }
    }

    public func find(_ rect: Rect) -> [Rect] {
        var found: [Rect] = []

        // Get out early if this node can't hold the search rect
        if (!boundary.contains(rect)) {
            return found
        }

        elements.forEach { e in
            if (rect.contains(e)) {
                found.append(e)
            }
        }

        // check partitions
        partitions.forEach { partition in
            found.append(contentsOf: partition.find(rect))
        }

        return found
    }

    private func split() -> Bool {
        let (ab, cd) = boundary.divide(.horizontal)
        let (a, b) = ab.divide(.vertical)
        let (c, d) = cd.divide(.vertical)

        addPartition(boundary: a)
        addPartition(boundary: b)
        addPartition(boundary: c)
        addPartition(boundary: d)

        // redistribute elements
        let oldElements = elements

        // no reason to go through the trouble of reallocating the memory
        elements.removeAll(keepingCapacity: true)

        oldElements.forEach { rect in
            //TODO: may want to do something if this fails
            _ = insert(rect)
        }

        return true
    }

    private func partitionInsert(rect: Rect) -> Bool {
        for partition in partitions {
            if (partition.insert(rect)) {
                return true
            }
        }

        return false
    }

    private func hasVacancies() -> Bool {
        elements.count < maxElements
    }

    private func hasSplit() -> Bool {
        partitions.isNotEmpty
    }

    private func addPartition(boundary: Rect) {
        partitions.append(CTSQuadTreeRect(boundary: boundary, level: level + 1, maxElements: maxElements, maxLevels:  maxLevels))
    }
}
