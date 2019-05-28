//
//  Scope.swift
//  LogicDesigner
//
//  Created by Devin Abbott on 5/16/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

public struct ScopeStack<Key: Hashable, Value> {
    public typealias Scope = [Key: Value]

    // MARK: Lifecycle

    public init(_ rootScope: Scope = Scope()) {
        self.scopes = [rootScope]
    }

    // MARK: Private

    private var scopes: [Scope]

    // MARK: Public

    public var flattened: Scope {
        return scopes.reduce(Scope(), { (result, scope) -> Scope in
            return result.merging(scope, uniquingKeysWith: { (current, new) -> Value in
                return current
            })
        })
    }

    public func value(for key: Key) -> Value? {
        for scope in scopes.reversed() {
            if let value = scope[key] {
                return value
            }
        }

        return nil
    }

    public mutating func set(_ value: Value, for key: Key) {
        self.scopes[self.scopes.count - 1][key] = value
    }

    public func with(_ value: Value, for key: Key) -> ScopeStack<Key, Value> {
        var copy = self
        copy.scopes[copy.scopes.count - 1][key] = value
        return copy
    }

    public func push() -> ScopeStack<Key, Value> {
        var copy = self
        copy.scopes.append(Scope())
        return copy
    }

    public func pop() -> ScopeStack<Key, Value> {
        var copy = self
        let _ = copy.scopes.popLast()

        if copy.scopes.count <= 0 {
            fatalError("Popped the root scope")
        }

        return copy
    }
}
