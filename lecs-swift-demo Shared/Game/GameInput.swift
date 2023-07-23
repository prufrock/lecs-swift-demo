//
// Created by David Kanenwisher on 1/5/23.
//

import Foundation

struct GameInput {
    let externalInput: Input
    var selectedButtonId: String?
    var selectedButton: ECSEntity?
    var play: Bool = false
    var floors: Set = Set<String>()
}