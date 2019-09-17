//
//  TypeEntity.swift
//  Logic
//
//  Created by Devin Abbott on 9/25/18.
//  Copyright © 2018 BitDisco, Inc. All rights reserved.
//

import Foundation

public struct FunctionType: Codable & Equatable {
    public var parameters: [TypeParameter]
    public var returnType: TypeParameter

    public init(parameters: [TypeParameter], returnType: TypeParameter) {
        self.parameters = parameters
        self.returnType = returnType
    }
}

public enum TypeEntity: Codable & Equatable, CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .nativeType(let value):
            return value.debugDescription
        case .enumType(let value):
            return value.debugDescription
        case .functionType:
            return "functionType(TODO)"
        }
    }

    case enumType(EnumType)
    //    case instanceType
    //    case aliasType
    //    case recordType
    case nativeType(NativeType)
    case functionType(FunctionType)

    enum CodingKeys: String, CodingKey {
        case caseType = "case"
        case data
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let caseType = try container.decode(String.self, forKey: .caseType)

        switch caseType {
        case "type":
            self = .enumType(try container.decode(EnumType.self, forKey: .data))
        case "native":
            self = .nativeType(try container.decode(NativeType.self, forKey: .data))
        default:
            fatalError("Failed to decode TypeCaseParameterEntity")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .enumType(let type):
            try container.encode("type", forKey: .caseType)
            try container.encode(type, forKey: .data)
        case .nativeType(let type):
            try container.encode("native", forKey: .caseType)
            try container.encode(type, forKey: .data)
        case .functionType(let type):
            try container.encode("function", forKey: .caseType)
            try container.encode(type, forKey: .data)
        }
    }

    public var children: [TypeListItem] {
        switch self {
        case .enumType(let genericType):
            return genericType.cases.map { TypeListItem.typeCase($0) }
        case .nativeType(let nativeType):
            return nativeType.parameters.map { TypeListItem.nativeTypeParameter($0) }
        case .functionType:
//            return functionType.parameters.map { TypeListItem.nativeTypeParameter($0) }
            return []
        }
    }

    public var name: String {
        switch self {
        case .enumType(let genericType):
            return genericType.name
        case .nativeType(let nativeType):
            return nativeType.name
        case .functionType:
            return "function"
        }
    }

    func removing(itemAtPath path: [Int]) -> TypeEntity {
        switch self {
        case .enumType(var genericType):
            if path.count > 1 {
                let item = genericType.cases.remove(at: path[0])
                genericType.cases.insert(item.removing(itemAtPath: Array(path.dropFirst())), at: path[0])
            } else {
                genericType.cases.remove(at: path[0])
            }
            return .enumType(genericType)
        case .nativeType(var nativeType):
            if path.count > 1 {
                fatalError("Nothing to remove")
            } else {
                nativeType.parameters.remove(at: path[0])
            }
            return .nativeType(nativeType)
        case .functionType(let functionType):
            return .functionType(functionType)
        }
    }

    func appending(item: TypeListItem, atPath path: [Int]) -> TypeEntity {
        switch self {
        case .enumType(var genericType):
            if path.count > 1 {
                genericType.cases = genericType.cases.replacing(
                    elementAt: path[0],
                    with: genericType.cases[path[0]].appending(item: item, atPath: Array(path.dropFirst()))
                )
            } else {
                genericType.cases.append(item.typeCase!)
            }
            return .enumType(genericType)
        case .nativeType:
            return self
        case .functionType:
            return self
        }
    }

    func inserting(item: TypeListItem, atPath path: [Int]) -> TypeEntity {
        switch self {
        case .enumType(var genericType):
            if path.count > 1 {
                genericType.cases = genericType.cases.replacing(
                    elementAt: path[0],
                    with: genericType.cases[path[0]].inserting(item: item, atPath: Array(path.dropFirst()))
                )
            } else {
                genericType.cases.insert(item.typeCase!, at: path[0])
            }
            return .enumType(genericType)
        case .nativeType:
            return self
        case .functionType(_):
            return self
        }
    }

    func replacing(itemAtPath path: [Int], with item: TypeListItem) -> TypeListItem {
        switch self {
        case .enumType(var genericType):
            if path.count > 0 {
                genericType.cases = genericType.cases.enumerated().map { index, x in
                    return index == path[0]
                        ? x.replacing(itemAtPath: Array(path.dropFirst()), with: item).typeCase!
                        : x
                }
                return TypeListItem.entity(.enumType(genericType))
            } else {
                return item
            }
        case .nativeType(var nativeType):
            if path.count > 0 {
                nativeType.parameters = nativeType.parameters.enumerated().map { index, x in
                    return index == path[0]
                        ? x.replacing(itemAtPath: Array(path.dropFirst()), with: item).nativeTypeParameter!
                        : x
                }
                return TypeListItem.entity(.nativeType(nativeType))
            } else {
                return item
            }
        case .functionType:
            if path.count > 0 {
//                nativeType.parameters = nativeType.parameters.enumerated().map { index, x in
//                    return index == path[0]
//                        ? x.replacing(itemAtPath: Array(path.dropFirst()), with: item).nativeTypeParameter!
//                        : x
//                }
//                return TypeListItem.entity(.nativeType(nativeType))
                return item
            } else {
                return item
            }
        }
    }

    static func make(name: String, genericParameterNames: [String], withContextualTypes types: [TypeEntity]) -> TypeEntity? {
        guard let type = types.first(where: { $0.name == name }) else {
            Swift.print("Failed to find type `\(name)` in context.")
            return nil
        }

        return type
    }
}
