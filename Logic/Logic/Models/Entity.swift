//
//  Entity.swift
//  LogicExample2
//
//  Created by Devin Abbott on 9/25/18.
//  Copyright © 2018 BitDisco, Inc. All rights reserved.
//

import Foundation

public struct NormalType {
    public var name: String
    public var cases: [GenericTypeCase]
}

public struct GenericType {
    public var name: String
    public var cases: [GenericTypeCase]

    public init(name: String, cases: [GenericTypeCase]) {
        self.name = name
        self.cases = cases
    }
}

public struct NativeType {
    public init(name: String) {
        self.name = name
    }

    public var name: String
}

public enum Entity {
    case genericType(GenericType)
    //    case instanceType
    //    case aliasType
    case nativeType(NativeType)

    public var children: [TypeListItem] {
        switch self {
        case .genericType(let genericType):
            return genericType.cases.map { TypeListItem.typeCase($0) }
        case .nativeType:
            return []
        }
    }

    public var name: String {
        switch self {
        case .genericType(let genericType):
            return genericType.name
        case .nativeType(let nativeType):
            return nativeType.name
        }
    }

    func removing(itemAtPath path: [Int]) -> Entity {
        switch self {
        case .genericType(var genericType):
            if path.count > 1 {
                let item = genericType.cases.remove(at: path[0])
                genericType.cases.insert(item.removing(itemAtPath: Array(path.dropFirst())), at: path[0])
            } else {
                genericType.cases.remove(at: path[0])
            }
            return .genericType(genericType)
        case .nativeType:
            return self
        }
    }

    func replacing(itemAtPath path: [Int], with item: TypeListItem) -> TypeListItem {
        switch self {
        case .genericType(var genericType):
            if path.count > 0 {
                genericType.cases = genericType.cases.enumerated().map { index, x in
                    return index == path[0]
                        ? x.replacing(itemAtPath: Array(path.dropFirst()), with: item).typeCase!
                        : x
                }
                return TypeListItem.entity(.genericType(genericType))
            } else {
                return item
            }
        case .nativeType:
            if path.count > 0 {
                return TypeListItem.entity(self)
            } else {
                return item
            }
        }
    }
}
