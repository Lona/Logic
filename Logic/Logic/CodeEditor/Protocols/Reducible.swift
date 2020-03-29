//
//  Reducible.swift
//  Logic
//
//  Created by Devin Abbott on 3/29/20.
//  Copyright © 2020 BitDisco, Inc. All rights reserved.
//

import Foundation

public enum TraversalOrder {
    case pre, post
}

public class TraversalConfig {
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

public protocol Reducible {
    func reduce<R>(
        config: TraversalConfig,
        initialResult: R,
        f: @escaping (R, Self, TraversalConfig) throws -> R
    ) rethrows -> R

    func reduceChildren<R>(
        config: TraversalConfig,
        initialResult: R,
        f: @escaping (R, Self, TraversalConfig) throws -> R
    ) rethrows -> R
}

extension Reducible {
    /**
     The main reduce implementation, traversing into the subtree.
     */
    public func reduce<R>(
        config: TraversalConfig,
        initialResult: R,
        f: @escaping (R, Self, TraversalConfig) throws -> R
    ) rethrows -> R {
        if config.stopTraversal { return initialResult }

        switch config.order {
        case .post:
            let context = try self.reduceChildren(config: config, initialResult: initialResult, f: f)

            if config.stopTraversal { return context }

            return try f(context, self, config)
        case .pre:
            var context = try f(initialResult, self, config)

            let shouldRevisit = config.needsRevisitAfterTraversingChildren

            if config.stopTraversal { return context }

            if config.ignoreChildren {
                config.ignoreChildren = false
            } else {
                context = try self.reduceChildren(config: config, initialResult: context, f: f)
            }

            if !config.stopTraversal && shouldRevisit {
                config._isRevisit = true

                context = try f(context, self, config)

                config._isRevisit = false

                // Reset ignoreChildren in case the caller set it (it should do nothing if set here)
                config.ignoreChildren = false
            }

            return context
        }
    }

    public func reduce<R>(
        initialResult: R,
        f: @escaping (R, Self, TraversalConfig) -> R
    ) -> R {
        return reduce(config: TraversalConfig(), initialResult: initialResult, f: f)
    }

    public func forEachDescendant(
        config: TraversalConfig,
        f: @escaping (Self, TraversalConfig) throws -> Void
    ) rethrows {
        return try reduce(config: config, initialResult: (), f: { result, node, config in
            try f(node, config)
            return ()
        })
    }
}
