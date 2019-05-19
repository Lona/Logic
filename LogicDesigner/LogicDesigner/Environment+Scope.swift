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
        return node.reduce(initialResult: ScopeStack()) {
            (context, node, config) -> ScopeStack<UUID, String> in
            if node.uuid == targetId {
                config.stopTraversal = true
                return context
            }

            switch node {
            case .declaration(.variable(id: let id, name: let pattern, annotation: _, initializer: _)):
                return context.set(pattern.name, for: id).set(pattern.name, for: pattern.id)
            default:
                break
            }

            return context
        }
    }
}
