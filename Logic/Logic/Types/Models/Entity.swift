//
//  Entity.swift
//  Logic
//
//  Created by Devin Abbott on 9/25/18.
//  Copyright © 2018 BitDisco, Inc. All rights reserved.
//

import Foundation

public struct GenericType: Codable & Equatable {
    public var name: String
    public var cases: [TypeCase]

    public init(name: String, cases: [TypeCase]) {
        self.name = name
        self.cases = cases
    }
}

public struct NativeType: Codable & Equatable {
    public init(name: String) {
        self.name = name
    }

    public var name: String
}

public enum Entity: Codable & Equatable {
    case genericType(GenericType)
    //    case instanceType
    //    case aliasType
    case nativeType(NativeType)

    enum CodingKeys: String, CodingKey {
        case caseType = "case"
        case data
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let caseType = try container.decode(String.self, forKey: .caseType)

        switch caseType {
        case "type":
            self = .genericType(try container.decode(GenericType.self, forKey: .data))
        case "native":
            self = .nativeType(try container.decode(NativeType.self, forKey: .data))
        default:
            fatalError("Failed to decode TypeCaseParameterEntity")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .genericType(let type):
            try container.encode("type", forKey: .caseType)
            try container.encode(type, forKey: .data)
        case .nativeType(let type):
            try container.encode("native", forKey: .caseType)
            try container.encode(type, forKey: .data)
        }
    }

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

    func appending(item: TypeListItem, atPath path: [Int]) -> Entity {
        switch self {
        case .genericType(var genericType):
            if path.count > 1 {
                genericType.cases = genericType.cases.replacing(
                    itemAt: path[0],
                    with: genericType.cases[path[0]].appending(item: item, atPath: Array(path.dropFirst()))
                )
            } else {
                genericType.cases.append(item.typeCase!)
            }
            return .genericType(genericType)
        case .nativeType:
            return self
        }
    }

    func inserting(item: TypeListItem, atPath path: [Int]) -> Entity {
        switch self {
        case .genericType(var genericType):
            if path.count > 1 {
                genericType.cases = genericType.cases.replacing(
                    itemAt: path[0],
                    with: genericType.cases[path[0]].inserting(item: item, atPath: Array(path.dropFirst()))
                )
            } else {
                genericType.cases.insert(item.typeCase!, at: path[0])
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
