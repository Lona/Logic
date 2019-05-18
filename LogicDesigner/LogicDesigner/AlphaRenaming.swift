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

    private struct Context {
        var scopeStack = ScopeStack<String, String>()
        var substitution: Substitution = [:]
        var currentIndex: Int = 0

        func newName(for originalName: String) -> String? {
            return scopeStack.value(for: originalName)
        }

        func with(nodeId: UUID, boundTo originalName: String) -> Context {
            var copy = self
            copy.substitution[nodeId] = copy.scopeStack.value(for: originalName)
            return copy
        }

        func with(newName: String, boundTo originalName: String) -> Context {
            var copy = self
            copy.scopeStack = copy.scopeStack.set(newName, for: originalName)
            return copy
        }
    }

    public static func rename(_ node: LGCSyntaxNode) -> Substitution {
        var defaultConfig = LGCSyntaxNode.TraversalConfig(order: .post)

        let result: Context = node.reduce(config: &defaultConfig, initialResult: Context(), f: {
            (context, node, config) -> Context in
            switch node {
            case .declaration(.variable(id: _, name: let pattern, annotation: _, initializer: _)):
                let newName = makeAlphaVariableName()

                config.ignoreChildren = true

                return context.with(newName: newName, boundTo: pattern.name).with(nodeId: pattern.id, boundTo: pattern.name)
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

        return result.substitution
    }
}

// Experimental reduce function

extension LGCSyntaxNode {
    public enum TraversalOrder {
        case pre, post
    }

    public struct TraversalConfig {
        public var order: TraversalOrder
        public var ignoreChildren = false
        public var stopTraversal = false

        public init(order: TraversalOrder = TraversalOrder.post) {
            self.order = order
        }

        public var ignoringChildren: TraversalConfig {
            var copy = self
            copy.ignoreChildren = true
            return copy
        }

        public var stoppingTraversal: TraversalConfig {
            var copy = self
            copy.stopTraversal = true
            return copy
        }
    }

    private func reduceChildren<Result>(
        config: inout TraversalConfig,
        initialResult context: Result,
        f: @escaping (Result, LGCSyntaxNode, inout LGCSyntaxNode.TraversalConfig) -> Result
    ) -> Result {
        switch self {
        case .program(let program):
            return program.block.reduce(context, { result, statement in
                return statement.node.reduce(config: &config, initialResult: result, f: f)
            })
        case .statement(.declaration(id: _, content: let declaration)):
            return declaration.node.reduce(config: &config, initialResult: context, f: f)
        case .declaration(.variable(id: _, name: let pattern, annotation: _, initializer: let initializer)):
            var context2: Result

            if let initializer = initializer {
                context2 = initializer.node.reduce(config: &config, initialResult: context, f: f)
            } else {
                context2 = context
            }

            context2 = pattern.node.reduce(config: &config, initialResult: context2, f: f)

            return context2
        case .expression(.binaryExpression(left: let left, right: let right, op: let op, id: _)):
            return [left.node, right.node, op.node].reduce(config: &config, initialResult: context, f: f)
        case .expression(.identifierExpression(id: _, identifier: let identifier)):
            return identifier.node.reduce(config: &config, initialResult: context, f: f)
        case .expression(.literalExpression(id: _, literal: let literal)):
            return literal.node.reduce(config: &config, initialResult: context, f: f)
        default:
            break
        }

        return context
    }

    public func reduce<Result>(
        config: inout TraversalConfig,
        initialResult: Result,
        f: @escaping (Result, LGCSyntaxNode, inout LGCSyntaxNode.TraversalConfig) -> Result
        ) -> Result {
        if config.stopTraversal { return initialResult }

        switch config.order {
        case .post:
            let context = self.reduceChildren(config: &config, initialResult: initialResult, f: f)

            if config.stopTraversal { return context }

            return f(context, self, &config)
        case .pre:
            let context = f(initialResult, self, &config)

            if config.ignoreChildren || config.stopTraversal {
                config.ignoreChildren = false
                return context
            } else {
                return self.reduceChildren(config: &config, initialResult: context, f: f)
            }
        }
    }

    public func reduce<Result>(
        initialResult: Result,
        f: @escaping (Result, LGCSyntaxNode, inout LGCSyntaxNode.TraversalConfig) -> Result
        ) -> Result {

        var config = TraversalConfig()

        return reduce(config: &config, initialResult: initialResult, f: f)
    }
}

extension Sequence where Iterator.Element == LGCSyntaxNode {
    public func reduce<Result>(
        config: inout LGCSyntaxNode.TraversalConfig,
        initialResult context: Result,
        f: @escaping (Result, LGCSyntaxNode, inout LGCSyntaxNode.TraversalConfig) -> Result
        ) -> Result {
        return self.reduce(context) { (result: Result, subnode: LGCSyntaxNode) -> Result in
            if config.stopTraversal { return result }

            return subnode.reduce(config: &config, initialResult: result, f: f)
        }
    }
}
