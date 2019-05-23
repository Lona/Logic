//
//  AlphaRenaming.swift
//  LogicDesigner
//
//  Created by Devin Abbott on 5/16/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation
import Logic

private var currentIndex: Int = 0

private func makeAlphaVariableName() -> String {
    currentIndex += 1
    let name = String(currentIndex, radix: 36, uppercase: true)
    return "__\(name)"
}


public enum AlphaRenaming {
    public typealias Substitution = [UUID: String]

    public struct Context {
        public var scopeStack = ScopeStack<String, String>()
        public var substitution: Substitution = [:]
        public var originalNames: Substitution = [:]
        var currentIndex: Int = 0

        func newName(for originalName: String) -> String? {
            return scopeStack.value(for: originalName)
        }

        func with(nodeId: UUID, boundTo originalName: String) -> Context {
            var copy = self
            copy.substitution[nodeId] = copy.scopeStack.value(for: originalName)
            copy.originalNames[nodeId] = originalName
            return copy
        }

        func with(newName: String, boundTo originalName: String) -> Context {
            var copy = self
            copy.scopeStack = copy.scopeStack.with(newName, for: originalName)
            return copy
        }
    }

    public static func rename(_ node: LGCSyntaxNode) -> Context {
        var defaultConfig = LGCSyntaxNode.TraversalConfig(order: .post)

        let result: Context = node.reduce(config: &defaultConfig, initialResult: Context(), f: {
            (context, node, config) -> Context in
            switch node {
            case .declaration(.variable(id: let id, name: let pattern, annotation: _, initializer: _)):
                let newName = makeAlphaVariableName()

                config.ignoreChildren = true

                return context
                    .with(newName: newName, boundTo: pattern.name)
                    .with(nodeId: pattern.id, boundTo: pattern.name)
                    .with(nodeId: id, boundTo: pattern.name)
            case .expression(.identifierExpression(id: _, identifier: let identifier)):
                if identifier.isPlaceholder {
                    return context
                }

                return context.with(nodeId: identifier.uuid, boundTo: identifier.string)
            default:
                break
            }

            return context
        })

        return result
    }
}
