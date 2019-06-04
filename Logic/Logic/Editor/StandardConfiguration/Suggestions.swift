//
//  Suggestions.swift
//  Logic
//
//  Created by Devin Abbott on 6/4/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

public enum StandardConfiguration {
    public enum LogLevel {
        case none, verbose
    }

    public static func literalSuggestions(for type: Unification.T, query: String) -> [LogicSuggestionItem] {
        switch type {
        case .evar:
            return []
        case .bool:
            let literals: [LogicSuggestionItem] = [
                LGCLiteral.Suggestion.true,
                LGCLiteral.Suggestion.false
                ].compactMap(LGCExpression.Suggestion.from(literalSuggestion:))

            return literals.titleContains(prefix: query)
        case .number:
            let literals: [LogicSuggestionItem] = [
                LGCLiteral.Suggestion.rationalNumber(for: query)
                ].compactMap(LGCExpression.Suggestion.from(literalSuggestion:))

            return literals.titleContains(prefix: query)
        case .string:
            let literals: [LogicSuggestionItem] = [
                LGCLiteral.Suggestion.string(for: query)
                ].compactMap(LGCExpression.Suggestion.from(literalSuggestion:))

            return literals.titleContains(prefix: query)
        case .cssColor:
            let literals: [LogicSuggestionItem] = [
                LGCLiteral.Suggestion.color(for: query)
                ].compactMap(LGCExpression.Suggestion.from(literalSuggestion:))

            return literals
        case .cons(name: "Array", _):
            let literals: [LogicSuggestionItem] = [
                LGCLiteral.Suggestion.array(for: query)
                ].compactMap(LGCExpression.Suggestion.from(literalSuggestion:))

            return literals
        default:
            return []
        }
    }

