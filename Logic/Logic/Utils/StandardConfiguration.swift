//
//  StandardConfiguration.swift
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

    public static func isValidSuggestionType(expressionType: Unification.T, suggestionType: Unification.T) -> Unification.T? {
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
                constraints: [Unification.Constraint(specificReturnType, expressionType)]
            )

            switch unified {
            case .success(let substitution):
                let substitutedType = Unification.substitute(substitution, in: suggestionType)
//                Swift.print("Specific instance of generic type", suggestionType, "=>", substitutedType)
                return substitutedType
            case .failure:
                return nil
            }
        default:
            return nil
        }
    }

    public static func literalSuggestions(for type: Unification.T, query: String, node: LGCSyntaxNode) -> [LogicSuggestionItem] {
        switch type {
        case .evar:
            return []
        case .bool:
            let expressions: [LogicSuggestionItem] = [
                LGCLiteral.Suggestion.true,
                LGCLiteral.Suggestion.false
                ].compactMap(LGCExpression.Suggestion.from(literalSuggestion:))

            return expressions.titleContains(prefix: query)
        case .number:
            let expressions: [LogicSuggestionItem] = [
                LGCLiteral.Suggestion.rationalNumber(for: query)
                ].compactMap(LGCExpression.Suggestion.from(literalSuggestion:))

            return expressions.titleContains(prefix: query)
        case .string:
            let expressions: [LogicSuggestionItem] = [
                LGCLiteral.Suggestion.string(for: query)
                ].compactMap(LGCExpression.Suggestion.from(literalSuggestion:))

            return expressions.titleContains(prefix: query)
        case .color:
            let literals: [LogicSuggestionItem]

            switch (query, node) {
            case ("", .expression(.literalExpression(_, literal: .color(_, value: let cssString)))):
                literals = [
                    LGCLiteral.Suggestion.color(for: cssString)
                ]
            default:
                literals = [
                    LGCLiteral.Suggestion.color(for: query)
                ]
            }

            let expressions = literals.compactMap(LGCExpression.Suggestion.from(literalSuggestion:))

            return expressions
        case .cons(name: "Array", _):
            let expressions: [LogicSuggestionItem] = [
                LGCLiteral.Suggestion.array(for: query)
                ].compactMap(LGCExpression.Suggestion.from(literalSuggestion:))

            return expressions
        default:
            return []
        }
    }

    public typealias CompilerContext = (
        scope: Compiler.ScopeContext,
        unification: Compiler.UnificationContext,
        substitution: Unification.Substitution
    )

    public static func compile(_ rootNode: LGCSyntaxNode) -> (
        scope: Compiler.ScopeContext,
        unification: Compiler.UnificationContext,
        substitution: Result<Unification.Substitution, Unification.UnificationError>
        ) {
        let scopeContext = Compiler.scopeContext(rootNode)
        let unificationContext = Compiler.makeUnificationContext(rootNode, scopeContext: scopeContext)
        let substitutionResult = Unification.unify(constraints: unificationContext.constraints)

        return (scopeContext, unificationContext, substitutionResult)
    }

    public static func suggestions(
        rootNode: LGCSyntaxNode,
        node: LGCSyntaxNode,
        query: String,
        currentScopeContext: Compiler.ScopeContext,
        scopeContext: Compiler.ScopeContext,
        unificationContext: Compiler.UnificationContext,
        substitution: Unification.Substitution,
        evaluationContext: Compiler.EvaluationContext?,
        formattingOptions: LogicFormattingOptions,
        logLevel: LogLevel = LogLevel.none
        ) -> [LogicSuggestionItem]? {

        switch node {
        case .functionCallArgument(let currentArgument):
            guard let parent = rootNode.pathTo(id: node.uuid)?.dropLast().last else { return nil }

            switch parent {
            case .expression(.functionCallExpression(let value)):
                guard let unificationType = unificationContext.nodes[value.expression.uuid] else {
                    Swift.print("Can't determine function call argument suggestions - no type for expression", parent.uuid)
                    return nil
                }

                let type = Unification.substitute(substitution, in: unificationType)

                guard case .fun(let targetArguments, _) = type else {
                    Swift.print("Invalid call expression - only function types are callable")
                    return nil
                }

                let existingArgumentLabels: [String] = value.arguments.compactMap {
                    switch $0 {
                    case .argument(let value):
                        return value.label
                    case .placeholder:
                        return nil
                    }
                }

                let availableArguments: [Unification.FunctionArgument] = targetArguments.filter { argument in
                    guard let label = argument.label else { return false }
                    let available = !existingArgumentLabels.contains(label)
                    switch currentArgument {
                    case .argument(_, let argumentLabel, _):
                        return available || argumentLabel == label
                    case .placeholder:
                        return available
                    }
                }

                if logLevel == .verbose {
                    Swift.print("Resolved argument type: \(type)")
                }

                return availableArguments.map { argument in
                    var labelComment: String?

                    if case .identifierExpression(_, identifier: let identifier) = value.expression,
                        let definitionNameId = scopeContext.identifierToPattern[identifier.uuid],
                        let definitionNode = rootNode.contents.parentOf(target: definitionNameId, includeTopLevel: false),
                        case .declaration(.record(let record)) = definitionNode {

                        record.declarations.forEach { declaration in
                            switch declaration {
                            case .variable(_, let labelPattern, _, _, _) where labelPattern.name == argument.label:
                                if let comment = declaration.comment(within: rootNode) {
                                    labelComment = comment
                                }
                            default:
                                break
                            }
                        }
                    }

                    var suggestion = LogicSuggestionItem(
                        title: argument.label ?? "",
                        category: "ARGUMENTS",
                        node: .functionCallArgument(
                            .argument(
                                id: UUID(),
                                label: argument.label ?? "Invalid argument label",
                                expression: .identifierExpression(
                                    id: UUID(),
                                    identifier: .init(id: UUID(), string: "value", isPlaceholder: true)
                                )
                            )
                        )
                    )

                    if let comment = labelComment {
                        suggestion.documentation = { _ in
                            return LightMark.makeScrollView(LightMark.parse(comment), renderingOptions: .init(formattingOptions: formattingOptions))
                        }
                    }

                    return suggestion
                }.titleContains(prefix: query)
            default:
                return nil
            }
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
                case .some(.declaration(.enumeration(id: _, name: _, genericParameters: let genericParameters, cases: _, _))),
                     .some(.declaration(.record(id: _, name: _, genericParameters: let genericParameters, declarations: _, _))):
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

                    var suggestion = LGCTypeAnnotation.Suggestion.from(type: .cons(name: value, parameters: params))

                    if let comment = node?.comment(within: rootNode) {
                        suggestion.documentation = { _ in
                            return LightMark.makeScrollView(LightMark.parse(comment), renderingOptions: .init(formattingOptions: formattingOptions))
                        }
                    }

                    return suggestion
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

            var common: [LogicSuggestionItem] = []

            switch type {
            case .bool:
                common.append(LGCExpression.Suggestion.comparison)
            default:
                break
            }

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
                func getIdentifierPaths(
                    scopeContext: Compiler.ScopeContext,
                    unificationContext: Compiler.UnificationContext
                    ) -> [(keyPath: [String], id: UUID)] {

                    let currentScopePaths = currentScopeContext.patternsInScope.map({ pattern -> ([String], UUID) in
                        return ([pattern.name], pattern.uuid)
                    })

                    let namespacePaths = currentScopeContext.namespace.pairs.compactMap({ keyPath, id -> ([String], UUID)? in

                        // Ignore variables in scope, which are listed by their shortest name
                        if currentScopePaths.contains(where: { id == $1 }) { return nil }

                        return (keyPath, id)
                    })

                    return namespacePaths + currentScopePaths
                }

                func getValidSuggestionsPaths(
                    expressionType: Unification.T,
                    identifierPaths: [(keyPath: [String], id: UUID)],
                    unificationContext: Compiler.UnificationContext
                    ) -> [(id: UUID, keyPath: [String], type: Unification.T)] {
                    return identifierPaths.compactMap({ keyPath, id -> (UUID, [String], Unification.T)? in
                        guard let identifierType = unificationContext.patternTypes[id] else { return nil }

                        let resolvedType = Unification.substitute(substitution, in: identifierType)

                        if keyPath == ["Optional", "value"] {
                            return nil
                        }

                        if let suggestionType = isValidSuggestionType(expressionType: expressionType, suggestionType: resolvedType) {
                            return (id, keyPath, suggestionType)
                        } else {
                            return nil
                        }
                    })
                }

                func getMatchingSuggestions(
                    validSuggestionPaths: [(id: UUID, keyPath: [String], type: Unification.T)]
                    ) -> [LogicSuggestionItem] {
                    return validSuggestionPaths.map { (id, keyPath, resolvedType) in
                        switch resolvedType {
                        case .fun:
                            var suggestion = LGCExpression.Suggestion.functionCall(
                                keyPath: keyPath,
                                arguments: [
                                    .placeholder(id: UUID())
                                ]
                            )

                            if let comment = rootNode.find(id: id)?.comment(within: rootNode) {
                                suggestion.documentation = { _ in
                                    return LightMark.makeScrollView(LightMark.parse(comment), renderingOptions: .init(formattingOptions: formattingOptions))
                                }
                            }

                            return suggestion
                        default:
                            var suggestion = LGCExpression.Suggestion.memberExpression(names: keyPath)

                            if let comment = rootNode.find(id: id)?.comment(within: rootNode) {
                                suggestion.documentation = { _ in
                                    return LightMark.makeScrollView(LightMark.parse(comment), renderingOptions: .init(formattingOptions: formattingOptions))
                                }
                            }

                            switch resolvedType {
                            case Unification.T.color:
                                guard let colorString = evaluationContext?.values[id]?.colorString else { break }
                                suggestion.style = .colorPreview(code: colorString, NSColor.parse(css: colorString) ?? .black)
                                return suggestion
                            default:
                                break
                            }

                            if let memory = evaluationContext?.values[id]?.memory {
                                switch memory {
                                case .bool, .number, .string:
                                    suggestion.badge = evaluationContext?.values[id]?.memory.debugDescription
                                default:
                                    suggestion.badge = resolvedType.debugDescription
                                }
                            }

                            return suggestion
                        }
                    }
                }

                let identifierPaths = getIdentifierPaths(
                    scopeContext: currentScopeContext,
                    unificationContext: unificationContext
                )

                let validSuggestionPaths = getValidSuggestionsPaths(
                    expressionType: type,
                    identifierPaths: identifierPaths,
                    unificationContext: unificationContext
                )

                let matchingSuggestions = getMatchingSuggestions(validSuggestionPaths: validSuggestionPaths)

                let literals = literalSuggestions(for: type, query: query, node: node)

                var nested: [LogicSuggestionItem] = []

                switch type {
                case .cons(name: "Optional", parameters: let parameters):
                    guard let wrappedType = parameters.first else { return [] }

                    let wrappedValidPaths = getValidSuggestionsPaths(
                        expressionType: wrappedType,
                        identifierPaths: identifierPaths,
                        unificationContext: unificationContext
                    )

                    let wrappedSuggestions = literalSuggestions(for: wrappedType, query: query, node: node) +
                        getMatchingSuggestions(validSuggestionPaths: wrappedValidPaths).titleContains(prefix: query)

                    let updatedSuggestions: [LogicSuggestionItem] = wrappedSuggestions.compactMap { suggestion in
                        guard case .expression(let expression) = suggestion.node else { return nil }

                        var copy = suggestion

                        copy.node = .expression(
                            .functionCallExpression(
                                id: UUID(),
                                expression: LGCExpression.makeMemberExpression(names: ["Optional", "value"]),
                                arguments: .init(
                                    [
                                        .argument(id: UUID(), label: nil, expression: expression)
                                    ]
                                )
                            )
                        )
                        return copy
                    }

                    nested.append(contentsOf: updatedSuggestions)
                default:
                    break
                }

                return literals + nested.sortedByPrefix() + (matchingSuggestions.sortedByPrefix() + common).titleContains(prefix: query)
            }
        default:
            return nil
        }

    }

    public static func suggestions(
        rootNode: LGCSyntaxNode,
        node: LGCSyntaxNode,
        query: String,
        formattingOptions: LogicFormattingOptions,
        logLevel: LogLevel = LogLevel.none
        ) -> [LogicSuggestionItem]? {
        let (scopeContext, unificationContext, substitutionResult) = compile(rootNode)

        if logLevel == .verbose {
            Swift.print("---------")
            Swift.print("Unification context", unificationContext.constraints, unificationContext.nodes)
        }

        let substitution: Unification.Substitution

        do {
            substitution = try substitutionResult.get()
        } catch let error {
            Swift.print("Failed to unify, \(error)")
            return nil
        }

        if logLevel == .verbose {
            Swift.print("Substitution", substitution)
        }

        let currentScopeContext = Compiler.scopeContext(rootNode, targetId: node.uuid)

        if logLevel == .verbose {
            Swift.print("Current scope", currentScopeContext.namesInScope)
        }

        let evaluationContext = try? Compiler.evaluate(
            rootNode,
            rootNode: rootNode,
            scopeContext: scopeContext,
            unificationContext: unificationContext,
            substitution: substitution,
            context: .init()
            ).get()

        return suggestions(
            rootNode: rootNode,
            node: node,
            query: query,
            currentScopeContext: currentScopeContext,
            scopeContext: scopeContext,
            unificationContext: unificationContext,
            substitution: substitution,
            evaluationContext: evaluationContext,
            formattingOptions: formattingOptions,
            logLevel: logLevel
        )
    }
}

