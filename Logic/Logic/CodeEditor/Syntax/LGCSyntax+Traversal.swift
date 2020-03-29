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
        public var needsRevisitAfterTraversingChildren = false

        fileprivate var _isRevisit = false
        public var isRevisit: Bool { return _isRevisit }

        public init(order: TraversalOrder = TraversalOrder.post) {
            self.order = order
        }
    }

    private func reduceChildren<Result>(
        config: inout TraversalConfig,
        initialResult context: Result,
        f: @escaping (Result, LGCSyntaxNode, inout LGCSyntaxNode.TraversalConfig) throws -> Result
    ) rethrows -> Result {

        switch self {
        case .statement(.branch(id: _, condition: let condition, block: let block)):
            let context2 = try condition.node.reduce(config: &config, initialResult: context, f: f)

            if config.ignoreChildren { return context2 }

            return try block.map { $0.node }.reduce(config: &config, initialResult: context2, f: f)
        default:
            return try self.subnodes.reduce(config: &config, initialResult: context, f: f)
        }
    }

    public func reduce<Result>(
        config: inout TraversalConfig,
        initialResult: Result,
        f: @escaping (Result, LGCSyntaxNode, inout LGCSyntaxNode.TraversalConfig) throws -> Result
    ) rethrows -> Result {
        if config.stopTraversal { return initialResult }

        switch config.order {
        case .post:
            let context = try self.reduceChildren(config: &config, initialResult: initialResult, f: f)

            if config.stopTraversal { return context }

            return try f(context, self, &config)
        case .pre:
            var context = try f(initialResult, self, &config)

            let shouldRevisit = config.needsRevisitAfterTraversingChildren

            if config.stopTraversal { return context }

            if config.ignoreChildren {
                config.ignoreChildren = false
            } else {
                context = try self.reduceChildren(config: &config, initialResult: context, f: f)
            }

            if !config.stopTraversal && shouldRevisit {
                config._isRevisit = true

                context = try f(context, self, &config)

                config._isRevisit = false

                // Reset ignoreChildren in case the caller set it (it should do nothing if set here)
                config.ignoreChildren = false
            }

            return context
        }
    }

    public func reduce<Result>(
        initialResult: Result,
        f: @escaping (Result, LGCSyntaxNode, inout LGCSyntaxNode.TraversalConfig) -> Result
        ) -> Result {
        var config = TraversalConfig()

        return reduce(config: &config, initialResult: initialResult, f: f)
    }

    public func forEachDescendant(
        config: inout LGCSyntaxNode.TraversalConfig,
        f: @escaping (LGCSyntaxNode, inout LGCSyntaxNode.TraversalConfig) throws -> Void
    ) rethrows {
        return try reduce(config: &config, initialResult: (), f: { result, node, config in
            try f(node, &config)
            return ()
        })
    }
}

extension Sequence where Iterator.Element == LGCSyntaxNode {
    public func reduce<Result>(
        config: inout LGCSyntaxNode.TraversalConfig,
        initialResult context: Result,
        f: @escaping (Result, LGCSyntaxNode, inout LGCSyntaxNode.TraversalConfig) throws -> Result
    ) rethrows -> Result {
        return try reduce(context) { (result: Result, subnode: LGCSyntaxNode) -> Result in
            if config.stopTraversal { return result }

            return try subnode.reduce(config: &config, initialResult: result, f: f)
        }
    }
}
