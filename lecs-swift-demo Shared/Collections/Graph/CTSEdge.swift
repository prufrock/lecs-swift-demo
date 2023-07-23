//
// Created by David Kanenwisher on 3/22/23.
//

import Foundation

class CTSEdge<T> {
    var source: CTSVertex<T>
    var destination: CTSVertex<T>
    var weight: Double?

    init(source: CTSVertex<T>, destination: CTSVertex<T>, weight: Double? = nil) {
        self.source = source
        self.destination = destination
        self.weight = weight
    }
}