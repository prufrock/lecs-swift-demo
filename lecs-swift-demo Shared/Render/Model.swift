//
// Created by David Kanenwisher on 1/7/23.
//

import Metal

protocol Model {
    var v: [F3] {get}
    var primitiveType: MTLPrimitiveType {get}
}

struct Dot: Model {
    let v: [F3] = [F3(0.0, 0.0, 0.0)] // model space
    let primitiveType: MTLPrimitiveType = .point
}

struct Square: Model {
    let v: [F3] = [ // model space
        // first triangle
        F3(-1, 1, 0), F3(1,1,0), F3(1, -1, 0), F3(-1, 1, 0),
        // second triangle
        F3(1, -1, 0),  F3(-1,-1,0), F3(1, -1, 0),
    ]
    let primitiveType: MTLPrimitiveType = .triangle
}

struct WireframeSquare: Model {
    let v: [F3] = [ // model space
        // first triangle
        F3(-1, 1, 0), F3(1, 1, 0), F3(1, 1, 0), F3(1, -1, 0), F3(1, -1, 0), F3(-1, 1, 0),
        // second triangle
        F3(1, -1, 0), F3(-1, -1, 0), F3(-1, -1, 0), F3(-1, 1, 0), F3(-1, 1, 0), F3(1, -1, 0),
    ]
    let primitiveType: MTLPrimitiveType = .line
}

public enum BasicModels {
    case dot, square, wfSquare
}
