//
//  TypeParameter.swift
//  Logic
//
//  Created by Devin Abbott on 9/26/18.
//  Copyright © 2018 BitDisco, Inc. All rights reserved.
//

import Foundation

public enum TypeParameter: Codable & Equatable {
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
