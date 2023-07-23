//
// Created by David Kanenwisher on 3/22/23.
//

import Foundation

protocol CTSGraph: CustomStringConvertible, ScopeFunction {
    associatedtype Element

    var allVertices: [CTSVertex<Element>] { get }

    var description: String { get }

    func createVertex(data: Element) -> CTSVertex<Element>

    func addDirectedEdge(from source: CTSVertex<Element>, to destination: CTSVertex<Element>, weight: Double?)

    func addUndirectedEdge(between source: CTSVertex<Element>, and destination: CTSVertex<Element>, weight: Double?)

    func weight(from source: CTSVertex<Element>, to destination: CTSVertex<Element>) -> Double?

    func edges(_ source: CTSVertex<Element>) -> [CTSEdge<Element>]

//    func depthFirstSearch(from source: CTSVertex<Element>) -> [CTSVertex<Element>]

//    func breadthFirstSearch(from source: CTSVertex<Element>) -> [CTSVertex<Element>]
}

extension CTSGraph {
    func addUndirectedEdge(between source: CTSVertex<Element>, and destination: CTSVertex<Element>, weight: Double?) {
        addDirectedEdge(from: source, to: destination, weight: weight)
        addDirectedEdge(from: destination, to: source, weight: weight)
    }

    func add(edgeType: EdgeType, from source: CTSVertex<Element>, to destination: CTSVertex<Element>, weight: Double?) {
        switch edgeType {
        case .directed:
            addDirectedEdge(from: source, to: destination, weight: weight)
        case .undirected:
            addUndirectedEdge(between: source, and: destination, weight: weight)
        }
    }

    func breadthFirstTraversal(source: CTSVertex<Element>, visitor: Visitor<Element>) {
        // tracks the vertices to visit next
        let queue = CTSQueueArray<CTSVertex<Element>>()
        // ensures vertices are only visited once
        var enqueued: Set<CTSVertex<Element>> = []

        // get the BFS part started by enqueueing the starting vertex
        queue.enqueue(source)
        // add it to the set of enqueued vertices, so it isn't visited again
        enqueued.insert(source)

        while(true) {
            // as long as there are items to dequeue keep going
            guard let vertex = queue.dequeue() else {
                break
            }

            // do something with the vertex
            visitor(vertex)
            // queue up all the neighbors that haven't been queued before
            let neighborsEdges = edges(vertex)
            neighborsEdges.forEach { edge in
                if !enqueued.contains(edge.destination) {
                    queue.enqueue(edge.destination)
                    enqueued.insert(edge.destination)
                }
            }
        }
    }

    func breadthFirstTraversalRecursive(source: CTSVertex<Element>, visitor: Visitor<Element>) {
        let vertexQueue = CTSStackQueue<CTSVertex<Element>>()
        var enqueued: Set<CTSVertex<Element>> = []

        vertexQueue.enqueue(source)
        enqueued.insert(source)

        breadthFirstTraversalRecursive(vertexQueue: vertexQueue, enqueued: &enqueued, visitor: visitor)
    }

    private func breadthFirstTraversalRecursive(
        vertexQueue: CTSStackQueue<CTSVertex<Element>>,
        enqueued: inout Set<CTSVertex<Element>>,
        visitor: Visitor<Element>) {

        // avoid passing the current vertex as an argument and clear it from the queue before processing neighbors
        guard let vertex = vertexQueue.dequeue() else {
            return
        }

        // process the vertex
        visitor(vertex)

        // add all this node's unvisited neighbors
        edges(vertex).forEach { edge in
            if !enqueued.contains(edge.destination) {
                vertexQueue.enqueue(edge.destination)
                // Don't forget to add it to `enqueued` so it isn't visited again
                enqueued.insert(edge.destination)
            }
        }

        // go back around again
        breadthFirstTraversalRecursive(vertexQueue: vertexQueue, enqueued: &enqueued, visitor: visitor)
    }

    func breadthFirstSort(source: CTSVertex<Element>) -> [CTSVertex<Element>] {
        var sorted: [CTSVertex<Element>] = []
        breadthFirstTraversal(source: source) { vertex in
            sorted.append(vertex)
        }

        return sorted
    }

