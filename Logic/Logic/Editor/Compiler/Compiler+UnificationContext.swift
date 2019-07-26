//
//  LGCSyntax+Unification.swift
//  Logic
//
//  Created by Devin Abbott on 5/28/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

extension Compiler {
    public class UnificationContext {
        public var constraints: [Unification.Constraint] = []
        public var nodes: [UUID: Unification.T] = [:]
        public var patternTypes: [UUID: Unification.T] = [:]
        public var functionArgumentLabels: [UUID: [String]] = [:]

        public init() {}

        private var typeNameGenerator = NameGenerator(prefix: "?")

        func makeGenericName() -> String {
            return typeNameGenerator.next()
        }

        func makeEvar() -> Unification.T {
            return .evar(makeGenericName())
        }
    }

    private static func specificIdentifierType(
        scopeContext: Compiler.ScopeContext,
        unificationContext: UnificationContext,
        identifierId: UUID
        ) -> Unification.T {
        if let patternId = scopeContext.identifierToPattern[identifierId], let scopedType = unificationContext.patternTypes[patternId] {
            return scopedType.replacingGenericsWithEvars(getName: unificationContext.makeGenericName)
        } else {
            return unificationContext.makeEvar()
        }
    }

    public static func makeUnificationContext(
        _ rootNode: LGCSyntaxNode,
        scopeContext: Compiler.ScopeContext,
        initialContext: UnificationContext = UnificationContext()
        ) -> UnificationContext {
        var traversalConfig = LGCSyntaxNode.TraversalConfig(order: .pre)

        return rootNode.reduce(config: &traversalConfig, initialResult: initialContext) { (result, node, config) in
            //            Swift.print("pre", node.nodeTypeDescription)

            config.needsRevisitAfterTraversingChildren = true

            switch (config.isRevisit, node) {
            case (true, .statement(.branch(id: _, condition: let condition, block: _))):
                result.nodes[condition.uuid] = .bool

                return result
            case (false, .declaration(.record(id: _, name: let functionName, genericParameters: let genericParameters, declarations: let declarations, _))):
                let genericNames: [String] = genericParameters.compactMap { param in
                    switch param {
                    case .parameter(_, name: let pattern):
                        return pattern.name
                    case .placeholder:
                        return nil
                    }
                }

                var genericInScope: [String: String] = [:]
                genericNames.forEach { name in
                    genericInScope[name] = result.makeGenericName()
                }

                let universalTypes = genericNames.map { name in Unification.T.gen(genericInScope[name]!) }

                var parameterTypes: [Unification.FunctionArgument] = []

                var labels: [String] = []

                declarations.forEach { declaration in
                    switch declaration {
                    case .variable(id: _, name: let pattern, annotation: let annotation, initializer: _, _):
                        guard let annotation = annotation else { break }

                        labels.append(pattern.name)

                        let annotationType = annotation.unificationType(genericsInScope: [:]) { result.makeGenericName() }

                        parameterTypes.append(Unification.FunctionArgument(label: pattern.name, type: annotationType))

                        result.nodes[pattern.uuid] = annotationType
                        //                        result.constraints.append(Unification.Constraint(annotationType, result.nodes[defaultValue.uuid]!))
                        result.patternTypes[pattern.uuid] = annotationType
                    default:
                        break
                    }
                }

                let returnType: Unification.T = .cons(name: functionName.name, parameters: universalTypes)
                let functionType: Unification.T = .fun(arguments: parameterTypes, returnType: returnType)

                result.nodes[functionName.uuid] = functionType
                result.patternTypes[functionName.uuid] = functionType
                result.functionArgumentLabels[functionName.uuid] = labels
            case (false, .declaration(.enumeration(_, name: let functionName, genericParameters: let genericParameters, cases: let enumCases, _))):
                let genericNames: [String] = genericParameters.compactMap { param in
                    switch param {
                    case .parameter(_, name: let pattern):
                        return pattern.name
                    case .placeholder:
                        return nil
                    }
                }

                var genericInScope: [String: String] = [:]
                genericNames.forEach { name in
                    genericInScope[name] = result.makeGenericName()
                }

                let universalTypes = genericNames.map { name in Unification.T.gen(genericInScope[name]!) }

                let returnType: Unification.T = .cons(name: functionName.name, parameters: universalTypes)

                enumCases.forEach { enumCase in
                    switch enumCase {
                    case .placeholder:
                        break
                    case .enumerationCase(_, name: let pattern, associatedValueTypes: let associatedValueTypes, _):
                        let parameterTypes: [Unification.FunctionArgument] = associatedValueTypes.compactMap { annotation in
                            switch annotation {
                            case .placeholder:
                                return nil
                            default:
                                return Unification.FunctionArgument(
                                    label: pattern.name,
                                    type: annotation.unificationType(genericsInScope: genericInScope) { result.makeGenericName() }
                                )
                            }
                        }

                        let functionType: Unification.T = .fun(arguments: parameterTypes, returnType: returnType)

                        result.nodes[pattern.uuid] = functionType
                        result.patternTypes[pattern.uuid] = functionType
                    }
                }

                // Not used for unification, but used for convenience in evaluation
                result.nodes[functionName.uuid] = returnType
                result.patternTypes[functionName.uuid] = returnType
            case (false, .declaration(.function(id: _, name: let functionName, returnType: let returnTypeAnnotation, genericParameters: let genericParameters, parameters: let parameters, block: _, _))):

                let genericNames: [String] = genericParameters.compactMap { param in
                    switch param {
                    case .parameter(_, name: let pattern):
                        return pattern.name
                    case .placeholder:
                        return nil
                    }
                }

                var genericInScope: [String: String] = [:]
                genericNames.forEach { name in
                    genericInScope[name] = result.makeGenericName()
                }

                var parameterTypes: [Unification.FunctionArgument] = []

                parameters.forEach { parameter in
                    switch parameter {
                    case .parameter(id: _, externalName: _, localName: let pattern, annotation: let annotation, defaultValue: _):
                        let annotationType = annotation.unificationType(genericsInScope: genericInScope) { result.makeGenericName() }

                        parameterTypes.append(Unification.FunctionArgument(label: pattern.name, type: annotationType))

                        result.nodes[pattern.uuid] = annotationType
                        //                        result.constraints.append(Unification.Constraint(annotationType, result.nodes[defaultValue.uuid]!))
                        result.patternTypes[pattern.uuid] = annotationType
                    default:
                        break
                    }
                }

                let returnType = returnTypeAnnotation.unificationType(genericsInScope: genericInScope) { result.makeGenericName() }
                let functionType: Unification.T = .fun(arguments: parameterTypes, returnType: returnType)

                result.nodes[functionName.uuid] = functionType
                result.patternTypes[functionName.uuid] = functionType
            case (true, .declaration(.variable(id: _, name: let pattern, annotation: let annotation, initializer: let initializer, _))):
                guard let initializer = initializer, let annotation = annotation else {
                    config.ignoreChildren = true
                    return result
                }

                if annotation.isPlaceholder {
                    config.ignoreChildren = true
                    return result
                }

                let annotationType = annotation.unificationType(genericsInScope: [:]) { result.makeGenericName() }

                result.nodes[pattern.uuid] = annotationType

                // TODO: If this doesn't exist, we probably need to implement another node
                if let initializerType = result.nodes[initializer.uuid] {
                    result.constraints.append(Unification.Constraint(annotationType, initializerType))
                } else {
                    Swift.print("WARNING: No initializer type for \(initializer.uuid)")
                }

                result.patternTypes[pattern.uuid] = annotationType

                return result
            case (true, .expression(.placeholder)):
                let type = result.makeEvar()

                result.nodes[node.uuid] = type

                return result
            case (true, .expression(.identifierExpression(id: _, identifier: let identifier))):
                let type = self.specificIdentifierType(scopeContext: scopeContext, unificationContext: result, identifierId: identifier.uuid)

                result.nodes[node.uuid] = type
                result.nodes[identifier.uuid] = type

                return result
            case (true, .expression(.functionCallExpression(id: _, expression: let expression, arguments: let arguments))):
                let calleeType = result.nodes[expression.uuid]!

                guard case .fun(let targetArguments, let targetReturnType) = calleeType else {
                    fatalError("Functions must currently be called by directly (not indirectly, via a reference)")
                }

                result.nodes[node.uuid] = targetReturnType

                arguments.forEach { argument in
                    switch argument {
                    case .argument(let value):
                        // TODO: Values without labels will need positional handling, if we allow them at all
                        guard let targetArgument = targetArguments.first(where: { $0.label == value.label }) else { break }

                        result.constraints.append(Unification.Constraint(targetArgument.type, result.nodes[value.expression.uuid]!))
                    case .placeholder:
                        break
                    }
                }

                return result
            case (false, .expression(.memberExpression)):
                // The only supported children are identifiers currently, and we will handle them here when we revisit them
                config.ignoreChildren = true

            case (true, .expression(.memberExpression)):
                let type = self.specificIdentifierType(scopeContext: scopeContext, unificationContext: result, identifierId: node.uuid)

                result.nodes[node.uuid] = type

                return result
            case (true, .expression(.literalExpression(id: _, literal: let literal))):
                result.nodes[node.uuid] = result.nodes[literal.uuid]!

                return result
            case (true, .expression(.binaryExpression(left: let left, right: let right, op: let op, id: _))):
                switch op {
                case .isEqualTo, .isNotEqualTo, .isLessThan, .isGreaterThan, .isLessThanOrEqualTo, .isGreaterThanOrEqualTo:
                    result.nodes[node.uuid] = Unification.T.bool
                    result.constraints.append(Unification.Constraint(result.nodes[left.uuid]!, result.nodes[right.uuid]!))
                    return result
                case .setEqualTo: // TODO
                    break
                }
            case (true, .literal(.boolean)):
                result.nodes[node.uuid] = Unification.T.bool

                return result
            case (true, .literal(.number)):
                result.nodes[node.uuid] = Unification.T.number

                return result
            case (true, .literal(.string)):
                result.nodes[node.uuid] = Unification.T.string

                return result
            case (true, .literal(.color)):
                result.nodes[node.uuid] = Unification.T.color

                return result
            case (true, .literal(.array(id: _, value: let expressions))):
                let elementType = result.makeEvar()
                result.nodes[node.uuid] = .array(elementType)

                expressions.forEach { expression in
                    let expressionType = result.nodes[expression.uuid] ?? result.makeEvar()
                    Swift.print("Evar for \(expression): \(expressionType)")
                    result.constraints.append(Unification.Constraint(elementType, expressionType))
                }
            default:
                break
            }

            return result
        }
    }
}
