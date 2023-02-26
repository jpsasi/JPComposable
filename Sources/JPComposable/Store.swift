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
    let reducer: (inout Value, Action) -> Void
    var cancellable: Cancellable?
    
    public init(initialValue: Value,
                reducer: @escaping (inout Value, Action) -> Void) {
        self.value = initialValue
        self.reducer = reducer
    }
    
    public func send(_ action: Action) {
        reducer(&value, action)
    }
    
    public func view<LocalValue>(
        _ f: @escaping (Value) -> LocalValue
    ) -> Store<LocalValue, Action> {
        let localStore = Store<LocalValue, Action>.init(
            initialValue: f(value),
            reducer: { localValue, action in
                self.send(action)
                self.reducer(&self.value, action)
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
            })
        localStore.cancellable = self.$value.sink { [weak localStore] value in
            localStore?.value = toLocalValue(value)
        }
        return localStore
    }
}
