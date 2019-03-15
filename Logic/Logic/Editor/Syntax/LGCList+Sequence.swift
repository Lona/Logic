//
//  SwiftList+Sequence.swift
//  LogicDesigner
//
//  Created by Devin Abbott on 2/20/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import AppKit

public struct LGCListIterator<T: Equatable & Codable>: IteratorProtocol {
    var list: LGCList<T>

    init(_ list: LGCList<T>) {
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


extension LGCList: Sequence {
    public func makeIterator() -> LGCListIterator<T> {
        return LGCListIterator(self)
    }
}

extension LGCList: Collection {
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

    public subscript(index: Index) -> LGCListIterator<T>.Element {
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
