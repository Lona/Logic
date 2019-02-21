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

extension SwiftList: Collection {
    public typealias Index = Int
    public typealias Element = T

    public var startIndex: Index { return 0 }
    public var endIndex: Index {
        var count = 0

        var iterator = self.makeIterator()
        while let _ = iterator.next() {
            count += 1
        }

        return count
    }

    public subscript(index: Index) -> Iterator<T>.Element {
        get {
            var count = 0

            var iterator = self.makeIterator()
            while let value = iterator.next() {
                if count == index {
                    return value
                }

                count += 1
            }

            fatalError("SwiftList.Index out of range")
        }
    }

    public func index(after i: Index) -> Index {
        return i + 1
    }
}