    public static func suggestionsForNode(
        rootNode: LGCSyntaxNode,
        node: LGCSyntaxNode,
        query: String,
        logLevel: LogLevel = LogLevel.none
        ) -> [LogicSuggestionItem]? {

        if logLevel == .verbose {
            Swift.print("---------")
        }

        let scopeContext = Compiler.scopeContext(rootNode)
        let unificationContext = Compiler.makeUnificationContext(rootNode, scopeContext: scopeContext)

        if logLevel == .verbose {
            Swift.print("Unification context", unificationContext.constraints, unificationContext.nodes)
        }

        guard case .success(let substitution) = Unification.unify(constraints: unificationContext.constraints) else {
            Swift.print("Unification failed", Unification.unify(constraints: unificationContext.constraints))
            return []
        }

        if logLevel == .verbose {
            Swift.print("Substitution", substitution)
        }

        let currentScopeContext = Compiler.scopeContext(rootNode, targetId: node.uuid)

        if logLevel == .verbose {
            Swift.print("Current scope", currentScopeContext.namesInScope)
        }

        switch node {
        case .typeAnnotation:
            return currentScopeContext.patternToTypeName.map { key, value in
                let node = rootNode.pathTo(id: key)?.last(where: { item in
                    switch item {
                    case .declaration:
                        return true
                    default:
                        return false
                    }
                })

                switch node {
                case .some(.declaration(.enumeration(id: _, name: _, genericParameters: let genericParameters, cases: _))),
                     .some(.declaration(.record(id: _, name: _, genericParameters: let genericParameters, declarations: _))):
                    let parameterNames: [String] = genericParameters.compactMap { param in
                        switch param {
                        case .parameter(_, name: let pattern):
                            return pattern.name
                        case .placeholder:
                            return nil
                        }
                    }

                    if parameterNames.contains(value) {
                        return LGCTypeAnnotation.Suggestion.from(type: .cons(name: value))
                    }

                    let params: [Unification.T] = genericParameters.compactMap { param in
                        switch param {
                        case .parameter(id: _, name: let pattern):
                            return .evar(pattern.name)
                        case .placeholder:
                            return nil
                        }
                    }
                    return LGCTypeAnnotation.Suggestion.from(type: .cons(name: value, parameters: params))
                default:
                    break
                }

                return LGCTypeAnnotation.Suggestion.from(type: .cons(name: value, parameters: []))
                }.titleContains(prefix: query)
        case .expression(let expression):
            guard let unificationType = unificationContext.nodes[expression.uuid] else {
                Swift.print("Can't determine suggestions - no type for expression", expression.uuid)
                return []
            }

            let type = Unification.substitute(substitution, in: unificationType)

            if logLevel == .verbose {
                Swift.print("Resolved type: \(type)")
            }

            let common: [LogicSuggestionItem] = [
                LGCExpression.Suggestion.comparison,
            ]

            switch type {
            case .gen:
                return []
            case .fun:
                // TODO: Suggestion functions?
                return []
            case .evar:
                let matchingIdentifiers = currentScopeContext.namesInScope

                let literals: [LogicSuggestionItem] = [
                    LGCLiteral.Suggestion.true,
                    LGCLiteral.Suggestion.false,
                    LGCLiteral.Suggestion.rationalNumber(for: query)
                    ].compactMap(LGCExpression.Suggestion.from(literalSuggestion:))

                let identifiers: [LogicSuggestionItem] = matchingIdentifiers.map(LGCExpression.Suggestion.identifier)

                return (literals + identifiers + common).titleContains(prefix: query)
            case .cons:
                func validSuggestionType(expressionType: Unification.T, suggestionType: Unification.T) -> Unification.T? {
                    if expressionType == suggestionType {
                        return suggestionType
                    }

                    switch suggestionType {
                    case .fun(arguments: _, returnType: let returnType):
                        if expressionType == returnType {
                            return suggestionType
                        }

                        let specificReturnType = returnType.replacingGenericsWithEvars(getName: NameGenerator(prefix: "&").next)
                        let unified = Unification.unify(
                            constraints: [Unification.Constraint(specificReturnType, type)]
                        )

                        switch unified {
                        case .success(let substitution):
                            let substitutedType = Unification.substitute(substitution, in: suggestionType)
                            Swift.print("Specific instance of generic type", suggestionType, "=>", substitutedType)
                            return substitutedType
                        case .failure:
                            return nil
                        }
                    default:
                        return nil
                    }
                }

                let matchingNamespaceIdentifiers = currentScopeContext.namespace.flattened.compactMap({ keyPath, pattern -> ([String], Unification.T)? in
                    // Variables in scope are listed elsewhere
                    if keyPath.count == 1 { return nil }

                    guard let identifierType = unificationContext.patternTypes[pattern] else { return nil }

                    let resolvedType = Unification.substitute(substitution, in: identifierType)

                    //                        Swift.print("Resolved type of pattern, \(keyPath.joined(separator: ".")): \(identifierType) == \(resolvedType)")

                    if let suggestionType = validSuggestionType(expressionType: type, suggestionType: resolvedType) {
                        return (keyPath, suggestionType)
                    } else {
                        return nil
                    }
                })

                //                    Swift.print("Namespace identifiers", matchingNamespaceIdentifiers)

                let matchingIdentifiers = currentScopeContext.patternsInScope.compactMap({ pattern -> (String, Unification.T)? in
                    guard let identifierType = unificationContext.patternTypes[pattern.uuid] else { return nil }

                    let resolvedType = Unification.substitute(substitution, in: identifierType)

                    //                        Swift.print("Resolved type of pattern, \(pattern.name): \(identifierType) == \(resolvedType)")

                    if let suggestionType = validSuggestionType(expressionType: type, suggestionType: resolvedType) {
                        return (pattern.name, suggestionType)
                    } else {
                        return nil
                    }
                })

                //                    Swift.print("Matching ids", matchingIdentifiers)

                let namespaceIdentifiers: [LogicSuggestionItem] = matchingNamespaceIdentifiers.map { (keyPath, resolvedType) in
                    switch resolvedType {
                    case .fun(arguments: let arguments, returnType: _):
                        return LogicSuggestionItem(
                            title: keyPath.joined(separator: "."),
                            category: "FUNCTIONS",
                            node: .expression(
                                .functionCallExpression(
                                    id: UUID(),
                                    expression: LGCExpression.makeMemberExpression(names: keyPath),
                                    arguments: LGCList<LGCFunctionCallArgument>(
                                        arguments.map { arg in
                                            LGCFunctionCallArgument(
                                                id: UUID(),
                                                label: nil,
                                                expression: .identifierExpression(
                                                    id: UUID(),
                                                    identifier: .init(id: UUID(), string: "value", isPlaceholder: true)
                                                )
                                            )
                                        }
                                    )
                                )
                            )
                        )
                    default:
                        return LGCExpression.Suggestion.memberExpression(names: keyPath)
                    }
                }

                let identifiers: [LogicSuggestionItem] = matchingIdentifiers.map { (keyPath, resolvedType) in
                    switch resolvedType {
                    case .fun(arguments: let arguments, returnType: _):
                        return LogicSuggestionItem(
                            title: keyPath,
                            category: "FUNCTIONS",
                            node: .expression(
                                .functionCallExpression(
                                    id: UUID(),
                                    expression: .identifierExpression(id: UUID(), identifier: .init(id: UUID(), string: keyPath)),
                                    arguments: LGCList<LGCFunctionCallArgument>(
                                        arguments.map { arg in
                                            LGCFunctionCallArgument(
                                                id: UUID(),
                                                label: nil,
                                                expression: .identifierExpression(
                                                    id: UUID(),
                                                    identifier: .init(id: UUID(), string: "value", isPlaceholder: true)
                                                )
                                            )
                                        }
                                    )
                                )
                            )
                        )
                    default:
                        return LGCExpression.Suggestion.identifier(name: keyPath)
                    }
                }

                let literals = literalSuggestions(for: type, query: query)

                return literals + (identifiers + namespaceIdentifiers + common).titleContains(prefix: query)
            }
        default:
            return nil
        }
    }
}

