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

        logicEditor.suggestionsForNode = { [unowned self] node, query in
            Swift.print("---------")

            let rootNode = self.logicEditor.rootNode

            switch node {
            case .expression(let expression):
                let unificationContext = rootNode.makeUnificationContext()

                Swift.print("Unification context", unificationContext.constraints, unificationContext.nodes)

                guard case .success(let substitution) = Unification.unify(constraints: unificationContext.constraints) else {
                    Swift.print("Unification failed")
                    return []
                }

                Swift.print("Substitution", substitution)

                guard let unificationType = unificationContext.nodes[expression.uuid] else {
                    Swift.print("Can't determine suggestions - no type for expression", expression.uuid)
                    return []
                }

                let type = Unification.substitute(substitution, in: unificationType)

                let currentScope = Environment.scope(rootNode, targetId: node.uuid).flattened

                Swift.print("Scope", currentScope)

                let common: [LogicSuggestionItem] = [
                    LGCExpression.Suggestion.comparison,
                ]

                switch type {
                case .evar:
                    Swift.print("Resolved type: \(type)")

                    let matchingIdentifiers = currentScope.values

                    let literals: [LogicSuggestionItem] = [
                        LGCLiteral.Suggestion.true,
                        LGCLiteral.Suggestion.false,
                        LGCLiteral.Suggestion.rationalNumber(for: query)
                        ].compactMap(LGCExpression.Suggestion.from(literalSuggestion:))

                    let identifiers: [LogicSuggestionItem] = matchingIdentifiers.map(LGCExpression.Suggestion.identifier)

                    return (literals + identifiers + common).titleContains(prefix: query)
                case .cons(name: let name, parameters: _):
                    Swift.print("Resolved type: \(type)")

                    let matchingIdentifiers: [String] = currentScope.keys.compactMap({ nodeId in
                        guard let identifierType = unificationContext.nodes[nodeId] else { return nil }

                        let resolvedType = Unification.substitute(substitution, in: identifierType)

                        Swift.print("Resolved type of \(nodeId): \(identifierType) == \(resolvedType)")

                        if type == resolvedType {
                            return currentScope[nodeId]
                        }

                        return nil
                    })

                    Swift.print("Matching ids", matchingIdentifiers)

                    let identifiers: [LogicSuggestionItem] = matchingIdentifiers.map(LGCExpression.Suggestion.identifier)

                    switch name {
                    case "Boolean":
                        let literals: [LogicSuggestionItem] = [
                            LGCLiteral.Suggestion.true,
                            LGCLiteral.Suggestion.false
                            ].compactMap(LGCExpression.Suggestion.from(literalSuggestion:))

                        return (identifiers + literals + common).titleContains(prefix: query)
                    case "Number":
                        let literals: [LogicSuggestionItem] = [
                            LGCLiteral.Suggestion.rationalNumber(for: query)
                            ].compactMap(LGCExpression.Suggestion.from(literalSuggestion:))

                        return (identifiers + literals + common).titleContains(prefix: query)
                    default:
                        return (identifiers + common).titleContains(prefix: query)
                    }
                }
            default:
                return LogicEditor.defaultSuggestionsForNode(node, self.logicEditor.rootNode, query)
            }
        }

        logicEditor.onChangeRootNode = { [unowned self] rootNode in
            self.logicEditor.rootNode = rootNode

            do {
                let compilerContext = try Environment.compile(rootNode, in: .standard)

//                Swift.print(compilerContext.nodeType, compilerContext.scopes)

                let context = try Environment.evaluate(rootNode, in: .standard).1

//                Swift.print(context.scopes)

                annotations = context.annotations

                self.logicEditor.underlinedId = nil
            } catch let error {
                if let error = error as? CompilerError {
//                    Swift.print("Compiler error", error)

                    // TODO:
//                    self.logicEditor.underlinedId = error.nodeId
                }

                if let error = error as? LogicError {
                    annotations = error.context.annotations

                    // TODO:
//                    self.logicEditor.underlinedId = error.nodeId
                }
            }

            return true
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

