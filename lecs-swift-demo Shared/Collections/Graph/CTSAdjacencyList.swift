//
// Created by David Kanenwisher on 3/22/23.
//

import Foundation

/**
 With an adjacency list the graph stores a list of outgoing edges for each vertex.
 */
class CTSAdjacencyList<Element>: CTSGraph {
    var adjacencies: [CTSVertex<Element>: [CTSEdge<Element>]] = [:]

    var allVertices: [CTSVertex<Element>] {
        Array(adjacencies.keys)
    }

    var vertices: Set<CTSVertex<Element>> {
        Set(adjacencies.keys)
    }

    var description: String {
        adjacencies.map { (vertex, edges) in
            let edgeString = edges.map { (edge: CTSEdge<Element>) -> String in
                    "\(edge.destination.data)"
            }.joined(separator: ", ")

            return "\(vertex.data):  ---> [\(edgeString)]"
        }.joined(separator: "\n")
    }

    func createVertex(data: Element) -> CTSVertex<Element> {
        // create the vertex with it's place in the adjacency list and the data
        let vertex = CTSVertex(index: adjacencies.count, data: data)
        // store the vertex in the adjacency list with a fresh list for its outgoing edges
        adjacencies[vertex] = []
        return vertex
    }

    func addDirectedEdge(from source: CTSVertex<Element>, to destination: CTSVertex<Element>, weight: Double?) {
        // create a new edge
        let edge = CTSEdge(source: source, destination: destination, weight: weight)
        // add it to the adjacency list for the vertex
        adjacencies[source]?.append(edge)
    }

    func edges(_ source: CTSVertex<Element>) -> [CTSEdge<Element>] {
        adjacencies[source] ?? []
    }

    func weight(from source: CTSVertex<Element>, to destination: CTSVertex<Element>) -> Double? {
        edges(source).first { $0.destination == destination }?.weight
    }
}