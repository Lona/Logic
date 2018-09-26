//
//  TypeCase.swift
//  LogicExample2
//
//  Created by Devin Abbott on 9/25/18.
//  Copyright © 2018 BitDisco, Inc. All rights reserved.
//

import Foundation

public struct GenericTypeParameterSubstitution: Codable {
    public init(generic: String, instance: String) {
        self.generic = generic
        self.instance = instance
    }

    public let generic: String
    public let instance: String
}

public enum TypeCaseParameterEntity: Codable {
    case type(String, [GenericTypeParameterSubstitution])
    case generic(String)

    enum CodingKeys: String, CodingKey {
        case caseType = "case"
        case name
        case substitutions
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let caseType = try container.decode(String.self, forKey: .caseType)
        let name = try container.decode(String.self, forKey: .name)

        switch caseType {
        case "generic":
            self = .generic(name)
        case "type":
            self = .type(name, try container.decode([GenericTypeParameterSubstitution].self, forKey: .substitutions))
        default:
            fatalError("Failed to decode TypeCaseParameterEntity")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        switch self {
        case .generic:
            try container.encode("generic", forKey: .caseType)
        case .type(_, let substitutions):
            try container.encode("type", forKey: .caseType)
            try container.encode(substitutions, forKey: .substitutions)
        }
    }

    public var name: String {
        switch self {
        case .type(let entity, _):
            return entity
        case .generic(let value):
            return value
        }
    }

    public var children: [TypeListItem] {
        switch self {
        case .type(_, let substitutions):
            return substitutions.map { TypeListItem.genericTypeParameterSubstitution($0) }
        case .generic:
            return []
        }
    }

    func replacing(itemAtPath path: [Int], with item: TypeListItem) -> TypeListItem {
        return item
    }
}

public struct NormalTypeCaseParameter: Codable {
    public init(value: TypeCaseParameterEntity) {
        self.value = value
    }

    public var value: TypeCaseParameterEntity

    public var children: [TypeListItem] {
        return value.children
    }

    func replacing(itemAtPath path: [Int], with item: TypeListItem) -> TypeListItem {
        if path.count > 0 {
            switch value {
            case .type(let name, var substitution):
                if path.count > 0 {
                    substitution = substitution.enumerated().map { index, x in
                        if index == path[0] {
                            return item.genericTypeParameterSubstitution!
                        } else {
                            return x
                        }
                    }
                    return TypeListItem.normalTypeCaseParameter(
                        NormalTypeCaseParameter(value:
                            TypeCaseParameterEntity.type(name, substitution)))
                } else {
                    return item
                }
            case .generic:
                return TypeListItem.normalTypeCaseParameter(self)
            }
        } else {
            return item
        }
    }
}

public struct RecordTypeCaseParameter: Codable {
    public init(key: String, value: TypeCaseParameterEntity) {
        self.key = key
        self.value = value
    }

    public var key: String
    public var value: TypeCaseParameterEntity

    public var children: [TypeListItem] {
        return value.children
    }

    func replacing(itemAtPath path: [Int], with item: TypeListItem) -> TypeListItem {
        if path.count > 0 {
            switch value {
            case .type(let name, var substitution):
                if path.count > 0 {
                    substitution = substitution.enumerated().map { index, x in
                        if index == path[0] {
                            return item.genericTypeParameterSubstitution!
                        } else {
                            return x
                        }
                    }
                    return TypeListItem.recordTypeCaseParameter(
                        RecordTypeCaseParameter(key: key, value:
                            TypeCaseParameterEntity.type(name, substitution)))
                } else {
                    return item
                }
            case .generic:
                return TypeListItem.recordTypeCaseParameter(self)
            }
        } else {
            return item
        }
    }
}

public enum GenericTypeCase: Codable {
    case normal(String, [NormalTypeCaseParameter])
    case record(String, [RecordTypeCaseParameter])

    enum CodingKeys: String, CodingKey {
        case caseType = "case"
        case name
        case parameters = "params"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let caseType = try container.decode(String.self, forKey: .caseType)
        let name = try container.decode(String.self, forKey: .name)

        switch caseType {
        case "normal":
            self = .normal(name, try container.decode([NormalTypeCaseParameter].self, forKey: .parameters))
        case "record":
            self = .record(name, try container.decode([RecordTypeCaseParameter].self, forKey: .parameters))
        default:
            fatalError("Failed to decode TypeCaseParameterEntity")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        switch self {
        case .normal(_, let parameters):
            try container.encode("normal", forKey: .caseType)
            try container.encode(parameters, forKey: .parameters)
        case .record(_, let parameters):
            try container.encode("record", forKey: .caseType)
            try container.encode(parameters, forKey: .parameters)
        }
    }

    public var children: [TypeListItem] {
        switch self {
        case .normal(_, let parameters):
            return parameters.map { TypeListItem.normalTypeCaseParameter($0) }
        case .record(_, let parameters):
            return parameters.map { TypeListItem.recordTypeCaseParameter($0) }
        }
    }

    public var name: String {
        switch self {
        case .normal(let name, _), .record(let name, _):
            return name
        }
    }

    func removing(itemAtPath path: [Int]) -> GenericTypeCase {
        switch self {
        case .normal(let name, var parameters):
            if path.count > 1 {
                return self // TODO
            } else {
                parameters.remove(at: path[0])
                return GenericTypeCase.normal(name, parameters)
            }
        case .record(let name, var parameters):
            if path.count > 1 {
                return self // TODO
            } else {
                parameters.remove(at: path[0])
                return GenericTypeCase.record(name, parameters)
            }
        }
    }

    func replacing(itemAtPath path: [Int], with item: TypeListItem) -> TypeListItem {
        switch self {
        case .normal(let name, var parameters):
            if path.count > 0 {
                parameters = parameters.enumerated().map { index, x in
                    if index == path[0] {
                        return x.replacing(itemAtPath: Array(path.dropFirst()), with: item).normalTypeCaseParameter!
                    } else {
                        return x
                    }
                }
                return TypeListItem.typeCase(.normal(name, parameters))
            } else {
                return item
            }
        case .record(let name, var parameters):
            if path.count > 0 {
                parameters = parameters.enumerated().map { index, x in
                    if index == path[0] {
                        return x.replacing(itemAtPath: Array(path.dropFirst()), with: item).recordTypeCaseParameter!
                    } else {
                        return x
                    }
                }
                return TypeListItem.typeCase(.record(name, parameters))
            } else {
                return item
            }
        }
    }
}
