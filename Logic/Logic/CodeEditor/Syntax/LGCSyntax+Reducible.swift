//
//  LGCSyntax+Traversal.swift
//  Logic
//
//  Created by Devin Abbott on 5/19/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

extension LGCSyntaxNode: Reducible {
    public func reduceChildren<Result>(
        config: TraversalConfig,
        initialResult context: Result,
        f: @escaping (Result, Self, TraversalConfig) throws -> Result
    ) rethrows -> Result {
        switch self {
        case .statement(.branch(id: _, condition: let condition, block: let block)):
            let context2 = try condition.node.reduce(config: config, initialResult: context, f: f)

            if config.ignoreChildren { return context2 }

            return try block.map { $0.node }.reduce(config: config, initialResult: context2, f: f)
        default:
            return try self.subnodes.reduce(config: config, initialResult: context, f: f)
        }
    }
}

extension Sequence where Iterator.Element == LGCSyntaxNode {
    public func reduce<Result>(
        config: TraversalConfig,
        initialResult context: Result,
        f: @escaping (Result, LGCSyntaxNode,   TraversalConfig) throws -> Result
    ) rethrows -> Result {
        return try reduce(context) { (result: Result, subnode: LGCSyntaxNode) -> Result in
            if config.stopTraversal { return result }

            return try subnode.reduce(config: config, initialResult: result, f: f)
        }
    }
}
