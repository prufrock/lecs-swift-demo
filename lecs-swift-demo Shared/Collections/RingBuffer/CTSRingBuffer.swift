//
//  CTSRingBuffer.swift
//  DrawMaze iOSTests
//
//  Created by David Kanenwisher on 3/21/23.
//

import Foundation

protocol CTSRingBuffer: CustomStringConvertible, ScopeFunction {
    associatedtype Element

    var count: Int { get }

    var first: Element? { get }

    var isEmpty: Bool { get }

    var isFull: Bool { get }

    /**
     Add the element to the buffer.
     */
    func write(_ item: Element) -> Bool

    func read() -> Element?

    func toArray() -> [Element]
}

class CTSRingBufferArray<Element>: CTSRingBuffer {

    private var storage: [Element] = []
    private var readIndex = 0
    private var writeIndex = 0

    /**
     * Determine the number of readable elements by taking the difference between the current location of the `writeIndex` and the read index.
     * This can't become negative because the `writeIndex` is always larger than the `readIndex`.
     * This is possible because the modulo of the size is always used to determine the current index to read from.
     */
    private var availableSpaceForReading: Int {
        writeIndex - readIndex
    }

    /**
     * Determine how many more elements can be added by taking the difference between the size and what's available for reading.
     */
    private var availableSpaceForWriting: Int {
        size - availableSpaceForReading
    }

    var count: Int {
        availableSpaceForReading
    }

    var first: Element? {
        storage.getOrNil(readIndex)
    }

    var isEmpty: Bool {
        count == 0
    }

    var isFull: Bool {
        availableSpaceForWriting == 0
    }

    var description: String  {
        toArray().map { "\($0)"}.joined(separator: ",")
    }

    private let size: Int

    init(size: Int) {
        self.size = size
    }

    func write(_ item: Element) -> Bool {
        // Don't write if full
        if (!isFull) {
            // if storage is holding less than the size of the buffer there's room to add more elements to storage.
            if (storage.count < size) {
                storage.append(item)
            } else {
                // once storage is full reuse the position of the `writeIndex`
                // the `writeIndex` wraps around the buffer so use the modulo of the size to determine where it should write to.
                storage[writeIndex % size] = item
            }
            // move the `writeIndex` forward
            // The `writeIndex` is always increasing and the modulo is used above. Otherwise, you have to worry about values like `availableSpaceForReading` becoming negative.
            // There is a limit on the size of an Integer that will, at some point, causing the RingBuffer to break after too many writes.
            writeIndex += 1
            return true
        } else {
            return false
        }
    }

    func read() -> Element? {
        if (!isEmpty) {
            // use the modulo of the readIndex and the size since the read index goes around and around the ring buffer
            // but should always read from a value less than size.
            let element = storage[readIndex % size]
            // move the read index ahead one for the next time read is called.
            readIndex += 1
            // return the element
            return element
        } else {
            return nil
        }
    }

    func toArray() -> [Element] {
        // the read index needs to stay where it is since this is more of a debugging aid
        // that's why it goes from readIndex to the availableSpaceReading
        // where the current iteration is used as an offset
        // then it modulos the size since readIndex keeps growing unbound.
        (0..<availableSpaceForReading).map { offset -> Element in
            storage[(readIndex + offset) % size]
        }
    }
}
