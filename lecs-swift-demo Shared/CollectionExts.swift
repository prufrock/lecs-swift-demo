//
// Created by David Kanenwisher on 2/12/23.
//

extension Collection {
    var isNotEmpty: Bool {
        !isEmpty
    }

    /*
     If there's a value at the index return it otherwise null
     https://stackoverflow.com/a/30593673/312910
     */
    func getOrNil(_ index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
