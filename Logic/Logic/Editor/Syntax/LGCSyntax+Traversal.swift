//
//  LGCSyntax+Traversal.swift
//  Logic
//
//  Created by Devin Abbott on 5/19/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

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
        case .statement(.branch(id: _, condition: let condition, block: let block)):
            let context2 = condition.node.reduce(config: &config, initialResult: context, f: f)

            if config.ignoreChildren { return context2 }

            return block.map { $0.node }.reduce(config: &config, initialResult: context2, f: f)
        case .declaration(.function(id: _, name: let pattern, returnType: let returnType, parameters: let parameters, block: let block)):
            return ([pattern.node, returnType.node] + parameters.map { $0.node } + block.map { $0.node }).reduce(config: &config, initialResult: context, f: f)
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
