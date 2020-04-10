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
        public var constraintDebugInfo: [(String, [UUID])] = []
        public var nodes: [UUID: Unification.T] = [:]
        public var patternTypes: [UUID: Unification.T] = [:]

        public init() {}

        private var typeNameGenerator = NameGenerator(prefix: "?")

        func makeGenericName() -> String {
            return typeNameGenerator.next()
        }

        func makeEvar() -> Unification.T {
            return .evar(makeGenericName())
        }

        func addConstraint(_ constraint: Unification.Constraint, _ description: String, _ nodes: [UUID]) {
            constraints.append(constraint)
            constraintDebugInfo.append((description, nodes))
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
        var traversalConfig =  TraversalConfig(order: .pre)

        func walk(_ result: UnificationContext, _ node: LGCSyntaxNode, config:  TraversalConfig) -> UnificationContext {
            config.needsRevisitAfterTraversingChildren = true

            switch (config.isRevisit, node) {
            case (true, .statement(.branch(id: _, condition: let condition, block: _))):
                result.nodes[condition.uuid] = .bool

                return result
            case (true, .statement(.returnStatement(id: let id, expression: let expression))):
                guard let annotation: LGCTypeAnnotation = rootNode.pathTo(id: id)?.reversed().dropFirst().reduce(nil, { acc, item in
                    if acc != nil { return acc }

                    switch item {
                    case .declaration(.function(id: _, name: _, returnType: let returnType, genericParameters: _, parameters: _, block: _, comment: _)):
                        return returnType
                    default:
                        return nil
                    }
                }) else {
                    Swift.print("WARNING: Return statement not within function (found during unification)")
                    return result
                }

                let expressionType = result.nodes[expression.uuid] ?? result.makeEvar()

                // TODO: Handle generic return
                let returnType = annotation.unificationType(genericsInScope: [:]) { result.makeGenericName() }

                result.addConstraint(
                    Unification.Constraint(expressionType, returnType),
                    "Return Statement <-> Function Return Type",
                    [node.uuid, expression.uuid]
                )

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
                let returnType: Unification.T = .cons(name: functionName.name, parameters: universalTypes)

                var parameterTypes: [Unification.FunctionArgument] = []

                declarations.forEach { declaration in
                    switch declaration {
                    case .variable(id: _, name: let pattern, annotation: let annotation, initializer: let initializer, _):
                        guard let annotation = annotation else { break }

                        let annotationType = annotation.unificationType(genericsInScope: [:]) { result.makeGenericName() }

                        parameterTypes.append(Unification.FunctionArgument(label: pattern.name, type: annotationType))

                        // Synthesize getter function

                        let functionType: Unification.T = .fun(
                            arguments: [
                                Unification.FunctionArgument(label: nil, type: returnType)
                            ],
                            returnType: annotationType
                        )

                        result.nodes[pattern.uuid] = functionType
                        result.patternTypes[pattern.uuid] = functionType

                        if let initializer = initializer {
                            _ = LGCSyntaxNode.expression(initializer).reduce(config: config, initialResult: result, f: walk)

                            // TODO: If this doesn't exist, we probably need to implement another node
                            if let initializerType = result.nodes[initializer.uuid] {
                                result.addConstraint(
                                    Unification.Constraint(annotationType, initializerType),
                                    "Record Variable Type Annotation <-> Initializer",
                                    [node.uuid, initializer.uuid]
                                )
                            } else {
                                Swift.print("WARNING: No initializer type for \(initializer.uuid)")
                            }

                        }
                    default:
                        break
                    }
                }

                // Handle children (initializers) manually since we want to hide member variables and only expose getters
                config.ignoreChildren = true

                let functionType: Unification.T = .fun(arguments: parameterTypes, returnType: returnType)

                result.nodes[functionName.uuid] = functionType
                result.patternTypes[functionName.uuid] = functionType
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
                                    label: nil,
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

                // Generic function parameters don't use namespace scoping, so we rename them here.
                // TODO: Is there a different way we can make these unambiguous
                var genericInScope: [String: String] = [:]
                genericNames.forEach { name in
                    genericInScope[name] = result.makeGenericName()
                }

                var parameterTypes: [Unification.FunctionArgument] = []

                parameters.forEach { parameter in
                    switch parameter {
                    case .parameter(id: _, localName: let pattern, annotation: let annotation, defaultValue: _, _):
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
                    result.addConstraint(
                        Unification.Constraint(annotationType, initializerType),
                        "Variable Type Annotation <-> Initializer",
                        [node.uuid, initializer.uuid]
                    )
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

                // Unify against these to enforce a function type
                let placeholderReturnType = result.makeEvar()
                let placeholderArgTypes: [Unification.FunctionArgument] = arguments.compactMap { argument in
                    switch argument {
                    case .argument(_, let label, _):
                        return Unification.FunctionArgument(label: label, type: result.makeEvar())
                    case .placeholder:
                        return nil
                    }
                }
                let placeholderFunctionType: Unification.T = .fun(arguments: placeholderArgTypes, returnType: placeholderReturnType)

                result.addConstraint(
                    .init(calleeType, placeholderFunctionType),
                    "Function Call Expression <-> Callee Expression + [Args]",
                    [node.uuid, expression.uuid] + arguments.filter { !$0.isPlaceholder }.map { LGCSyntaxNode.functionCallArgument($0).uuid }
                )

                result.nodes[node.uuid] = placeholderReturnType

                let argumentValues: [LGCExpression] = arguments.compactMap { argument in
                    switch argument {
                    case .argument(_, _, let expression):
                        return expression
                    case .placeholder:
                        return nil
                    }
                }

                zip(placeholderArgTypes, argumentValues).forEach { (argType, argValue) in
                    result.addConstraint(
                        Unification.Constraint(argType.type, result.nodes[argValue.uuid]!),
                        "Function Call Argument",
                        [argValue.uuid]
                    )
                }
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
//                    Swift.print("Evar for \(expression): \(expressionType)")
                    result.addConstraint(
                        Unification.Constraint(elementType, expressionType),
                        "Array Literal <-> Element Expression",
                        [node.uuid, expression.uuid]
                    )
                }
            default:
                break
            }

            return result
        }

        return rootNode.reduce(config: traversalConfig, initialResult: initialContext, f: walk)
    }
}
