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

        public var pairs: [[String]: UUID] = [:]

        public func get(_ keyPath: [String]) -> UUID? {
            return pairs[keyPath]
        }

        public mutating func with(_ keyPath: [String], setTo value: UUID) -> Namespace {
            self.pairs[keyPath] = value
            return self
        }

        public mutating func set(_ keyPath: [String], setTo value: UUID) {
            self.pairs[keyPath] = value
        }
    }
}
