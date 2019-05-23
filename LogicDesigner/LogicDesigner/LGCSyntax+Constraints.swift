//
//  LGCSyntax+Constraints.swift
//  LogicDesigner
//
//  Created by Devin Abbott on 5/22/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation
import Logic

extension LGCSyntaxNode {
    public class UnificationContext {
        var constraints: [Unification.Constraint] = []
        var nodes: [UUID: Unification.T] = [:]

        public init() {}

        private var typeNameGenerator = NameGenerator(prefix: "?")

        func makeGenericName() -> String {
            return typeNameGenerator.next()
        }

        func makeEvar() -> Unification.T {
            return .evar(makeGenericName())
        }
    }

    public func makeConstraints() -> UnificationContext {
        let context: UnificationContext = UnificationContext()

        return self.reduce(initialResult: context) { (result, node, config) in
            switch node {
            case .statement(.branch(id: _, condition: let condition, block: _)):
                context.nodes[condition.uuid] = .cons(name: "Boolean")

                return context
            case .declaration(.variable(id: _, name: let pattern, annotation: let annotation, initializer: let initializer)):
                guard let initializer = initializer, let annotation = annotation else {
                    config.ignoreChildren = true
                    return result
                }

                if annotation.isPlaceholder {
                    config.ignoreChildren = true
                    return result
                }

                let typeVariable = context.makeEvar()
                let annotationType = annotation.unificationType { context.makeGenericName() }

                // TODO: We still need to know the variable name (either via the node or the original/new name),
                // though maybe we do alpha substition outside of this function
                context.constraints.append(Unification.Constraint(annotationType, typeVariable))
                context.nodes[pattern.uuid] = typeVariable
                context.nodes[initializer.uuid] = typeVariable

                return context
            case .expression(.identifierExpression(id: _, identifier: let identifier)):
                let typeVariable = context.makeEvar()

                context.nodes[node.uuid] = typeVariable
                context.nodes[identifier.uuid] = typeVariable

                return context
            case .expression(.literalExpression(id: _, literal: let literal)):
                if let type = context.nodes[literal.uuid] {
                    context.nodes[node.uuid] = type
                }

                return context
            case .expression(.binaryExpression(left: _, right: _, op: let op, id: _)):
                switch op {
                case .isEqualTo, .isNotEqualTo, .isLessThan, .isGreaterThan, .isLessThanOrEqualTo, .isGreaterThanOrEqualTo:
                    context.nodes[node.uuid] = .cons(name: "Boolean")

                    return context
                case .setEqualTo: // TODO
                    break
                }
            case .literal(.boolean):
                context.nodes[node.uuid] = .cons(name: "Boolean")

                return context
            default:
                break
            }

            return context
        }
    }
}
