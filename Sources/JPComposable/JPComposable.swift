import Foundation

public typealias Effect = () -> Void
public typealias Reducer<Value, Action> = (inout Value, Action) -> Effect

public func combine<Value, Action>(
    _ reducers: Reducer<Value, Action>...
) -> Reducer<Value, Action> {
    return { value, action in
        var effects:[Effect] = []
        for reducer in reducers {
            let effect = reducer(&value, action)
            effects.append(effect)
        }
        return {
            for effect in effects {
                effect()
            }
        }
    }
}

public func pullback<LocalValue, GlobalValue, LocalAction, GlobalAction>(
    _ reducer: @escaping Reducer<LocalValue, LocalAction>,
    _ value: WritableKeyPath<GlobalValue, LocalValue>,
    _ action: WritableKeyPath<GlobalAction, LocalAction?>
) -> Reducer<GlobalValue, GlobalAction> {
    return { gValue, gAction in
        guard let localAction = gAction[keyPath: action] else { return {}}
        var localValue = gValue[keyPath: value]
        let effect = reducer(&localValue, localAction)
        return effect
    }
}
