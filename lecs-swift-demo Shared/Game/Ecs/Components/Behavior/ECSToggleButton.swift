//
// Created by David Kanenwisher on 2/17/23.
//

import Foundation

struct ECSToggleButton: ECSComponent {
    var entityID: String
    var buttonState: State = .NotToggled
    let toggledColor: Float4 = Float4(0.0, 0.6, 0.0, 1.0)
    let notToggledColor: Float4 = Float4(0.0, 0.2, 0.0, 1.0)
    var toggledAction: ((GameInput, inout ECSEntity, inout World) -> Void)? = nil
    var notToggledAction: ((GameInput, inout ECSEntity, inout World) -> Void)? = nil

    init(entityID: String, buttonState: State = .NotToggled, toggledAction: @escaping (GameInput, inout ECSEntity, inout World) -> (), notToggledAction: @escaping (GameInput, inout ECSEntity, inout World) -> ()) {
        self.entityID = entityID
        self.buttonState = buttonState
        self.toggledAction = toggledAction
        self.notToggledAction = notToggledAction
    }

    mutating func update(input: GameInput, entity: inout ECSEntity, world: inout World) {
        if (input.selectedButton?.id == entityID) {
            switch buttonState {
            case .Toggled:
                buttonState =  .NotToggled
                if let action = notToggledAction {
                    action(input, &entity, &world)
                }
            case .NotToggled:
                buttonState = .Toggled
                if let action = toggledAction {
                    action(input, &entity, &world)
                }
            }
        }

        switch buttonState {
        case .Toggled:
            entity.graphics?.color = toggledColor
        case .NotToggled:
            entity.graphics?.color = notToggledColor
        }
    }

    public enum State {
        case NotToggled, Toggled
    }
}
