//
//  Store.swift
//  
//
//  Created by Sasikumar JP on 26/02/23.
//

import Foundation
import SwiftUI
import Combine

public class Store<Value, Action>: ObservableObject {
    @Published var value: Value
    let reducer: Reducer<Value, Action>
    var cancellable: Cancellable?
    
    public init(initialValue: Value,
                reducer: @escaping Reducer<Value, Action>) {
        self.value = initialValue
        self.reducer = reducer
    }
    
    public func send(_ action: Action) {
        let effect = reducer(&value, action)
        effect()
    }
    
    public func view<LocalValue>(
        _ f: @escaping (Value) -> LocalValue
    ) -> Store<LocalValue, Action> {
        let localStore = Store<LocalValue, Action>.init(
            initialValue: f(value),
            reducer: { localValue, action in
                self.send(action)
                localValue = f(self.value)
                return {}
            })
        localStore.cancellable = self.$value.sink(receiveValue: { [weak localStore] value in
            localStore?.value = f(value)
        })
        return localStore
    }
    
    public func view<LocalValue, LocalAction>(
        value toLocalValue: @escaping (Value) -> LocalValue,
        action toGlobalAction: @escaping (LocalAction) -> Action
    ) -> Store<LocalValue, LocalAction> {
        let localStore = Store<LocalValue, LocalAction>.init(
            initialValue: toLocalValue(value),
            reducer: { localValue, localAction in
                self.send(toGlobalAction(localAction))
                localValue = toLocalValue(self.value)
                return {}
            })
        localStore.cancellable = self.$value.sink { [weak localStore] value in
            localStore?.value = toLocalValue(value)
        }
        return localStore
    }
}
