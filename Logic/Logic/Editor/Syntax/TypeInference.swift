//
//  TypeInference.swift
//  Logic
//
//  Created by Devin Abbott on 4/4/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

public struct InferredType {
    public var entity: TypeEntity
    public var substitutions: [GenericTypeParameterSubstitution]

    public init(entity: TypeEntity, substitutions: [GenericTypeParameterSubstitution] = []) {
        self.entity = entity
        self.substitutions = substitutions
    }
}

public protocol TypeInferable {
    func inferType(within rootNode: LGCSyntaxNode, context: [TypeEntity]) -> InferredType?
}

extension LGCFunctionParameterDefaultValue: TypeInferable {
    public func inferType(within rootNode: LGCSyntaxNode, context: [TypeEntity]) -> InferredType? {
        guard let path = rootNode.pathTo(id: self.uuid) else { return nil }

        guard let functionParameter = path.last(where: {
            switch $0 {
            case .functionParameter:
                return true
            default:
                return false
            }
        }) else { return nil }

        switch functionParameter {
        case .functionParameter(.placeholder):
            return nil
        case .functionParameter(.parameter(let parameter)):
            switch parameter.annotation {
            case .typeIdentifier(let typeIdentifier):
                guard let match = context.first(where: { entity in
                    entity.name == typeIdentifier.identifier.string
                }) else { return nil }

                return InferredType(entity: match, substitutions: [])
            case .functionType:
                return nil // TODO
            }
        default:
            fatalError("Problem")
        }
    }
}
