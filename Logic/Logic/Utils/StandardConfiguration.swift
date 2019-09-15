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

    public static func literalSuggestions(for type: Unification.T, query: String, existingNode: LGCSyntaxNode?) -> [LogicSuggestionItem] {
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

            switch (query, existingNode) {
            case ("", .some(.expression(.literalExpression(_, literal: .color(_, value: let cssString))))):
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

    public static func expressionSuggestion(
        rootNode: LGCSyntaxNode,
        node: LGCSyntaxNode?,
        type: Unification.T,
        query: String,
        currentScopeContext: Compiler.ScopeContext,
        scopeContext: Compiler.ScopeContext,
        unificationContext: Compiler.UnificationContext,
        substitution: Unification.Substitution,
        evaluationContext: Compiler.EvaluationContext?,
        formattingOptions: LogicFormattingOptions,
        logLevel: LogLevel = LogLevel.none
    ) -> [LogicSuggestionItem]? {
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
            // If we're within a variable declaration, we don't want to suggest the variable name as an identifier.
            // This will cause an infinite loop/crash during execution
            // TODO: We can prevent the crash and show an error by traversing the thunk dependency graph
            func getSelfReferentialNamespacePaths() -> [[String]] {
                guard let node = node, let path = rootNode.pathTo(id: node.uuid) else { return [] }

                return path.dropLast().compactMap { ancestor in
                    switch ancestor {
                    case .declaration(.variable(_, _, _, initializer: .some(let initializer), _)) where initializer.find(id: node.uuid) != nil:
                        return rootNode.declarationPath(id: node.uuid)
                    default:
                        return nil
                    }
                }
            }

            func getIdentifierPaths() -> [(keyPath: [String], id: UUID)] {
                let currentScopePaths = currentScopeContext.patternsInScope.map({ pattern -> ([String], UUID) in
                    return ([pattern.name], pattern.uuid)
                })

                let namespacePaths = scopeContext.namespace.pairs.compactMap({ keyPath, id -> ([String], UUID)? in
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
                    case .fun(let arguments, _):
                        var suggestion: LogicSuggestionItem

                        // Positional arguments
                        if arguments.contains(where: { $0.label == nil }) {
                            suggestion = LGCExpression.Suggestion.functionCall(
                                keyPath: keyPath,
                                arguments: arguments.enumerated().map({ index, arg in
                                    LGCFunctionCallArgument.argument(
                                        id: UUID(),
                                        label: nil,
                                        expression: .identifierExpression(
                                            id: UUID(),
                                            identifier: .init(id: UUID(), string: "value", isPlaceholder: true)
                                        )
                                    )
                                })
                            )
                        } else {
                            suggestion = LGCExpression.Suggestion.functionCall(
                                keyPath: keyPath,
                                arguments: [.placeholder(id: UUID())]
                            )
                        }

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
                            guard let colorString = evaluationContext?.evaluate(uuid: id)?.colorString else { break }
                            suggestion.style = .colorPreview(code: colorString, NSColor.parse(css: colorString) ?? .black)
                            return suggestion
                        default:
                            break
                        }

                        if let memory = evaluationContext?.evaluate(uuid: id)?.memory {
                            switch memory {
                            case .bool, .number, .string:
                                suggestion.badge = evaluationContext?.evaluate(uuid: id)?.memory.debugDescription
                            default:
                                suggestion.badge = resolvedType.debugDescription
                            }
                        }

                        return suggestion
                    }
                }
            }

            let selfReferentialNamespacePaths = getSelfReferentialNamespacePaths()

            let identifierPaths = getIdentifierPaths().filter({ !selfReferentialNamespacePaths.contains($0.keyPath) })

            let validSuggestionPaths = getValidSuggestionsPaths(
                expressionType: type,
                identifierPaths: identifierPaths,
                unificationContext: unificationContext
                ).filter({ !selfReferentialNamespacePaths.contains($0.keyPath) })

            let matchingSuggestions = getMatchingSuggestions(validSuggestionPaths: validSuggestionPaths)

            let literals = literalSuggestions(for: type, query: query, existingNode: node)

            var nested: [LogicSuggestionItem] = []

            switch type {
            case .cons(name: "Optional", parameters: let parameters):
                guard let wrappedType = parameters.first else { return [] }

                let wrappedValidPaths = getValidSuggestionsPaths(
                    expressionType: wrappedType,
                    identifierPaths: identifierPaths,
                    unificationContext: unificationContext
                )

                let wrappedSuggestions = literalSuggestions(for: wrappedType, query: query, existingNode: node) +
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

                let containsLabels = targetArguments.contains(where: { $0.label != nil })

                if !containsLabels {
                    guard let currentIndex = value.arguments.firstIndex(of: currentArgument) else {
                        Swift.print("Unexpected argument")
                        return []
                    }

                    guard targetArguments.count > currentIndex else {
                        Swift.print("No more arguments exist")
                        return []
                    }

                    let targetUnificationType = targetArguments[currentIndex].type
                    let targetType = Unification.substitute(substitution, in: targetUnificationType)

                    let argumentExpression: LGCExpression?

                    switch currentArgument {
                    case .argument(_, label: .none, expression: let expression):
                        argumentExpression = expression
                    case .argument, .placeholder:
                        argumentExpression = nil
                    }

                    let expressionSuggestions = expressionSuggestion(
                        rootNode: rootNode,
                        node: argumentExpression?.node,
                        type: targetType,
                        query: query,
                        currentScopeContext: currentScopeContext,
                        scopeContext: scopeContext,
                        unificationContext: unificationContext,
                        substitution: substitution,
                        evaluationContext: evaluationContext,
                        formattingOptions: formattingOptions,
                        logLevel: logLevel
                    )

                    return expressionSuggestions?.map { suggestion in
                        var suggestion = suggestion

                        suggestion.node = .functionCallArgument(
                            .argument(id: UUID(), label: nil, expression: suggestion.node.contents as! LGCExpression)
                        )

                        return suggestion
                    }
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

                    switch value.expression {
                    case .identifierExpression(_, identifier: let identifier):
                        if let definitionNameId = scopeContext.identifierToPattern[identifier.uuid],
                            let definitionNode = rootNode.contents.parentOf(target: definitionNameId, includeTopLevel: false) {
                            switch definitionNode {
                            case .declaration(.record(let record)):
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
                            default:
                                Swift.print("Unhandled definition")
                            }
                        }
                    case .memberExpression:
                        guard let flattened = value.expression.flattenedMemberExpression else { break }

                        let namespacePaths = currentScopeContext.namespace.pairs.compactMap({ keyPath, id -> ([String], UUID)? in
                            return (keyPath, id)
                        })

                        guard let (_, patternId) = namespacePaths.first(where: { $0.0 == flattened.map { $0.string } }) else { break }

                        if let definitionNode = rootNode.contents.parentOf(target: patternId, includeTopLevel: false) {
                            switch definitionNode {
                            case .declaration(.function(let function)):
                                function.parameters.forEach { parameter in
                                    switch parameter {
                                    case .parameter(_, _, let localName, _, _, _) where localName.name == argument.label:
                                        if let comment = parameter.comment(within: rootNode) {
                                            labelComment = comment
                                        }
                                    case .placeholder, .parameter:
                                        break
                                    }
                                }
                            case .declaration(.record(let record)):
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
                            default:
                                break
                            }
                        }
                    default:
                        break
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
            func getTypePaths() -> [(keyPath: [String], id: UUID)] {
                let currentScopePaths = currentScopeContext.typesInScope.map({ pattern -> ([String], UUID) in
                    return ([pattern.name], pattern.uuid)
                })

                let namespacePaths = currentScopeContext.typeNamespace.pairs.compactMap({ keyPath, id -> ([String], UUID)? in
                    // Ignore variables in scope, which are listed by their shortest name
                    if currentScopePaths.contains(where: { id == $1 }) { return nil }

                    return (keyPath, id)
                })

                return namespacePaths + currentScopePaths
            }

            return getTypePaths()
                .map({ keyPath, uuid in
                    if keyPath.count != 1 { fatalError("Types must be declared at the top-level namespace for now") }

                    let key = uuid
                    let value = keyPath.last!
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
                }).titleContains(prefix: query)
        case .expression(let expression):
            guard let unificationType = unificationContext.nodes[expression.uuid] else {
                Swift.print("Can't determine suggestions - no type for expression", expression.uuid)
                return []
            }

            let type = Unification.substitute(substitution, in: unificationType)

            return expressionSuggestion(
                rootNode: rootNode,
                node: node,
                type: type,
                query: query,
                currentScopeContext: currentScopeContext,
                scopeContext: scopeContext,
                unificationContext: unificationContext,
                substitution: substitution,
                evaluationContext: evaluationContext,
                formattingOptions: formattingOptions,
                logLevel: logLevel
            )
        default:
            return nil
        }

    }

    public static func suggestions(
        rootNode: LGCSyntaxNode,
        node: LGCSyntaxNode,
        formattingOptions: LogicFormattingOptions,
        logLevel: LogLevel = LogLevel.none
        ) -> ((String) -> [LogicSuggestionItem]?)? {
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

        return { query in
            suggestions(
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

    // Formatter Arguments

    public static func formatArguments(
        rootNode: LGCSyntaxNode,
        id: UUID,
        unificationContext: Compiler.UnificationContext?,
        substitution: Unification.Substitution?
        ) -> LogicFormattingOptions.ArgumentsFormat? {
        guard let node = rootNode.find(id: id) else { return nil }

        switch node {
        case .expression(let expression):
            let flattened = expression.flattenedMemberExpression?.map({ $0.string })
            if flattened == ["Optional", "value"] {
                return (1, false, false)
            } else if flattened == ["Optional", "none"] {
                return (0, true, false)
            } else {
                break
            }
        default:
            break
        }

        if let unificationContext = unificationContext, let substitution = substitution {
            if let type = unificationContext.nodes[node.uuid] {
                let resolvedType = Unification.substitute(substitution, in: type)
                switch resolvedType {
                case .fun(arguments: let arguments, returnType: _):
                    return (arguments.count, true, arguments.count > 0)
                default:
                    break
                }
            }
        }

        return nil
    }

    // Menu

    public enum MenuAction {
        case addComment(UUID)
        case duplicate(UUID)
        case delete(UUID)
        case insertAbove(UUID)
        case insertBelow(UUID)
        case replace(UUID)
    }

    public static func handleMenuItem(logicEditor: LogicEditor, action: MenuAction) {
        switch action {
        case .replace(let id):
            logicEditor.select(nodeByID: id)
        case .delete(let id):
            logicEditor.rootNode = logicEditor.rootNode.delete(id: id)
        case .duplicate(let id):
            if let duplicated = logicEditor.rootNode.duplicate(id: id) {
                logicEditor.rootNode = duplicated.rootNode
                logicEditor.select(nodeByID: nil)
            }
        case .insertAbove(let id):
            if let inserted = logicEditor.rootNode.insert(.above, id: id) {
                logicEditor.rootNode = inserted.rootNode
                logicEditor.select(nodeByID: inserted.insertedNode.uuid)
            }
        case .insertBelow(let id):
            if let node = logicEditor.rootNode.find(id: id),
                let contents = node.contents as? SyntaxNodePlaceholdable,
                contents.isPlaceholder {
                logicEditor.select(nodeByID: node.uuid)
            } else if let inserted = logicEditor.rootNode.insert(.below, id: id) {
                logicEditor.rootNode = inserted.rootNode
                logicEditor.select(nodeByID: inserted.insertedNode.uuid)
            }
        case .addComment(let id):
            guard let node = logicEditor.rootNode.find(id: id) else { return }

            switch node {
            case .functionParameter(.parameter(let value)):
                logicEditor.rootNode = logicEditor.rootNode.replace(
                    id: id,
                    with: .functionParameter(
                        .parameter(
                            id: UUID(),
                            externalName: value.externalName,
                            localName: value.localName,
                            annotation: value.annotation,
                            defaultValue: value.defaultValue,
                            comment: value.comment ?? .init(id: UUID(), string: "A comment")
                        )
                    )
                )
            case .declaration(.variable(let value)):
                logicEditor.rootNode = logicEditor.rootNode.replace(
                    id: id,
                    with: .declaration(
                        .variable(
                            id: UUID(),
                            name: value.name,
                            annotation: value.annotation,
                            initializer: value.initializer,
                            comment: value.comment ?? .init(id: UUID(), string: "A comment")
                        )
                    )
                )
            case .declaration(.record(let value)):
                logicEditor.rootNode = logicEditor.rootNode.replace(
                    id: id,
                    with: .declaration(
                        .record(
                            id: UUID(),
                            name: value.name,
                            genericParameters: value.genericParameters,
                            declarations: value.declarations,
                            comment: value.comment ?? .init(id: UUID(), string: "A comment")
                        )
                    )
                )
            case .declaration(.enumeration(let value)):
                logicEditor.rootNode = logicEditor.rootNode.replace(
                    id: id,
                    with: .declaration(
                        .enumeration(
                            id: UUID(),
                            name: value.name,
                            genericParameters: value.genericParameters,
                            cases: value.cases,
                            comment: value.comment ?? .init(id: UUID(), string: "A comment")
                        )
                    )
                )
            case .declaration(.function(let value)):
                logicEditor.rootNode = logicEditor.rootNode.replace(
                    id: id,
                    with: .declaration(
                        .function(
                            id: UUID(),
                            name: value.name,
                            returnType: value.returnType,
                            genericParameters: value.genericParameters,
                            parameters: value.parameters,
                            block: value.block,
                            comment: value.comment ?? .init(id: UUID(), string: "A comment")
                        )
                    )
                )
            case .enumerationCase(.enumerationCase(let value)):
                logicEditor.rootNode = logicEditor.rootNode.replace(
                    id: id,
                    with: .enumerationCase(
                        .enumerationCase(
                            id: UUID(),
                            name: value.name,
                            associatedValueTypes: value.associatedValueTypes,
                            comment: value.comment ?? .init(id: UUID(), string: "A comment")
                        )
                    )
                )
            default:
                break
            }

            break
        }
    }

    public static func menu(rootNode: LGCSyntaxNode, node: LGCSyntaxNode, allowComments: Bool, handleMenuAction: @escaping (MenuAction) -> Void) -> [LogicEditor.MenuItem]? {
        func makeContextMenu(for node: LGCSyntaxNode) -> [LogicEditor.MenuItem]? {
            var menu: [LogicEditor.MenuItem] = [
                .init(row: .sectionHeader("ACTIONS"), action: {})
            ]

            func makeMenuItem(title: String, action: MenuAction) -> LogicEditor.MenuItem {
                return .init(row: .row(title, nil, false, nil, nil), action: { handleMenuAction(action) })
            }

            switch node {
            case .statement(.declaration(id: _, content: let declaration)):
                if allowComments {
                    menu.append(makeMenuItem(title: "Add comment", action: MenuAction.addComment(declaration.uuid)))
                }
                menu.append(makeMenuItem(title: "Duplicate", action: MenuAction.duplicate(node.uuid)))
                menu.append(makeMenuItem(title: "Delete", action: MenuAction.delete(node.uuid)))
            case .declaration(let value):
                menu.append(makeMenuItem(title: "Insert above", action: MenuAction.insertAbove(node.uuid)))
                menu.append(makeMenuItem(title: "Insert below", action: MenuAction.insertBelow(node.uuid)))
                if allowComments {
                    menu.append(makeMenuItem(title: "Add comment", action: MenuAction.addComment(value.uuid)))
                }
                menu.append(makeMenuItem(title: "Duplicate", action: MenuAction.duplicate(node.uuid)))
                menu.append(makeMenuItem(title: "Delete", action: MenuAction.delete(node.uuid)))
            case .enumerationCase(.enumerationCase(let value)):
                if allowComments {
                    menu.append(makeMenuItem(title: "Add comment", action: MenuAction.addComment(value.id)))
                }
            case .functionParameter(.parameter(let value)):
                if allowComments {
                    menu.append(makeMenuItem(title: "Add comment", action: MenuAction.addComment(value.id)))
                }
            default:
                return nil
            }

            menu.append(makeMenuItem(title: "Replace", action: MenuAction.replace(node.uuid)))

            return menu
        }

        switch node {
        case .pattern:
            guard let parent = rootNode.contents.parentOf(target: node.uuid, includeTopLevel: false) else { return nil }
            return makeContextMenu(for: parent)
        default:
            return makeContextMenu(for: node)
        }
    }
}

