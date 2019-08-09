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
        var colorValues: [UUID: String] = [:]
        var shadowValues: [UUID: NSShadow] = [:]
        var textStyleValues: [UUID: TextStyle] = [:]
        var successfulUnification: (Compiler.UnificationContext, Unification.Substitution)?

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
            getColor: ({ id in
                guard let colorString = colorValues[id], let color = NSColor.parse(css: colorString) else { return nil }
                return (colorString, color)
            }),
            getTextStyle: ({ id in return textStyleValues[id] }),
            getShadow: ({ id in return shadowValues[id] })
        )

        logicEditor.decorationForNodeID = { id in
            guard let node = self.logicEditor.rootNode.find(id: id) else { return nil }

            if let colorValue = colorValues[node.uuid] {
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
            let menu = NSMenu()

            func addComment(_ uuid: UUID) {
                let addCommentItem = NSMenuItem(title: "Add comment", action: #selector(self.addComment), keyEquivalent: "")
                addCommentItem.representedObject = MenuAction.addComment(uuid)
                menu.addItem(addCommentItem)
            }

            switch node {
            case .statement(.declaration(id: _, content: let declaration)):
                addComment(declaration.uuid)
            case .declaration(let value):
                addComment(value.uuid)
            case .enumerationCase(.enumerationCase(let value)):
                addComment(value.id)
            case .functionParameter(.parameter(let value)):
                addComment(value.id)
            default:
                return nil
            }

            return menu
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
            self.logicEditor.rootNode = rootNode

            let rootNode = self.logicEditor.rootNode

            guard let root = LGCProgram.make(from: rootNode) else { return true }

            let program: LGCSyntaxNode = .program(root.expandImports(importLoader: Library.load))

            let scopeContext = Compiler.scopeContext(program)

            if let errorId = scopeContext.undefinedIdentifiers.first, case .identifier(let identifierNode)? = logicEditor.rootNode.find(id: errorId) {
                logicEditor.elementErrors = [
                    LogicEditor.ElementError(uuid: errorId, message: "The name \"\(identifierNode.string)\" hasn't been declared yet")
                ]
            } else {
                logicEditor.elementErrors = []
            }

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

            annotations.removeAll(keepingCapacity: true)
            colorValues.removeAll(keepingCapacity: true)
            shadowValues.removeAll(keepingCapacity: true)
            textStyleValues.removeAll(keepingCapacity: true)

            switch result {
            case .success(let evaluationContext):
                //                Swift.print("Result", evaluationContext.values)

                evaluationContext.values.forEach { id, value in
                    switch value.memory {
                    case .unit, .bool, .number, .string, .enum, .array:
                        annotations[id] = "\(value.memory)"
                    case .record, .function:
                        break
                    }

                    //                    Swift.print(id, value.type, value.memory)

                    if let colorString = value.colorString {
                        colorValues[id] = colorString
                    }

                    if let shadow = value.nsShadow {
                        shadowValues[id] = shadow
                    }

                    if let textStyle = value.textStyle {
                        textStyleValues[id] = textStyle
                    }
                }
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
    }

    @objc func addComment(_ sender: NSMenuItem) {
        guard let action = sender.representedObject as? MenuAction else { return }

        switch action {
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

