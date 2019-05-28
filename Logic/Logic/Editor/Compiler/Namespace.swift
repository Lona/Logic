//
//  Namespace.swift
//  Logic
//
//  Created by Devin Abbott on 5/28/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

public extension Compiler {
    struct Namespace: CustomDebugStringConvertible {
        public init() {}

        public var debugDescription: String {
            return pairs.debugDescription
        }

        public indirect enum Value: CustomDebugStringConvertible {
            public var debugDescription: String {
                switch self {
                case .pattern(let uuid):
                    return uuid.debugDescription
                case .namespace(let namespace):
                    return namespace.debugDescription
                }
            }

            case namespace(Namespace)
            case pattern(UUID)
        }

        public var pairs: [String: Value] = [:]

        public func get(_ keyPath: [String]) -> Value? {
            guard let key = keyPath.first, let value = pairs[key] else { return nil }

            let rest = keyPath.dropFirst()

            if rest.isEmpty {
                return value
            } else {
                switch value {
                case .namespace(let sub):
                    return sub.get(Array(rest))
                case .pattern:
                    fatalError("Invalid namespace keypath")
                }
            }
        }

        public mutating func with(_ keyPath: [String], setTo value: Value) -> Namespace {
            guard let key = keyPath.first else { return self }

            let rest = keyPath.dropFirst()

            if rest.isEmpty {
                self.pairs[key] = value
            } else {
                guard let current = self.pairs[key] else { return self }

                switch current {
                case .namespace(var sub):
                    self.pairs[key] = .namespace(sub.with(Array(rest), setTo: value))
                case .pattern:
                    fatalError("Invalid namespace keypath")
                }
            }

            return self
        }

        public mutating func set(_ keyPath: [String], setTo value: Value) {
            self = with(keyPath, setTo: value)
        }

        public var flattened: [(keyPath: [String], pattern: UUID)] {
            let all: [[(keyPath: [String], UUID)]] = pairs.map { key, value in
                switch value {
                case .pattern(let uuid):
                    return [([key], uuid)]
                case .namespace(let sub):
                    return sub.flattened.map { keyPath, nestedValue in
                        return ([key] + keyPath, nestedValue)
                    }
                }
            }

            return Array(all.joined())
        }
    }
}
