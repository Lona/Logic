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

    class ScopeContext {
        // Values in these are never removed, even if a variable is out of scope
        var patternToName: [UUID: String] = [:]
        var identifierToPattern: [UUID: UUID] = [:]

        // This keeps track of the current scope
        fileprivate var patternNames = ScopeStack<String, LGCPattern>()

        var namesInScope: [String] {
            return patternNames.flattened.map { $0.key }
        }

        var patternsInScope: [LGCPattern] {
            return patternNames.flattened.map { $0.value }
        }

        public init() {}
    }

    static func scopeContext(_ node: LGCSyntaxNode, targetId: UUID? = nil) -> ScopeContext {
        var traversalConfig = LGCSyntaxNode.TraversalConfig(order: .pre)

        return node.reduce(config: &traversalConfig, initialResult: ScopeContext()) {
            (context, node, config) -> ScopeContext in
            if node.uuid == targetId {
                config.stopTraversal = true
                return context
            }

            config.needsRevisitAfterTraversingChildren = true

            switch (config.isRevisit, node) {
            case (true, .identifier(let identifier)):
                if identifier.isPlaceholder { return context }

                if context.patternNames.value(for: identifier.string) == nil {
                    Swift.print("No \(identifier.string)", context.patternNames)
                }

                context.identifierToPattern[identifier.uuid] = context.patternNames.value(for: identifier.string)!.uuid
            case (true, .declaration(.variable(id: _, name: let pattern, annotation: _, initializer: _))):
                context.patternToName[pattern.uuid] = pattern.name
                context.patternNames.set(pattern, for: pattern.name)

                return context
            case (false, .declaration(.function(id: _, name: _, returnType: _, parameters: let parameters, block: _))):
                context.patternNames = context.patternNames.push()

                parameters.forEach { parameter in
                    switch parameter {
                    case .parameter(id: _, externalName: _, localName: let pattern, annotation: _, defaultValue: _):
                        context.patternToName[pattern.uuid] = pattern.name
                        context.patternNames.set(pattern, for: pattern.name)
                    default:
                        break
                    }
                }

                return context
            case (true, .declaration(.function(id: _, name: _, returnType: _, parameters: _, block: _))):
                context.patternNames = context.patternNames.pop()

                return context
            default:
                break
            }

            return context
        }
    }
}
