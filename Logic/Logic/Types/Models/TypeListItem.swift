//
//  TypeListItem.swift
//  Logic
//
//  Created by Devin Abbott on 9/24/18.
//  Copyright © 2018 BitDisco, Inc. All rights reserved.
//

import Foundation

public enum TypeListItem: Decodable & Encodable & Equatable {
    case entity(TypeEntity)
    case typeCase(TypeCase)
    case normalTypeCaseParameter(NormalTypeCaseParameter)
    case recordTypeCaseParameter(KeyedParameter)
    case genericTypeParameterSubstitution(GenericTypeParameterSubstitution)
    case nativeTypeParameter(NativeTypeParameter)
    
    // MARK: Codable

    public enum CodingKeys: CodingKey {
        case type
        case data
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "entity":
            self = .entity(try container.decode(TypeEntity.self, forKey: .data))
        case "typeCase":
            self = .typeCase(try container.decode(TypeCase.self, forKey: .data))
        case "normalTypeCaseParameter":
            self = .normalTypeCaseParameter(try container.decode(NormalTypeCaseParameter.self, forKey: .data))
        case "recordTypeCaseParameter":
            self = .recordTypeCaseParameter(try container.decode(KeyedParameter.self, forKey: .data))
        case "genericTypeParameterSubstitution":
            self = .genericTypeParameterSubstitution(try container.decode(GenericTypeParameterSubstitution.self, forKey: .data))
        case "nativeTypeParameter":
            self = .nativeTypeParameter(try container.decode(NativeTypeParameter.self, forKey: .data))
        default:
            fatalError("Failed to decode enum due to invalid case type.")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .entity(let value):
            try container.encode("entity", forKey: .type)
            try container.encode(value, forKey: .data)
        case .typeCase(let value):
            try container.encode("typeCase", forKey: .type)
            try container.encode(value, forKey: .data)
        case .normalTypeCaseParameter(let value):
            try container.encode("normalTypeCaseParameter", forKey: .type)
            try container.encode(value, forKey: .data)
        case .recordTypeCaseParameter(let value):
            try container.encode("recordTypeCaseParameter", forKey: .type)
            try container.encode(value, forKey: .data)
        case .genericTypeParameterSubstitution(let value):
            try container.encode("genericTypeParameterSubstitution", forKey: .type)
            try container.encode(value, forKey: .data)
        case .nativeTypeParameter(let value):
            try container.encode("nativeTypeParameter", forKey: .type)
            try container.encode(value, forKey: .data)
        }
    }

    // MARK: Public

    var children: [TypeListItem] {
        switch self {
        case .entity(let value):
            return value.children
        case .typeCase(let value):
            return value.children
        case .normalTypeCaseParameter(let value):
            return value.children
        case .recordTypeCaseParameter(let value):
            return value.children
        case .genericTypeParameterSubstitution:
            return []
        case .nativeTypeParameter:
            return []
        }
    }

    var typeCase: TypeCase? {
        switch self {
        case .typeCase(let value):
            return value
        default:
            return nil
        }
    }

    var entity: TypeEntity? {
        switch self {
        case .entity(let value):
            return value
        default:
            return nil
        }
    }

    var normalTypeCaseParameter: NormalTypeCaseParameter? {
        switch self {
        case .normalTypeCaseParameter(let value):
            return value
        default:
            return nil
        }
    }

    var recordTypeCaseParameter: KeyedParameter? {
        switch self {
        case .recordTypeCaseParameter(let value):
            return value
        default:
            return nil
        }
    }

    var genericTypeParameterSubstitution: GenericTypeParameterSubstitution? {
        switch self {
        case .genericTypeParameterSubstitution(let value):
            return value
        default:
            return nil
        }
    }

    var nativeTypeParameter: NativeTypeParameter? {
        switch self {
        case .nativeTypeParameter(let value):
            return value
        default:
            return nil
        }
    }
}

// NSTableView/NSOutlineView items must be hashable to work correctly.
// We could consider an obj-c compatible wrapper instead, which might be more future-proof.
extension TypeListItem: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(try! JSONEncoder().encode(self).hashValue)
    }
}

