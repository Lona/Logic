//
//  KeyValueMap.swift
//  LogicDesigner
//
//  Created by Devin Abbott on 5/17/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

public final class KeyValueMap<Key: Hashable, Value: Equatable> /*: KeyValueCollection */ {
    public typealias Key = Key
    public typealias Value = Value
    public typealias Pair = (Key, Value)

    private var dict: [Key: [Value]] = [:]

    public init(_ pairs: [Pair] = []) {
        for (key, value) in pairs {
            add(value, for: key)
        }
    }

    public func firstValue(for key: Key) -> Value? {
        return dict[key]?.first
    }

    public func add(_ value: Value, for key: Key) {
        if let existing = dict[key] {
            if !existing.contains(value) {
                dict[key] = existing + [value]
            }
        } else {
            dict[key] = [value]
        }
    }

    public var pairs: [Pair] {
        var result: [Pair] = []

        dict.forEach { (key, array) in
            array.forEach { value in
                result.append((key, value))
            }
        }

        return result
    }
}

extension KeyValueMap: CustomDebugStringConvertible {
    public var debugDescription: String {
        let contents = pairs.map { "\($0.0): \($0.1)" }.joined(separator: ", ")
        return "[\(contents)]"
    }
}
