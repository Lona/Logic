//
//  Immutable.swift
//  LogicDesigner
//
//  Created by Devin Abbott on 5/17/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation
import Logic

public struct Box<Wrapped> {
    public let value: Wrapped

    public init(_ value: Wrapped) {
        self.value = value
    }

    public func with(_ value: Wrapped) -> Box<Wrapped> {
        return Box(value)
    }

    public func map<A>(_ f: (Wrapped) -> A) -> A {
        return f(value)
    }
}

extension Box where Wrapped: KeyValueCollection {
    public func with(_ value: Wrapped.Value, for key: Wrapped.Key) -> Box<Wrapped> {
        return with(self.value.with(value, for: key))
    }
}
