//
//  Functions.swift
//  
//
//  Created by Sasikumar JP on 26/02/23.
//

import Foundation

func combine<Value, Action>(
    _ reducers: (inout Value, Action) -> Void...
) -> (inout Value, Action) -> Void {
    return { value, action in
        for reducer in reducers {
            reducer(&value, action)
        }
    }
}

func pullback<LocalValue, GlobalValue, LocalAction, GlobalAction>(
    _ reducer: @escaping (inout LocalValue, LocalAction) -> Void,
    _ value: WritableKeyPath<GlobalValue, LocalValue>,
    _ action: WritableKeyPath<GlobalAction, LocalAction?>
) -> (inout GlobalValue, GlobalAction) -> Void {
    return { gValue, gAction in
        guard let localAction = gAction[keyPath: action] else { return }
        var localValue = gValue[keyPath: value]
        reducer(&localValue, localAction)
    }
}
