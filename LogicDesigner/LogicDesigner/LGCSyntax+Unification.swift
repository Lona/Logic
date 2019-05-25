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
        var patternTypes: [UUID: Unification.T] = [:]

        public init() {}

        private var typeNameGenerator = NameGenerator(prefix: "?")

        func makeGenericName() -> String {
            return typeNameGenerator.next()
        }

        func makeEvar() -> Unification.T {
            return .evar(makeGenericName())
        }
    }

    public func makeUnificationContext(scopeContext: Environment.ScopeContext) -> UnificationContext {
        var traversalConfig = LGCSyntaxNode.TraversalConfig(order: .pre)

        return self.reduce(config: &traversalConfig, initialResult: UnificationContext()) { (result, node, config) in
//            Swift.print("pre", node.nodeTypeDescription)

            config.needsRevisitAfterTraversingChildren = true

            switch (config.isRevisit, node) {
            case (true, .statement(.branch(id: _, condition: let condition, block: _))):
                result.nodes[condition.uuid] = .cons(name: "Boolean")

                return result
            case (false, .declaration(.function(id: _, name: _, returnType: _, parameters: let parameters, block: _))):

                parameters.forEach { parameter in
                    switch parameter {
                    case .parameter(id: _, externalName: _, localName: let pattern, annotation: let annotation, defaultValue: _):
                        let annotationType = annotation.unificationType { result.makeGenericName() }

                        result.nodes[pattern.uuid] = annotationType
//                        result.constraints.append(Unification.Constraint(annotationType, result.nodes[defaultValue.uuid]!))
                        result.patternTypes[pattern.uuid] = annotationType
                    default:
                        break
                    }
                }
            case (true, .declaration(.variable(id: _, name: let pattern, annotation: let annotation, initializer: let initializer))):
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

                // TODO: If this doesn't exist, we probably need to implement another node
                if let initializerType = result.nodes[initializer.uuid] {
                    result.constraints.append(Unification.Constraint(annotationType, initializerType))
                } else {
                    Swift.print("No initializer type for \(initializer.uuid)")
                }

                result.patternTypes[pattern.uuid] = annotationType

                return result
            case (true, .expression(.identifierExpression(id: _, identifier: let identifier))):
                let typeVariable = result.makeEvar()

                result.nodes[node.uuid] = typeVariable
                result.nodes[identifier.uuid] = typeVariable

                if let patternId = scopeContext.identifierToPattern[identifier.uuid], let scopedType = result.patternTypes[patternId] {
                    result.constraints.append(.init(scopedType, typeVariable))
                }

                return result
            case (true, .expression(.functionCallExpression(id: _, expression: let expression, arguments: let arguments))):
                let calleeType = result.nodes[expression.uuid]!

                // Unify against these to enforce a function type
                let placeholderReturnType = result.makeEvar()
                let placeholderArgType = result.makeEvar()
                let placeholderFunctionType: Unification.T = .fun(arguments: [placeholderArgType], returnType: placeholderReturnType)

                result.constraints.append(.init(calleeType, placeholderFunctionType))

                result.nodes[node.uuid] = placeholderReturnType

                // TODO: Currently we're hardcoding a single argument
                let argumentValues = arguments.map { $0.expression }
                let arg0 = argumentValues[0]

                result.constraints.append(Unification.Constraint(placeholderArgType, result.nodes[arg0.uuid]!))

                return result
            case (true, .expression(.memberExpression(id: _, expression: let expression, memberName: _))):
                // TODO: Determine dynamically (currently hardcoded to Optional)
                let argType = result.makeEvar()
                let functionCallType: Unification.T = .fun(arguments: [argType], returnType: .cons(name: "Optional", parameters: [argType]))
                result.nodes[node.uuid] = functionCallType

                return result
            case (true, .expression(.literalExpression(id: _, literal: let literal))):
                result.nodes[node.uuid] = result.nodes[literal.uuid]!

                return result
            case (true, .expression(.binaryExpression(left: let left, right: let right, op: let op, id: _))):
                switch op {
                case .isEqualTo, .isNotEqualTo, .isLessThan, .isGreaterThan, .isLessThanOrEqualTo, .isGreaterThanOrEqualTo:
                    result.nodes[node.uuid] = .cons(name: "Boolean")
                    result.constraints.append(Unification.Constraint(result.nodes[left.uuid]!, result.nodes[right.uuid]!))
                    return result
                case .setEqualTo: // TODO
                    break
                }
            case (true, .literal(.boolean)):
                result.nodes[node.uuid] = .cons(name: "Boolean")

                return result
            case (true, .literal(.number)):
                result.nodes[node.uuid] = .cons(name: "Number")

                return result
            case (true, .literal(.string)):
                result.nodes[node.uuid] = .cons(name: "String")

                return result
            default:
                break
            }

            return result
        }
    }
}
