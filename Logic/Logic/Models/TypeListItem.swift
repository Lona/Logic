//
//  TypeListItem.swift
//  LogicExample2
//
//  Created by Devin Abbott on 9/24/18.
//  Copyright © 2018 BitDisco, Inc. All rights reserved.
//

import Foundation

public enum TypeListItem {
    case entity(Entity)
    case typeCase(GenericTypeCase)
    case normalTypeCaseParameter(NormalTypeCaseParameter)
    case recordTypeCaseParameter(RecordTypeCaseParameter)
    case genericTypeParameterSubstitution(GenericTypeParameterSubstitution)

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
        }
    }

    var typeCase: GenericTypeCase? {
        switch self {
        case .typeCase(let value):
            return value
        default:
            return nil
        }
    }

    var entity: Entity? {
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

    var recordTypeCaseParameter: RecordTypeCaseParameter? {
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
}
