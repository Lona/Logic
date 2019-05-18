//
//  KeyValueCollection.swift
//
//  Created by Devin Abbott on 5/17/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

public protocol KeyValueCollection {
    associatedtype Key
    associatedtype Value

    func value(for key: Key) -> Value?
    mutating func set(_ value: Value, for key: Key)
    func with(_ value: Value, for key: Key) -> Self
}

public extension KeyValueCollection {
    func with(_ value: Value, for key: Key) -> Self {
        var copy = self
        copy.set(value, for: key)
        return copy
    }

    subscript(key: Key) -> Value? {
        return value(for: key)
    }
}

extension Dictionary: KeyValueCollection {
    public func value(for key: Key) -> Value? {
        return self[key]
    }

    public mutating func set(_ value: Value, for key: Key) {
        self[key] = value
    }
}
