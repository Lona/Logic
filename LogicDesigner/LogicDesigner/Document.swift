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

        logicEditor.rootNode = .topLevelDeclarations(
            .init(
                id: UUID(),
                declarations: LGCList<LGCDeclaration>.init(
                    [
                        .importDeclaration(id: UUID(), name: .init(id: UUID(), name: "Prelude")),
                        .makePlaceholder()
                    ]
                )
            )
        )

//        logicEditor.rootNode = .program(
//            .init(
//                id: UUID(),
//                block: .init(
//                    [
//                        .declaration(id: UUID(), content:
//                            .importDeclaration(id: UUID(), name: .init(id: UUID(), name: "Prelude"))
//                        ),
//                        .makePlaceholder()
//                    ]
//                )
//            )
//        )
    }

    override class var autosavesInPlace: Bool {
        return false
    }

    var window: NSWindow?

    let logicEditor = LogicEditor()
    let infoBar = InfoBar()
    let divider = Divider()
    let containerView = NSBox()

    let editorDisplayStyles: [LogicFormattingOptions.Style] = [.visual, .natural, .js]

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
        containerView.addSubview(infoBar)
        containerView.addSubview(divider)

        containerView.translatesAutoresizingMaskIntoConstraints = false
        logicEditor.translatesAutoresizingMaskIntoConstraints = false
        infoBar.translatesAutoresizingMaskIntoConstraints = false
        divider.translatesAutoresizingMaskIntoConstraints = false

        logicEditor.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        logicEditor.leadingAnchor.constraint(equalTo: containerView.leadingAnchor).isActive = true
        logicEditor.trailingAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true

        logicEditor.bottomAnchor.constraint(equalTo: divider.topAnchor).isActive = true

        divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
        divider.leadingAnchor.constraint(equalTo: containerView.leadingAnchor).isActive = true
        divider.trailingAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true

        divider.bottomAnchor.constraint(equalTo: infoBar.topAnchor).isActive = true

        infoBar.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
        infoBar.leadingAnchor.constraint(equalTo: containerView.leadingAnchor).isActive = true
        infoBar.trailingAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true

        infoBar.dropdownValues = editorDisplayStyles.map { $0.displayName }
        infoBar.onChangeDropdownIndex = { [unowned self] index in
            var newFormattingOptions = self.logicEditor.formattingOptions
            newFormattingOptions.style = self.editorDisplayStyles[index]
            self.logicEditor.formattingOptions = newFormattingOptions
            self.infoBar.dropdownIndex = index
        }

        logicEditor.onChangeSuggestionFilter = { [unowned self] value in
            self.logicEditor.suggestionFilter = value
        }

        logicEditor.showsMinimap = true
        logicEditor.showsDropdown = true
        logicEditor.showsFilterBar = true
        logicEditor.suggestionFilter = .all

//        logicEditor.rootNode = .topLevelDeclarations(
//            .init(id: UUID(), declarations: .init([.makePlaceholder()]))
//        )

