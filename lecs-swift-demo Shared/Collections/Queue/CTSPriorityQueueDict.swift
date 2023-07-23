//
// Created by David Kanenwisher on 3/13/23.
//

import Foundation

/**
 * This priority queue considers the lowest number to be the highest priority.
 */
class CTSPriorityQueueDict<T>: ScopeFunction {
    private var storage: [Int :[T]] = [:]

    var count: Int {
        var size = 0
        storage.keys.forEach { size = size + (storage[$0]?.count ?? 0) }

        return size
    }

    func isEmpty() -> Bool {
        storage.isEmpty
    }

    @discardableResult
    func push(_ item: T, priority: Int = 1) -> Self {
        var list = storage[priority] ?? []

        list.append(item)

        storage[priority] =  list

        return self
    }

    func pop() -> T? {
        guard !isEmpty() else {
            return nil
        }

        if let lowestPriority = storage.keys.min() {
            if let list = storage[lowestPriority] {
                // if there's only one element in the list remove the key
                if list.count == 1 {
                    storage.removeValue(forKey: lowestPriority)
                } else {
                    // dropFirst returns a subsequence so convert it to an array
                    storage[lowestPriority] = list.dropFirst().toArray()
                }

                return list.first
            }
        }

        return nil
    }
}

extension CTSPriorityQueueDict: CustomStringConvertible {
    var description: String {
        storage.map { "\($0.key) => \($0.value)" }.joined(separator: ", ")
    }
}

extension Collection {
    func toArray() -> [Element] {
        Array(self)
    }
}
