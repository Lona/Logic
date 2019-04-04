//
//  TypeInference.swift
//  Logic
//
//  Created by Devin Abbott on 4/4/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

public struct InferredType {
    var entity: TypeEntity
    var substitutions: [GenericTypeParameterSubstitution]
}

public protocol TypeInferable {
    func inferType(within rootNode: LGCSyntaxNode, context: [TypeEntity]) -> InferredType?
}

extension LGCFunctionParameterDefaultValue: TypeInferable {
    public func inferType(within rootNode: LGCSyntaxNode, context: [TypeEntity]) -> InferredType? {
        guard let path = rootNode.pathTo(id: self.uuid) else { return nil }

        guard let functionParameter = path.last(where: {
            guard case LGCSyntaxNode.functionParameter(_) = $0 else { return true }
            return false
        }) else { return nil }

        switch functionParameter {
        case .typeAnnotation(.typeIdentifier(let value)):
            guard let match = context.first(where: { entity in entity.name == value.identifier.string }) else { return nil }

//            value.genericArguments.map { $0. }
            return InferredType(entity: match, substitutions: [])
        default:
            fatalError("Problem")
        }
    }
}
