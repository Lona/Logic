//
//  Document.swift
//  LogicDesigner
//
//  Created by Devin Abbott on 2/16/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import AppKit
import Logic

class LogicDocument: NSDocument {

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

    var successfulUnification: (Compiler.UnificationContext, Unification.Substitution)?
    var successfulEvaluation: Compiler.EvaluationContext?

    func initializeWindowController(presenting contentView: NSView) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false)

        window.backgroundColor = Colors.background
        window.center()
        window.contentView = contentView

        self.window = window

        let windowController = NSWindowController(window: window)
        windowController.showWindow(nil)
        addWindowController(windowController)

        window.makeFirstResponder(nil)
    }

    override func makeWindowControllers() {
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
            let newFormattingOptions = self.logicEditor.formattingOptions
            newFormattingOptions.style = self.editorDisplayStyles[index]
            self.logicEditor.formattingOptions = newFormattingOptions
            self.infoBar.dropdownIndex = index
        }

        logicEditor.onChangeSuggestionFilter = { [unowned self] value in
            self.logicEditor.suggestionFilter = value
        }

        logicEditor.placeholderText = "Search"
        logicEditor.showsMinimap = true
        logicEditor.showsFilterBar = true
        logicEditor.suggestionFilter = .all
        logicEditor.showsLineButtons = true

//        logicEditor.rootNode = .topLevelDeclarations(
//            .init(id: UUID(), declarations: .init([.makePlaceholder()]))
//        )

//        logicEditor.rootNode = .topLevelParameters(
//            LGCTopLevelParameters(id: UUID(), parameters: .next(.placeholder(id: UUID()), .empty))
//        )

//        let labelFont = TextStyle(family: "San Francisco", weight: .bold, size: 9).nsFont

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
                    unificationContext: self.successfulUnification?.0,
                    substitution: self.successfulUnification?.1
                )
            }),
            getColor: ({ [unowned self] id in
                guard let evaluation = self.successfulEvaluation else { return nil }

                guard let value = evaluation.evaluate(uuid: id) else {
//                    Swift.print("Failed to evaluate color", id)
                    return nil
                }

                guard let colorString = value.colorString, let color = NSColor.parse(css: colorString) else { return nil }
                return (colorString, color)
            }),
            getTextStyle: ({ [unowned self] id in
                guard let evaluation = self.successfulEvaluation else { return nil }

                guard let value = evaluation.evaluate(uuid: id) else {
//                    Swift.print("Failed to evaluate text style", id)
                    return nil
                }

                return value.textStyle
            }),
            getShadow: ({ [unowned self] id in
                guard let evaluation = self.successfulEvaluation else { return nil }

                guard let value = evaluation.evaluate(uuid: id) else {
//                    Swift.print("Failed to evaluate shadow", id)
                    return nil
                }

                return value.nsShadow
            })
        )

        logicEditor.decorationForNodeID = { id in
            if let evaluation = self.successfulEvaluation,
                let colorValue = evaluation.evaluate(uuid: id)?.colorString {
                return .color(NSColor.parse(css: colorValue) ?? NSColor.black)
            }
            
            return nil
        }

        logicEditor.onInsertBelow = { [unowned self] rootNode, node in
            StandardConfiguration.handleMenuItem(logicEditor: self.logicEditor, action: .insertBelow(node.uuid))
        }

        logicEditor.contextMenuForNode = { [unowned self] rootNode, node in
            return StandardConfiguration.menu(rootNode: rootNode, node: node, allowComments: true, handleMenuAction: { [unowned self] action in
                StandardConfiguration.handleMenuItem(logicEditor: self.logicEditor, action: action)
                _ = self.evaluate(rootNode: self.logicEditor.rootNode)
            })
        }

        let makeProgram: (LGCSyntaxNode) -> LGCSyntaxNode? = Memoize.one({ rootNode in
            guard let root = LGCProgram.make(from: rootNode) else { return nil }

            let program: LGCSyntaxNode = .program(root.expandImports(importLoader: Library.load))

            return program
        })

        let makeSuggestionBuilder: (LGCSyntaxNode, LGCSyntaxNode, LogicFormattingOptions) -> ((String) -> [LogicSuggestionItem]?)? = Memoize.one({
            rootNode, node, formattingOptions in
            switch StandardConfiguration.suggestions(rootNode: rootNode, node: node, formattingOptions: formattingOptions) {
            case .success(let builder):
                return builder
            case .failure(let error):
                Swift.print("ERROR: Failed to make suggestion builder: \(error)")
                return nil
            }
        })

        logicEditor.suggestionsForNode = { [unowned self] rootNode, node, query in
            guard let program = makeProgram(rootNode) else { return .init([]) }

            let suggestionBuilder = makeSuggestionBuilder(program, node, self.logicEditor.formattingOptions)

            if let suggestionBuilder = suggestionBuilder, let suggestions = suggestionBuilder(query) {
                return .init(suggestions)
            } else {
                return LogicEditor.defaultSuggestionsForNode(program, node, query)
            }
        }

        logicEditor.onChangeRootNode = { [unowned self] rootNode in
            return self.evaluate(rootNode: rootNode)
        }

        _ = evaluate(rootNode: logicEditor.rootNode)

        initializeWindowController(presenting: containerView)
    }

    func evaluate(rootNode: LGCSyntaxNode) -> Bool {
        successfulEvaluation = nil

        guard let root = LGCProgram.make(from: rootNode) else {
            self.logicEditor.rootNode = rootNode

            return true
        }

        var errors: [LogicEditor.ElementError] = []

        let program: LGCSyntaxNode = .program(root.expandImports(importLoader: Library.load))

        debugWindowController.rootNode = program

        let scopeContext: Compiler.ScopeContext

        switch Compiler.scopeContext(program) {
        case .failure(let error):
            errors.append(
                .init(uuid: error.nodeID, message: error.localizedDescription)
            )

            logicEditor.rootNode = rootNode
            logicEditor.elementErrors = errors

            Swift.print("ERROR: \(error)")

            return true
        case .success(let value):
            scopeContext = value
        }

        debugWindowController.scopeContext = scopeContext

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

        debugWindowController.unificationContext = unificationContext

        guard case .success(let substitution) = Unification.unify(constraints: unificationContext.constraints) else {
            self.logicEditor.rootNode = rootNode

            return true
        }

        debugWindowController.substitution = substitution

        successfulUnification = (unificationContext, substitution)

        let result = Compiler.compile(
            program,
            rootNode: program,
            scopeContext: scopeContext,
            unificationContext: unificationContext,
            substitution: substitution,
            context: .init()
        )

        switch result {
        case .success(let evaluationContext):
            debugWindowController.evaluationContext = evaluationContext

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

        self.logicEditor.rootNode = rootNode

        return true
    }

    override func data(ofType typeName: String) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data = try encoder.encode(logicEditor.rootNode)

        return LogicFile.convert(data, kind: .logic, to: .source) ?? data
    }

    override func read(from data: Data, ofType typeName: String) throws {
        guard let jsonData = LogicFile.convert(data, kind: .logic, to: .json) else {
            throw NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotOpenFile, userInfo: nil)
        }

        logicEditor.rootNode = try JSONDecoder().decode(LGCSyntaxNode.self, from: jsonData)
    }

    var debugWindowController: DebugWindowController = DebugWindowController()
}

extension LogicDocument {
    @IBAction func showDebugWindow(_ sender: AnyObject) {
        debugWindowController.showWindow(self)
    }
}
