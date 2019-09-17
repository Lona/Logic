//
//  Array+Operations.swift
//  Logic
//
//  Created by Devin Abbott on 9/13/18.
//  Copyright © 2018 BitDisco, Inc. All rights reserved.
//

import Foundation

extension Array {
    func intersect(_ other: Array, where predicate: @escaping (Element, Element) -> Bool) -> Array {
        var result: Array<Element> = []

        self.forEach { item in
            let equalsItem = { predicate(item, $0) }

            if other.contains(where: equalsItem) && !result.contains(where: equalsItem) {
                result.append(item)
            }
        }

        return result
    }

    func union(_ other: Array, where predicate: @escaping (Element, Element) -> Bool) -> Array {
        var result: Array<Element> = []

        self.forEach { item in
            let equalsItem = { predicate(item, $0) }

            if !result.contains(where: equalsItem) {
                result.append(item)
            }
        }

        other.forEach { item in
            let equalsItem = { predicate(item, $0) }

            if !result.contains(where: equalsItem) {
                result.append(item)
            }
        }

        return result
    }

    func differenceBy(_ other: Array, where predicate: @escaping (Element, Element) -> Bool) -> Array {
        var result: Array<Element> = []

        self.forEach { item in
            let equalsItem = { predicate(item, $0) }

            if !other.contains(where: equalsItem) {
                result.append(item)
            }
        }

        return result
    }

    func all(where predicate: (Element) -> Bool) -> Bool {
        for element in self {
            if !predicate(element) {
                return false
            }
        }

        return true
    }

    func any(where predicate: (Element) -> Bool) -> Bool {
        for element in self {
            if predicate(element) {
                return true
            }
        }

        return false
    }

    static func concat(_ arrs: [Array]) -> Array {
        let joined = arrs.joined()
        return Array(joined)
    }

    func removing(at position: Int) -> Array {
        var copy = self
        copy.remove(at: position)
        return copy
    }

    func replacing(elementAt position: Int, with item: Element) -> Array {
        var copy = self
        copy.remove(at: position)
        copy.insert(item, at: position)
        return copy
    }

    func inserting(_ element: Element, at position: Int) -> Array {
        var copy = self
        copy.insert(element, at: position)
        return copy
    }
}

extension Array where Element: Equatable {
    func difference(_ other: Array) -> Array {
        var result: Array<Element> = []

        self.forEach { item in
            let equalsItem = { item == $0 }

            if !other.contains(where: equalsItem) {
                result.append(item)
            }
        }

        return result
    }

    func intersect(_ other: Array) -> Array {
        return self.intersect(other, where: { $0 == $1 })
    }

    func union(_ other: Array) -> Array {
        return self.union(other, where: { $0 == $1 })
    }
}