//        logicEditor.rootNode = .topLevelParameters(
//            LGCTopLevelParameters(id: UUID(), parameters: .next(.placeholder(id: UUID()), .empty))
//        )

        let labelFont = TextStyle(family: "San Francisco", weight: .bold, size: 9).nsFont

        var annotations: [UUID: String] = [:]
        var successfulUnification: (Compiler.UnificationContext, Unification.Substitution)?
        var successfulEvaluation: Compiler.EvaluationContext?

        infoBar.dropdownIndex = 0
        logicEditor.formattingOptions = LogicFormattingOptions(
            style: .visual,
            getError: ({ [unowned self ] id in
                if let error = self.logicEditor.elementErrors.first(where: { $0.uuid == id }) {
                    return error.message
                } else {
                    return nil
                }
            }),
            getArguments: ({ [unowned self] id in
                let rootNode = self.logicEditor.rootNode

                return StandardConfiguration.formatArguments(
                    rootNode: rootNode,
                    id: id,
                    unificationContext: successfulUnification?.0,
                    substitution: successfulUnification?.1
                )
            }),
            getColor: ({ [unowned self] id in
                guard let evaluation = successfulEvaluation else { return nil }

                guard let value = evaluation.evaluate(uuid: id) else {
//                    Swift.print("Failed to evaluate color", id)
                    return nil
                }

                guard let colorString = value.colorString, let color = NSColor.parse(css: colorString) else { return nil }
                return (colorString, color)
            }),
            getTextStyle: ({ [unowned self] id in
                guard let evaluation = successfulEvaluation else { return nil }

                guard let value = evaluation.evaluate(uuid: id) else {
//                    Swift.print("Failed to evaluate text style", id)
                    return nil
                }

                return value.textStyle
            }),
            getShadow: ({ [unowned self] id in
                guard let evaluation = successfulEvaluation else { return nil }

                guard let value = evaluation.evaluate(uuid: id) else {
//                    Swift.print("Failed to evaluate shadow", id)
                    return nil
                }

                return value.nsShadow
            })
        )

        logicEditor.decorationForNodeID = { id in
            guard let node = self.logicEditor.rootNode.find(id: id) else { return nil }

            if let evaluation = successfulEvaluation,
                let colorValue = evaluation.evaluate(uuid: node.uuid)?.colorString {
                if self.logicEditor.formattingOptions.style == .visual,
                    let path = self.logicEditor.rootNode.pathTo(id: id),
                    let parent = path.dropLast().last {

                    switch parent {
                    case .declaration(.variable):
                        return nil
                    default:
                        break
                    }

                    if let grandParent = path.dropLast().dropLast().last {
                        switch (grandParent, parent, node) {
                        case (.declaration(.variable), .expression(.literalExpression), .literal(.color)):
                            return nil
                        default:
                            break
                        }
                    }
                }

                return .color(NSColor.parse(css: colorValue) ?? NSColor.black)
            }

//            if let annotation = annotations[node.uuid] {
//                switch node {
//                case .literal:
//                    return nil
//                default:
//                    break
//                }
//
//                return .label(labelFont, annotation)
//            }

            switch node {
            case .literal(.color(id: _, value: let color)):
                return .color(NSColor.parse(css: color) ?? NSColor.black)
            case .identifier(let identifier) where identifier.string.starts(with: "TextStyles."):
                return .character(TextStyle(size: 18, color: .purple).apply(to: "S"), .purple)
            default:
                return nil
            }
        }

        logicEditor.contextMenuForNode = { rootNode, node in
            func makeContextMenu(for node: LGCSyntaxNode) -> NSMenu? {
                let menu = NSMenu()

                func makeMenuItem(title: String, action: MenuAction) -> NSMenuItem {
                    let item = NSMenuItem(title: title, action: #selector(self.handleMenuAction), keyEquivalent: "")
                    item.representedObject = action
                    return item
                }

                switch node {
                case .statement(.declaration(id: _, content: let declaration)):
                    menu.addItem(makeMenuItem(title: "Add comment", action: MenuAction.addComment(declaration.uuid)))
                    menu.addItem(makeMenuItem(title: "Duplicate statement", action: MenuAction.duplicate(node.uuid)))
                case .declaration(let value):
                    menu.addItem(makeMenuItem(title: "Insert above", action: MenuAction.insertAbove(node.uuid)))
                    menu.addItem(makeMenuItem(title: "Insert below", action: MenuAction.insertBelow(node.uuid)))
                    menu.addItem(.separator())
                    menu.addItem(makeMenuItem(title: "Add comment", action: MenuAction.addComment(value.uuid)))
                    menu.addItem(makeMenuItem(title: "Duplicate declaration", action: MenuAction.duplicate(node.uuid)))
                case .enumerationCase(.enumerationCase(let value)):
                    menu.addItem(makeMenuItem(title: "Add comment", action: MenuAction.addComment(value.id)))
                case .functionParameter(.parameter(let value)):
                    menu.addItem(makeMenuItem(title: "Add comment", action: MenuAction.addComment(value.id)))
                default:
                    return nil
                }

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

        let makeProgram: (LGCSyntaxNode) -> LGCSyntaxNode? = Memoize.one({ rootNode in
            guard let root = LGCProgram.make(from: rootNode) else { return nil }

            let program: LGCSyntaxNode = .program(root.expandImports(importLoader: Library.load))

            return program
        })

        let makeSuggestionBuilder: (LGCSyntaxNode, LGCSyntaxNode, LogicFormattingOptions) -> ((String) -> [LogicSuggestionItem]?)? = Memoize.one({
            rootNode, node, formattingOptions in
            return StandardConfiguration.suggestions(rootNode: rootNode, node: node, formattingOptions: formattingOptions)
        })

        logicEditor.suggestionsForNode = { [unowned self] rootNode, node, query in
            guard let program = makeProgram(rootNode) else { return [] }

            let suggestionBuilder = makeSuggestionBuilder(program, node, self.logicEditor.formattingOptions)

            if let suggestionBuilder = suggestionBuilder, let suggestions = suggestionBuilder(query) {
                return suggestions
            } else {
                return LogicEditor.defaultSuggestionsForNode(program, node, query)
            }
        }

        func evaluate(rootNode: LGCSyntaxNode) -> Bool {
            successfulEvaluation = nil

            self.logicEditor.rootNode = rootNode

            let rootNode = self.logicEditor.rootNode

            guard let root = LGCProgram.make(from: rootNode) else { return true }

            let program: LGCSyntaxNode = .program(root.expandImports(importLoader: Library.load))

            let scopeContext = Compiler.scopeContext(program)

            var errors: [LogicEditor.ElementError] = []

            scopeContext.undefinedIdentifiers.forEach { errorId in
                if case .identifier(let identifierNode)? = logicEditor.rootNode.find(id: errorId) {
                    errors.append(
                        LogicEditor.ElementError(uuid: errorId, message: "The name \"\(identifierNode.string)\" hasn't been declared yet")
                    )
                }
            }

            scopeContext.undefinedMemberExpressions.forEach { errorId in
                if case .expression(let expression)? = logicEditor.rootNode.find(id: errorId), let identifiers = expression.flattenedMemberExpression {
                    let keyPath = identifiers.map { $0.string }
                    let last = keyPath.last ?? ""
                    let rest = keyPath.dropLast().joined(separator: ".")
                    errors.append(
                        LogicEditor.ElementError(uuid: errorId, message: "The name \"\(last)\" hasn't been declared in \"\(rest)\" yet")
                    )
                }
            }

            logicEditor.elementErrors = errors

            let unificationContext = Compiler.makeUnificationContext(program, scopeContext: scopeContext)

            guard case .success(let substitution) = Unification.unify(constraints: unificationContext.constraints) else {
                return true
            }

            successfulUnification = (unificationContext, substitution)

            let result = Compiler.evaluate(
                program,
                rootNode: program,
                scopeContext: scopeContext,
                unificationContext: unificationContext,
                substitution: substitution,
                context: .init()
            )

            switch result {
            case .success(let evaluationContext):
                successfulEvaluation = evaluationContext

                if evaluationContext.hasCycle {
                    Swift.print("Logic cycle(s) found", evaluationContext.cycles)
                }

                let cycleErrors = evaluationContext.cycles.map { cycle in
                    return cycle.map { id -> LogicEditor.ElementError in
                        return LogicEditor.ElementError(uuid: id, message: "A variable's definition can't include its name (there's a cycle somewhere)")
                    }
                }
                logicEditor.elementErrors.append(contentsOf: Array(cycleErrors.joined()))
            case .failure(let error):
                Swift.print("Eval failure", error)
            }

            return true
        }

        logicEditor.onChangeRootNode = { rootNode in
            return evaluate(rootNode: rootNode)
        }

        _ = evaluate(rootNode: logicEditor.rootNode)

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
        guard let jsonData = LogicFile.convert(data, kind: .logic, to: .json) else {
            throw NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotOpenFile, userInfo: nil)
        }

        logicEditor.rootNode = try JSONDecoder().decode(LGCSyntaxNode.self, from: jsonData)
    }

    private enum MenuAction {
        case addComment(UUID)
        case duplicate(UUID)
        case insertAbove(UUID)
        case insertBelow(UUID)
    }

    @objc func handleMenuAction(_ sender: NSMenuItem) {
        guard let action = sender.representedObject as? MenuAction else { return }

        switch action {
        case .duplicate(let id):
            if let newRootNode = logicEditor.rootNode.duplicate(id: id) {
                logicEditor.rootNode = newRootNode
            }
        case .insertAbove(let id):
            if let newRootNode = logicEditor.rootNode.insert(.above, id: id) {
                logicEditor.rootNode = newRootNode
            }
        case .insertBelow(let id):
            if let newRootNode = logicEditor.rootNode.insert(.below, id: id) {
                logicEditor.rootNode = newRootNode
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

//    override func data(ofType typeName: String) throws -> Data {
//        let encoder = JSONEncoder()
//        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
//
//        let jsonData = try encoder.encode(logicEditor.rootNode)
//
//        guard let xmlData = LogicFile.convert(jsonData, kind: .logic, to: .xml) else {
//            throw NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotOpenFile, userInfo: nil)
//        }
//
//        return xmlData
//    }

}

