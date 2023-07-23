//
// Created by David Kanenwisher on 3/13/23.
//

import Foundation

protocol CTSQueue: CustomStringConvertible, ScopeFunction {
    associatedtype T

    var isEmpty: Bool { get }

    var count: Int { get }

    /**
     * Add an element at the back of the queue.
     */
    mutating func enqueue(_ item: T) -> Bool

    /**
    * Remove an element from the front of the queue.
    */
    func dequeue() -> T?

    /**
    * Return the element at the front of the queue without removing it.
    */
    func peek() -> T?

    /**
     * Return the elements of the queue as an array.
     */
     func toArray() -> [T]
}

class CTSQueueArray<T>: CTSQueue {
    var description: String {
        storage.map { "\($0)" }.joined(separator: ", ")
    }

    private var storage: [T] = []

    var count: Int {
        storage.count
    }

    var isEmpty: Bool {
        storage.isEmpty
    }

    @discardableResult
    func enqueue(_ item: T) -> Bool {
        storage.append(item)
        return true
    }

    func dequeue() -> T? {
        guard !isEmpty else {
            return nil
        }

        return storage.removeFirst()
    }

    func peek() -> T? {
        storage.first
    }

    func toArray() -> [T] {
        storage
    }
}
