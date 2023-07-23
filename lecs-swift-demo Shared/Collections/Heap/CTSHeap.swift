//
// Created by David Kanenwisher on 3/14/23.
//

import Foundation

protocol CTSHeap {
    associatedtype Element

    var isEmpty: Bool { get }

    var count: Int { get }

    func peek() -> Element?

    mutating func insert(_ element: Element)

    mutating func remove() -> Element?

    mutating func merge(_ heap: Self)
}

class CTSHeapArray<Element: Comparable>: CTSHeap {
    private var comparator: (Element, Element) -> Int

    private var elements: [Element] = []

    var isEmpty: Bool {
        elements.isEmpty
    }

    var count: Int {
        elements.count
    }

    init(comparator: @escaping (Element, Element) -> Int) {
        self.comparator = comparator
    }

    static func create(elements: [Element], comparator: @escaping (Element, Element) -> Int) -> CTSHeapArray<Element> {
        let heap = CTSHeapArray<Element>(comparator: comparator)
        heap.elements = elements
        heap.buildHeap()
        return heap
    }

    func peek() -> Element? {
        elements.first
    }

    func insert(_ element: Element) {
        // put the element at the end
        elements.append(element)
        // move it into the correct position
        siftUp(count - 1)
    }

    func remove() -> Element? {
        if isEmpty {
            return nil
        }

        // swap the first and last element
        // this ensures the array stays filled
        elements.swapAt(0, count - 1)
        // hold on to the item to return
        let item = elements.remove(at: count - 1)
        siftDown(0)

        return item
    }

    func remove(_ index: Int) -> Element? {
        // You've gone too far, time to be done
        if (index >= count) {
            return nil
        }

        if (index == count - 1) {
            // when it's the last element just remove that element and return it
            return elements.remove(at: index)
        } else {
            // for any other element swap it with the last element
            elements.swapAt(index, count - 1)
            // the remove it
            let item = elements.remove(at: count - 1)
            // adjust the swapped element down as far as it goes
            siftDown(index)
            // adjust the swapped element up as far as it goes
            siftUp(index)
            // return the removed element
            return item
        }
    }

    func merge(_ heap: CTSHeapArray<Element>) {
        elements.append(contentsOf: heap.elements)
        buildHeap()
    }

    func compare(_ lhs: Element, _ rhs: Element) -> Int {
        comparator(lhs, rhs)
    }

    /**
     * Finds the parent of the node at index.
     */
    private func parentIndex(_ index: Int) -> Int {
        (index - 1) / 2
    }

    /**
     * Finds the left child of the node at index.
     */
    private func leftChildIndex(_ index: Int) -> Int {
        (index * 2) + 1
    }

    /**
     * Finds the right child of the node at index.
     */
    private func rightChildIndex(_ index: Int) -> Int {
        (index * 2) + 2
    }

    private func siftUp(_ index: Int) {
        var child = index
        var parent = parentIndex(child)

        // remember compare uses *priority* so it can be used for both min and max heaps
        while(child > 0 && compare(elements[child], elements[parent]) > 0) {
            elements.swapAt(child, parent)
            // propagate the element up the heap
            child = parent
            parent = parentIndex(child)
        }
    }

    private func siftDown(_ index: Int) {
        var parent = index
        while(true) {
            let left = leftChildIndex(parent)
            let right = rightChildIndex(parent)
            var candidate = parent
            // if the left child has a higher priority
            // that may be the one we want to swap
            // so make it the candidate
            if (left < count && compare(elements[left], elements[candidate]) > 0) {
                candidate = left
            }
            // if the right child has a higher priority
            // then that is in fact the one we want to swap
            // it gets to be the candidate
            if (right < count && compare(elements[right], elements[candidate]) > 0) {
                candidate = right
            }
            // if they're the same well then noting to do here
            if (candidate == parent) {
                return
            }
            // swap the parent and the candidate
            // since the parent has a higher priority
            elements.swapAt(parent, candidate)
            // the parent hs moved into the candidate's position
            // so set the parent to the candidate
            // then head back to the top of the loop!
            parent = candidate
        }
    }

    private func buildHeap() {
        if (!elements.isEmpty) {
            // You only need to do half the array
            // since the sifting process ends up putting the parent nodes in the right places
            for i in stride(from: count / 2, through: 0, by: -1) {
                siftDown(i)
            }
        }
    }
}