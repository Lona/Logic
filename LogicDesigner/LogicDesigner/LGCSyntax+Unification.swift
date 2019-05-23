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

    public func makeUnificationContext() -> UnificationContext {
        return self.reduce(initialResult: UnificationContext()) { (result, node, config) in
            switch node {
            case .statement(.branch(id: _, condition: let condition, block: _)):
                result.nodes[condition.uuid] = .cons(name: "Boolean")

                return result
            case .declaration(.variable(id: _, name: let pattern, annotation: let annotation, initializer: let initializer)):
                guard let initializer = initializer, let annotation = annotation else {
                    config.ignoreChildren = true
                    return result
                }

                if annotation.isPlaceholder {
                    config.ignoreChildren = true
                    return result
                }

                let annotationType = annotation.unificationType { result.makeGenericName() }

                result.nodes[pattern.uuid] = annotationType
                result.constraints.append(Unification.Constraint(annotationType, result.nodes[initializer.uuid]!))

                return result
            case .expression(.identifierExpression(id: _, identifier: let identifier)):
                let typeVariable = result.makeEvar()

                result.nodes[node.uuid] = typeVariable
                result.nodes[identifier.uuid] = typeVariable

                return result
            case .expression(.literalExpression(id: _, literal: let literal)):
                result.nodes[node.uuid] = result.nodes[literal.uuid]!
                return result
            case .expression(.binaryExpression(left: let left, right: let right, op: let op, id: _)):
                switch op {
                case .isEqualTo, .isNotEqualTo, .isLessThan, .isGreaterThan, .isLessThanOrEqualTo, .isGreaterThanOrEqualTo:
                    result.nodes[node.uuid] = .cons(name: "Boolean")
                    result.constraints.append(Unification.Constraint(result.nodes[left.uuid]!, result.nodes[right.uuid]!))
                    return result
                case .setEqualTo: // TODO
                    break
                }
            case .literal(.boolean):
                result.nodes[node.uuid] = .cons(name: "Boolean")

                return result
            case .literal(.number):
                result.nodes[node.uuid] = .cons(name: "Number")

                return result
            case .literal(.string):
                result.nodes[node.uuid] = .cons(name: "String")

                return result
            default:
                break
            }

            return result
        }
    }
}
