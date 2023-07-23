//
// Created by David Kanenwisher on 3/11/23.
//

import Foundation

protocol CTSStack: CustomStringConvertible, ScopeFunction {
    associatedtype T
    var count: Int { get }
    var isEmpty: Bool { get }
    func push(_ item: T)
    func pop() -> T?
    func peek() -> T?
    func toArray() -> [T]
}

class CTSStackArray<T>: CTSStack {
    // holds the data
    // going to treat the end of the list as the top of the stack
    // this make pushing and popping O(1)
    private var storage: [T] = []

    var description: String {
        storage.reversed().map { "\($0)" }.joined(separator: ", ")
    }

    var count: Int {
        storage.count
    }

    var isEmpty: Bool {
        get {
            storage.isEmpty
        }
    }

    func push(_ item: T) {
        storage.append(item)
    }

    func pop() -> T? {
        if (isEmpty) {
            return nil
        }

        return storage.removeLast()
    }

    func toArray() -> [T] {
        storage.reversed()
    }

    func peek() -> T? {
        storage.last
    }
}
