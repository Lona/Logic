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

private func makeGenericName() -> String {
    currentIndex += 1
    let name = String(currentIndex, radix: 36, uppercase: true)
    return "?\(name)"
}


public enum AlphaRenaming {
    public typealias Substitution = [UUID: String]

    private struct Context {
        var scopeStack = ScopeStack<String, String>()
        var sub: Substitution = [:]
        var currentIndex: Int = 0

        func newName(for originalName: String) -> String? {
            return scopeStack.value(for: originalName)
        }

        func with(nodeId: UUID, boundTo originalName: String) -> Context {
            var copy = self
            copy.sub[nodeId] = copy.scopeStack.value(for: originalName)
            return copy
        }

        func with(newName: String, boundTo originalName: String) -> Context {
            var copy = self
            copy.scopeStack = copy.scopeStack.set(newName, for: originalName)
            return copy
        }
    }

    public static func rename(_ node: LGCSyntaxNode) -> Substitution {
        let result: Context = node.reduce(order: .post, initialResult: Context(), f: { (context, node) -> (result: Context, ignoreChildren: Bool) in
            switch node {
            case .declaration(.variable(id: _, name: let pattern, annotation: _, initializer: _)):
                let newName = makeGenericName()

                return (
                    context
                        .with(newName: newName, boundTo: pattern.name)
                        .with(nodeId: pattern.id, boundTo: pattern.name),
                    true
                )
            case .expression(.identifierExpression(id: _, identifier: let identifier)):
                if identifier.isPlaceholder { return (context, true) }

                return (context.with(nodeId: identifier.uuid, boundTo: identifier.string), true)
            default:
                break
            }

            return (context, false)
        })

        Swift.print("Result", result)

        return result.sub
    }
}

// Experimental reduce function

extension LGCSyntaxNode {
    public enum TraversalOrder {
        case pre, post
    }

    private func reduceChildren<Result>(
        order: TraversalOrder,
        initialResult context: Result,
        f: @escaping (Result, LGCSyntaxNode) -> (result: Result, ignoreSubnodes: Bool)
    ) -> Result {
        switch self {
        case .program(let program):
            return program.block.reduce(context, { result, statement in
                return statement.node.reduce(order: order, initialResult: result, f: f)
            })
        case .statement(.declaration(id: _, content: let declaration)):
            return declaration.node.reduce(order: order, initialResult: context, f: f)
        case .declaration(.variable(id: _, name: let pattern, annotation: _, initializer: let initializer)):
            var context2: Result

            if let initializer = initializer {
                context2 = initializer.node.reduce(order: order, initialResult: context, f: f)
            } else {
                context2 = context
            }

            context2 = pattern.node.reduce(order: order, initialResult: context2, f: f)

            return context2
        case .expression(.binaryExpression(left: let left, right: let right, op: let op, id: _)):
            return [left.node, right.node, op.node].reduce(order: order, initialResult: context, f: f)
        case .expression(.identifierExpression(id: _, identifier: let identifier)):
            return identifier.node.reduce(order: order, initialResult: context, f: f)
        case .expression(.literalExpression(id: _, literal: let literal)):
            return literal.node.reduce(order: order, initialResult: context, f: f)
        default:
            break
        }

        return context
    }

    public func reduce<Result>(
        order: TraversalOrder,
        initialResult: Result,
        f: @escaping (Result, LGCSyntaxNode) -> (result: Result, ignoreChildren: Bool)
        ) -> Result {
        switch order {
        case .post:
            let context = self.reduceChildren(order: order, initialResult: initialResult, f: f)

            return f(context, self).result
        case .pre:
            let (context, ignoreChildren) = f(initialResult, self)

            if ignoreChildren {
                return context
            } else {
                return self.reduceChildren(order: order, initialResult: context, f: f)
            }
        }
    }
}

extension Sequence where Iterator.Element == LGCSyntaxNode {
    public func reduce<Result>(
        order: LGCSyntaxNode.TraversalOrder,
        initialResult context: Result,
        f: @escaping (Result, LGCSyntaxNode) -> (result: Result, ignoreSubnodes: Bool)
        ) -> Result {
        return self.reduce(context) { (result: Result, subnode: LGCSyntaxNode) -> Result in
            return subnode.reduce(order: order, initialResult: result, f: f)
        }
    }
}
