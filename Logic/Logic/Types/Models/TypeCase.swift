//
//  TypeCase.swift
//  Logic
//
//  Created by Devin Abbott on 9/25/18.
//  Copyright © 2018 BitDisco, Inc. All rights reserved.
//

import Foundation

public enum TypeCase: Codable & Equatable {
    case normal(String, [NormalTypeCaseParameter])
    case record(String, [KeyedParameter])

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
            self = .record(name, try container.decode([KeyedParameter].self, forKey: .parameters))
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

    func removing(itemAtPath path: [Int]) -> TypeCase {
        switch self {
        case .normal(let name, var parameters):
            if path.count > 1 {
                return self // TODO
            } else {
                parameters.remove(at: path[0])
                return TypeCase.normal(name, parameters)
            }
        case .record(let name, var parameters):
            if path.count > 1 {
                return self // TODO
            } else {
                parameters.remove(at: path[0])
                return TypeCase.record(name, parameters)
            }
        }
    }

    func appending(item: TypeListItem, atPath path: [Int]) -> TypeCase {
        switch self {
        case .normal(let name, var parameters):
            if path.count > 1 {
                return self // TODO
            } else {
                parameters.append(item.normalTypeCaseParameter!)
                return TypeCase.normal(name, parameters)
            }
        case .record(let name, var parameters):
            if path.count > 1 {
                return self // TODO
            } else {
                parameters.append(item.recordTypeCaseParameter!)
                return TypeCase.record(name, parameters)
            }
        }
    }

    func inserting(item: TypeListItem, atPath path: [Int]) -> TypeCase {
        switch self {
        case .normal(let name, var parameters):
            if path.count > 1 {
                return self // TODO
            } else {
                parameters.insert(item.normalTypeCaseParameter!, at: path[0])
                return TypeCase.normal(name, parameters)
            }
        case .record(let name, var parameters):
            if path.count > 1 {
                return self // TODO
            } else {
                parameters.insert(item.recordTypeCaseParameter!, at: path[0])
                return TypeCase.record(name, parameters)
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
