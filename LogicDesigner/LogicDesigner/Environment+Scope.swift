//
//  Environment+Scope.swift
//  LogicDesigner
//
//  Created by Devin Abbott on 5/18/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation
import Logic

public extension Environment {
    static func scope(_ node: LGCSyntaxNode, targetId: UUID) -> ScopeStack<UUID, String> {
        var traversalConfig = LGCSyntaxNode.TraversalConfig(order: .pre)

        return node.reduce(config: &traversalConfig, initialResult: ScopeStack()) {
            (context, node, config) -> ScopeStack<UUID, String> in
            if node.uuid == targetId {
                config.stopTraversal = true
                return context
            }

            config.needsRevisitAfterTraversingChildren = true

            switch (config.isRevisit, node) {
            case (true, .declaration(.variable(id: _, name: let pattern, annotation: _, initializer: let initializer))):
                guard let initializer = initializer else { return context }
                return context.with(pattern.name, for: initializer.uuid)
            case (false, .declaration(.function(id: _, name: _, returnType: _, parameters: let parameters, block: _))):
                return parameters.reduce(context.push()) { result, parameter in
                    switch parameter {
                    case .parameter(id: _, externalName: _, localName: let pattern, annotation: _, defaultValue: _):
                        return result.with(pattern.name, for: pattern.id)
                    default:
                        return result
                    }
                }
            case (true, .declaration(.function(id: _, name: _, returnType: _, parameters: _, block: _))):
                return context.pop()
            default:
                break
            }

            return context
        }
    }
}