    func isDisconnected(source: CTSVertex<Element>) -> Bool {
        var sourceVertices: Set<CTSVertex<Element>> = []
        breadthFirstTraversal(source: source) { vertex in
            sourceVertices.insert(vertex)
        }

        return sourceVertices.count != allVertices.count
    }

    /**
     Search a graph depth first: start at a vertex and follow edges to the furthest connected vertex then work backward.
     Time complexity: O(V+E)
     Space complexity: O(V)
     */
    func depthFirstSearch(source: CTSVertex<Element>, visit: Visitor<Element>) {
        // Store the vertices that need to be processed
        let stack = CTSStackArray<CTSVertex<Element>>()
        // Track the vertices already added to the stack to avoid adding them again
        // Vertices are only added to this unlike the stack where they are removed as well.
        var pushed: Set<CTSVertex<Element>> = []

        // Get the party started with the source vertex.
        stack.push(source)
        pushed.insert(source)
        // visit before adding neighbors, pre-order traversal?
        visit(source)

        while(true) {
            // stop if there's nothing left to process.
            if (stack.isEmpty) {
                break
            }

            // grab the first vertex but don't pop until all of the neighbors have been processed.
            // this is important as we climb down the tree
            let vertex = stack.peek()!
            let neighbors = edges(vertex)
            var pushedDestination = false

            // if it has no neighbors pop it
            if neighbors.isEmpty {
                stack.pop()
                continue
            }

            // Visit each one and add each to the stack.
            for neighbor in neighbors {
                let destination = neighbor.destination
                // only check a vertex if it hasn't been checked yet
                if !pushed.contains(destination) {
                    stack.push(destination)
                    pushed.insert(destination)
                    visit(destination)
                    pushedDestination = true
                    break
                }
            }
            if pushedDestination {
                continue
            }
            // Pop after all the neighbors have been processed.
            stack.pop()
        }
    }

    func depthFirstSearchRecursive(source: CTSVertex<Element>, pushed: inout Set<CTSVertex<Element>>, visit: Visitor<Element>) {
        // since this is recursive simply calling the function pushes the vertex onto the call stack so a `stack` isn't needed.
        pushed.insert(source)

        // process the vertex
        visit(source)

        // Grab it's neighbors
        let neighbors = edges(source)

        // If no neighbors backtrack!
        if (neighbors.isEmpty) {
            return
        }

        // Search the neighbors unless they have already been visited
        neighbors.forEach { edge in
            if (!pushed.contains(edge.destination)) {
                depthFirstSearchRecursive(source: edge.destination, pushed: &pushed, visit: visit)
            }
        }

        // Backtrack after processing all the neighbors
        return
    }

    func topSort() -> [CTSVertex<Element>] {
        var ordered: [CTSVertex<Element>] = []
        var pushed: Set<CTSVertex<Element>> = []

        allVertices.forEach { source in
            if (!pushed.contains(source)) {
                depthFirstSearchRecursiveVisitBackTrack(source: source, pushed: &pushed, visit: { vertex in
                    ordered.append(vertex)
                })
            }
        }

        return ordered.reversed()
    }

    private func depthFirstSearchRecursiveVisitBackTrack(source: CTSVertex<Element>, pushed: inout Set<CTSVertex<Element>>, visit: Visitor<Element>) {
        // since this is recursive simply calling the function pushes the vertex onto the call stack so a `stack` isn't needed.
        pushed.insert(source)


        // Grab it's neighbors
        let neighbors = edges(source)

        // Search the neighbors unless they have already been visited
        neighbors.forEach { edge in
            if (!pushed.contains(edge.destination)) {
                depthFirstSearchRecursiveVisitBackTrack(source: edge.destination, pushed: &pushed, visit: visit)
            }
        }

        // Backtrack after processing all the neighbors
        visit(source)
        return
    }
}

enum EdgeType {
    case directed
    case undirected
}

typealias Visitor<T> = (CTSVertex<T>) -> Void
