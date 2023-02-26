import Foundation

public typealias Effect<Action> = () -> Action?
public typealias Reducer<Value, Action> = (inout Value, Action) -> [Effect<Action>]

public func combine<Value, Action>(
    _ reducers: Reducer<Value, Action>...
) -> Reducer<Value, Action> {
    return { value, action in
        let effects = reducers.flatMap { $0(&value, action) }
        return effects
    }
}

public func pullback<LocalValue, GlobalValue, LocalAction, GlobalAction>(
    _ reducer: @escaping Reducer<LocalValue, LocalAction>,
    _ value: WritableKeyPath<GlobalValue, LocalValue>,
    _ action: WritableKeyPath<GlobalAction, LocalAction?>
) -> Reducer<GlobalValue, GlobalAction> {
    return { gValue, gAction in
        guard let localAction = gAction[keyPath: action] else { return [] }
        var localValue = gValue[keyPath: value]
        let localEffects = reducer(&localValue, localAction)
        return localEffects.map { localEffect in
            return { () -> GlobalAction? in
                guard let localAction = localEffect() else { return nil }
                var globalAction = gAction
                globalAction[keyPath: action] = localAction
                return globalAction
            }
        }
    }
}
