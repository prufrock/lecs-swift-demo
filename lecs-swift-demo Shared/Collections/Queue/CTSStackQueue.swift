//
// Created by David Kanenwisher on 3/21/23.
//

import Foundation

class CTSStackQueue<T>: CTSQueue {
    private var leftStack = CTSStackArray<T>()
    private var rightStack = CTSStackArray<T>()

    var count: Int {
        get {
            leftStack.count + rightStack.count
        }
    }

    var description: String {
        get {
            "Left stack: \n$leftStack \n Right stack: \n$rightStack"
        }
    }

    var isEmpty: Bool {
        get {
            leftStack.isEmpty && rightStack.isEmpty
        }
    }

    /**
     O(1)
     */
    @discardableResult
    func enqueue(_ item: T) -> Bool {
        rightStack.push(item)
        return true
    }

    /**
     O(1) amortized
     */
    func dequeue() -> T? {
        // if it's empty move the elements to the left stack.
        // this reverses the stack and makes it simple to access the bottom of the right stack.
        if (leftStack.isEmpty) {
            transferElements()
        }
        return leftStack.pop()
    }

    /**
     * Amortized O(1) because `transferElements()` is O(n) but each element in the queue only has to be moved once so future calls are O(1).
     */
    func peek() -> T? {
        // If there aren't any elements in the left stack move them over
        if (leftStack.isEmpty) {
            transferElements()
        }
        return leftStack.peek()
    }

    func toArray() -> [T] {
        leftStack.toArray() + rightStack.toArray().reversed()
    }

    /**
     * Moves the elements from the right stack to the left stack.
     * O(n)
     */
    private func transferElements() {
        var nextElement = rightStack.pop()
        while(nextElement != nil) {
            // Is there a better way to unwrap this optional?
            leftStack.push(nextElement!)
            nextElement = rightStack.pop()
        }
    }
}
