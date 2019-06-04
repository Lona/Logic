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

        logicEditor.rootNode = .program(
            .init(
                id: UUID(),
                block: .init(
                    [
                        .declaration(id: UUID(), content:
                            .importDeclaration(id: UUID(), name: .init(id: UUID(), name: "Prelude"))
                        ),
                        .makePlaceholder()
                    ]
                )
            )
        )
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
        var colorValues: [UUID: String] = [:]

        logicEditor.decorationForNodeID = { id in
            guard let node = self.logicEditor.rootNode.find(id: id) else { return nil }

            if let colorValue = colorValues[node.uuid] {
                return .color(NSColor.parse(css: colorValue) ?? NSColor.black)
            }

            if let annotation = annotations[node.uuid] {
                return .label(labelFont, annotation)
            }

            switch node {
            case .literal(.color(id: _, value: let color)):
                return .color(NSColor.parse(css: color) ?? NSColor.black)
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
        
        logicEditor.suggestionsForNode = { rootNode, node, query in
            Swift.print("---------")

            guard case .program(let root) = rootNode else { return [] }

            let program: LGCSyntaxNode = .program(root.expandImports(importLoader: Library.load))

            let scopeContext = Compiler.scopeContext(program)
            let unificationContext = Compiler.makeUnificationContext(program, scopeContext: scopeContext)

//            Swift.print("Unification context", unificationContext.constraints, unificationContext.nodes)

            guard case .success(let substitution) = Unification.unify(constraints: unificationContext.constraints) else {
                Swift.print("Unification failed", Unification.unify(constraints: unificationContext.constraints))
                return []
            }

//            Swift.print("Substitution", substitution)

            let currentScopeContext = Compiler.scopeContext(program, targetId: node.uuid)

//            Swift.print("Current scope", currentScopeContext.namesInScope)

            switch node {
            case .typeAnnotation:
                return currentScopeContext.patternToTypeName.map { key, value in
                    let node = program.pathTo(id: key)?.last(where: { item in
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
//                    Swift.print("Resolved type: \(type)")

                    let matchingIdentifiers = currentScopeContext.namesInScope

                    let literals: [LogicSuggestionItem] = [
                        LGCLiteral.Suggestion.true,
                        LGCLiteral.Suggestion.false,
                        LGCLiteral.Suggestion.rationalNumber(for: query)
                        ].compactMap(LGCExpression.Suggestion.from(literalSuggestion:))

                    let identifiers: [LogicSuggestionItem] = matchingIdentifiers.map(LGCExpression.Suggestion.identifier)

                    return (literals + identifiers + common).titleContains(prefix: query)
                case .cons:
//                    Swift.print("Resolved type: \(type)")

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

                    let literals = suggestions(for: type, query: query)

                    return literals + (identifiers + namespaceIdentifiers + common).titleContains(prefix: query)
                }
            default:
                return LogicEditor.defaultSuggestionsForNode(program, node, query)
            }
        }

        logicEditor.onChangeRootNode = { [unowned self] rootNode in
            self.logicEditor.rootNode = rootNode

            let rootNode = self.logicEditor.rootNode

            guard case .program(let root) = rootNode else { return true }

            let program: LGCSyntaxNode = .program(root.expandImports(importLoader: Library.load))

            let scopeContext = Compiler.scopeContext(program)
            let unificationContext = Compiler.makeUnificationContext(program, scopeContext: scopeContext)

            guard case .success(let substitution) = Unification.unify(constraints: unificationContext.constraints) else {
                return true
            }

            // TODO: Evaluate program, not just rootNode
            let result = Compiler.evaluate(program, rootNode: program, scopeContext: scopeContext, unificationContext: unificationContext, substitution: substitution, context: .init())

            annotations.removeAll(keepingCapacity: true)
            colorValues.removeAll(keepingCapacity: true)

            switch result {
            case .success(let evaluationContext):
//                Swift.print("Result", evaluationContext.values)

                evaluationContext.values.forEach { id, value in
                    annotations[id] = "\(value.memory)"

//                    Swift.print(id, value.type, value.memory)

                    if let colorString = value.colorString {
                        colorValues[id] = colorString
                    }
                }
            case .failure(let error):
                Swift.print("Eval failure", error)
            }

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

