//
//  Compiler+Evaluate.swift
//  Logic
//
//  Created by Devin Abbott on 5/30/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

extension Compiler {
    public struct LogicValue {
        public let type: Unification.T
        public let memory: Any

        public init(_ type: Unification.T, _ memory: Any) {
            self.type = type
            self.memory = memory
        }

        static let unit = LogicValue(.cons(name: "Void"), 0)
        static let `true` = LogicValue(.cons(name: "Boolean"), true)
        static let `false` = LogicValue(.cons(name: "Boolean"), false)
    }

    public class EvaluationContext {
        public init(values: [UUID: LogicValue] = [:]) {
            self.values = values
        }

        public var values: [UUID: LogicValue]
    }

    public typealias EvaluationResult = Result<EvaluationContext, Error>

    public static func evaluate(
        _ node: LGCSyntaxNode,
        scopeContext: ScopeContext,
        unificationContext: UnificationContext,
        substitution: Unification.Substitution,
        context: EvaluationContext
        ) -> EvaluationResult {

//        Swift.print("Handle", node.nodeTypeDescription)

        func processChildren(result: Result<EvaluationContext, Error>) -> EvaluationResult {
            return node.subnodes.reduce(result, { result, child in
                switch result {
                case .failure:
                    return result
                case .success(let newContext):
                    return evaluate(
                        child,
                        scopeContext: scopeContext,
                        unificationContext: unificationContext,
                        substitution: substitution,
                        context: newContext
                    )
                }
            })
        }

        var result: EvaluationResult

        // Pre
        switch node {
        case .statement(.branch(id: _, condition: let condition, block: _)):
            result = evaluate(
                condition.node,
                scopeContext: scopeContext,
                unificationContext: unificationContext,
                substitution: substitution,
                context: context
                ).flatMap { context -> EvaluationResult in
                    if let value = context.values[condition.uuid],
                        let memory = value.memory as? Bool, memory == true,
                        value.type == .cons(name: "Boolean") {

                        return processChildren(result: .success(context))
                    } else {
                        return .success(context)
                    }
            }
        default:
            result = processChildren(result: .success(context))
        }

        guard case .success(let context) = result else { return result }

        // Post
        switch node {
        case .literal(.boolean(id: _, value: let value)):
            context.values[node.uuid] = LogicValue(.cons(name: "Boolean"), value)
        case .literal(.number(id: _, value: let value)):
            context.values[node.uuid] = LogicValue(.cons(name: "Number"), value)
        case .literal(.string(id: _, value: let value)):
            context.values[node.uuid] = LogicValue(.cons(name: "String"), value)
        case .literal(.color(id: _, value: let value)):
            context.values[node.uuid] = LogicValue(.cons(name: "CSSColor"), value)
        case .expression(.literalExpression(id: _, literal: let literal)):
            if let value = context.values[literal.uuid] {
                context.values[node.uuid] = value
            }
        case .expression(.identifierExpression(id: _, identifier: let identifier)):
            Swift.print("ident", identifier.string)

            guard let patternId = scopeContext.identifierToPattern[identifier.uuid] else { break }

            Swift.print("pattern id", patternId)

            guard let value = context.values[patternId] else { break }

            Swift.print("value", value)

            context.values[identifier.uuid] = value
            context.values[node.uuid] = value
        case .expression(.binaryExpression(left: let left, right: let right, op: let op, id: _)):
            Swift.print("binary expr", left, right, op)
        case .declaration(.variable(_, let pattern, _, let initializer)):
            guard let initializer = initializer else { return .success(context) }

            context.values[pattern.uuid] = context.values[initializer.uuid]
        default:
            break
        }

        return .success(context)
    }
}
