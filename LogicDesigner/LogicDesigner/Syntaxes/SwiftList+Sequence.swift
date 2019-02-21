//
//  SwiftList+Sequence.swift
//  LogicDesigner
//
//  Created by Devin Abbott on 2/20/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import AppKit

extension SwiftList: Sequence {
    public struct Iterator<T: Equatable & Codable>: IteratorProtocol {
        var list: SwiftList<T>

        init(_ list: SwiftList<T>) {
            self.list = list
        }

        public mutating func next() -> T? {
            switch list {
            case .empty:
                return nil
            case .next(let value, let list):
                self.list = list
                return value
            }
        }
    }

    public func makeIterator() -> Iterator<T> {
        return Iterator(self)
    }
}
