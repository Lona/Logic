//
//  Document.swift
//  LogicDesigner
//
//  Created by Devin Abbott on 2/16/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import AppKit
import Logic

class Document: NSDocument {

    override init() {
        super.init()
    }

    override class var autosavesInPlace: Bool {
        return false
    }

    var window: NSWindow?

    let logicEditor = LogicEditor()
    let containerView = NSBox()

    override func makeWindowControllers() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false)

        containerView.boxType = .custom
        containerView.borderType = .noBorder
        containerView.contentViewMargins = .zero

        containerView.addSubview(logicEditor)

        containerView.translatesAutoresizingMaskIntoConstraints = false
        logicEditor.translatesAutoresizingMaskIntoConstraints = false

        logicEditor.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        logicEditor.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
        logicEditor.leadingAnchor.constraint(equalTo: containerView.leadingAnchor).isActive = true
        logicEditor.trailingAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true

        logicEditor.showsDropdown = true
//        logicEditor.rootNode = .topLevelParameters(
//            LGCTopLevelParameters(id: UUID(), parameters: .next(.placeholder(id: UUID()), .empty))
//        )

        let labelFont = TextStyle(family: "San Francisco", weight: .bold, size: 9).nsFont

        var annotations: [UUID: String] = [:]

        logicEditor.decorationForNodeID = { id in
            guard let node = self.logicEditor.rootNode.find(id: id) else { return nil }

            if let annotation = annotations[node.uuid] {
                return .label(labelFont, annotation)
            }

            switch node {
            case .literal(.color(id: _, value: _)):
                return .color(.red)
            case .identifier(let identifier) where identifier.string.starts(with: "TextStyles."):
                return .character(TextStyle(size: 18, color: .purple).apply(to: "S"), .purple)
            default:
                return nil
            }
        }

        func suggestions(for type: Unification.T, query: String) -> [LogicSuggestionItem] {
            switch type {
            case .evar:
                return []
            case .cons(name: "Boolean", parameters: []):
                let literals: [LogicSuggestionItem] = [
                    LGCLiteral.Suggestion.true,
                    LGCLiteral.Suggestion.false
                    ].compactMap(LGCExpression.Suggestion.from(literalSuggestion:))

                return literals
            case .cons(name: "Number", parameters: []):
                let literals: [LogicSuggestionItem] = [
                    LGCLiteral.Suggestion.rationalNumber(for: query)
                    ].compactMap(LGCExpression.Suggestion.from(literalSuggestion:))

                return literals
            case .cons(name: "String", parameters: []):
                let literals: [LogicSuggestionItem] = [
                    LGCLiteral.Suggestion.string(for: query)
                    ].compactMap(LGCExpression.Suggestion.from(literalSuggestion:))

                return literals
            case .cons(name: "Optional", parameters: let parameters) where parameters.count == 1:
                let innerSuggestions = suggestions(for: parameters[0], query: query)

                let wrappedSuggestions: [LogicSuggestionItem] = innerSuggestions.compactMap { item in
                    guard case .expression(let contents) = item.node else { return nil }

                    return LogicSuggestionItem(
                        title: ".value(\(item.title))",
                        badge: "Optional",
                        category: LGCExpression.Suggestion.categoryTitle,
                        node: .expression(
                            .functionCallExpression(
                                id: UUID(),
                                expression: .makeMemberExpression(names: ["Optional", "value"]),
                                arguments: .next(
                                    .init(id: UUID(), label: nil, expression: contents),
                                    .empty
                                )
                            )
                        )
                    )
                }

                let noneSuggestion = LogicSuggestionItem(
                    title: ".none",
                    badge: "Optional",
                    category: LGCExpression.Suggestion.categoryTitle,
                    node: .expression(
                        .functionCallExpression(
                            id: UUID(),
                            expression: .makeMemberExpression(names: ["Optional", "none"]),
                            arguments: .empty
                        )
                    )
                )

                return wrappedSuggestions + [noneSuggestion]
            default:
                return []
            }
        }
        
        logicEditor.suggestionsForNode = { [unowned self] node, query in
            Swift.print("---------")

            let rootNode = self.logicEditor.rootNode

            Swift.print(Compiler.scopeContext(rootNode).namespace)

            let baseProgram = StandardLibrary.program

            let baseScopeContext = Compiler.scopeContext(baseProgram)
            let baseUnificationContext = baseProgram.makeUnificationContext(scopeContext: baseScopeContext)

            let scopeContext = Compiler.scopeContext(rootNode, initialContext: baseScopeContext)
            let unificationContext = rootNode.makeUnificationContext(scopeContext: scopeContext, initialContext: baseUnificationContext)

            Swift.print("Unification context", unificationContext.constraints, unificationContext.nodes)

            guard case .success(let substitution) = Unification.unify(constraints: unificationContext.constraints) else {
                Swift.print("Unification failed", Unification.unify(constraints: unificationContext.constraints))
                return []
            }

            Swift.print("Substitution", substitution)

            let currentBaseScopeContext = Compiler.scopeContext(baseProgram)
            let currentScopeContext = Compiler.scopeContext(rootNode, targetId: node.uuid, initialContext: currentBaseScopeContext)

            Swift.print("Current scope", currentScopeContext.namesInScope)

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
                    }) ?? baseProgram.pathTo(id: key)?.last(where: { item in
                        switch item {
                        case .declaration:
                            return true
                        default:
                            return false
                        }
                    })

                    switch node {
                    case .some(.declaration(.enumeration(id: _, name: _, genericParameters: let genericParameters, cases: _))):
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

                let common: [LogicSuggestionItem] = [
                    LGCExpression.Suggestion.comparison,
                ]

                switch type {
                case .fun:
                    // TODO: Suggestion functions?
                    return []
                case .evar:
                    Swift.print("Resolved type: \(type)")

                    let matchingIdentifiers = currentScopeContext.namesInScope

                    let literals: [LogicSuggestionItem] = [
                        LGCLiteral.Suggestion.true,
                        LGCLiteral.Suggestion.false,
                        LGCLiteral.Suggestion.rationalNumber(for: query)
                        ].compactMap(LGCExpression.Suggestion.from(literalSuggestion:))

                    let identifiers: [LogicSuggestionItem] = matchingIdentifiers.map(LGCExpression.Suggestion.identifier)

                    return (literals + identifiers + common).titleContains(prefix: query)
                case .cons:
                    Swift.print("Resolved type: \(type)")

                    let matchingNamespaceIdentifiers = currentScopeContext.namespace.flattened.compactMap({ keyPath, pattern -> ([String], Unification.T)? in
                        // Variables in scope are listed elsewhere
                        if keyPath.count == 1 { return nil }

                        guard let identifierType = unificationContext.patternTypes[pattern] else { return nil }

                        let resolvedType = Unification.substitute(substitution, in: identifierType)

                        Swift.print("Resolved type of pattern \(pattern): \(identifierType) == \(resolvedType)")

                        if type == resolvedType {
                            return (keyPath, resolvedType)
                        }

                        switch resolvedType {
                        case .fun(arguments: _, returnType: let returnType) where type == returnType:
                            return (keyPath, resolvedType)
                        default:
                            return nil
                        }
                    })

                    Swift.print("namespace identifiers", matchingNamespaceIdentifiers)

                    let matchingIdentifiers = currentScopeContext.patternsInScope.compactMap({ pattern -> (String, Unification.T)? in
                        guard let identifierType = unificationContext.patternTypes[pattern.uuid] else { return nil }

                        let resolvedType = Unification.substitute(substitution, in: identifierType)

                        Swift.print("Resolved type of pattern \(pattern.uuid): \(identifierType) == \(resolvedType)")

                        if type == resolvedType {
                            return (pattern.name, resolvedType)
                        }

                        switch resolvedType {
                        case .fun(arguments: _, returnType: let returnType) where type == returnType:
                            return (pattern.name, resolvedType)
                        default:
                            return nil
                        }
                    })

                    Swift.print("Matching ids", matchingIdentifiers)

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

                    let literals = suggestions(for: type, query: query)

                    return (identifiers + namespaceIdentifiers + literals + common).titleContains(prefix: query)
                }
            default:
                return LogicEditor.defaultSuggestionsForNode(node, self.logicEditor.rootNode, query)
            }
        }

        logicEditor.onChangeRootNode = { [unowned self] rootNode in
            self.logicEditor.rootNode = rootNode

            return true

//            do {
////                let compilerContext = try Environment.compile(rootNode, in: .standard)
//
////                Swift.print(compilerContext.nodeType, compilerContext.scopes)
//
//                let context = try Environment.evaluate(rootNode, in: .standard).1
//
////                Swift.print(context.scopes)
//
//                annotations = context.annotations
//
//                self.logicEditor.underlinedId = nil
//            } catch let error {
//                if let error = error as? CompilerError {
////                    Swift.print("Compiler error", error)
//
//                    // TODO:
////                    self.logicEditor.underlinedId = error.nodeId
//                }
//
//                if let error = error as? LogicError {
//                    annotations = error.context.annotations
//
//                    // TODO:
////                    self.logicEditor.underlinedId = error.nodeId
//                }
//            }
//
//            return true
        }

        window.backgroundColor = Colors.background
        window.center()
        window.contentView = containerView

        self.window = window

        let windowController = NSWindowController(window: window)
        windowController.showWindow(nil)
        addWindowController(windowController)
    }

    override func data(ofType typeName: String) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        return try encoder.encode(logicEditor.rootNode)
    }

    override func read(from data: Data, ofType typeName: String) throws {
        logicEditor.rootNode = try JSONDecoder().decode(LGCSyntaxNode.self, from: data)
    }
}

