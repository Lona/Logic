//
//  MarkdownDocument.swift
//  LogicDesigner
//
//  Created by Devin Abbott on 9/10/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import AppKit
import Logic

class MarkdownDocument: NSDocument {

    override init() {
        super.init()
    }

    override class var autosavesInPlace: Bool {
        return false
    }

    var window: NSWindow?

    let containerView = NSBox()

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
    }

    var blockEditor: BlockEditor = {
        let blockEditor = BlockEditor()

        blockEditor.blocks = MarkdownFile.makeBlocks("")

        return blockEditor
    }()

//    var successfulUnification: (Compiler.UnificationContext, Unification.Substitution)?
//    var successfulEvaluation: Compiler.EvaluationContext?

    private func evaluate(rootNode: LGCSyntaxNode) -> (
        errors: [LogicEditor.ElementError],
        compiled: (Compiler.UnificationContext, Unification.Substitution)?,
        evaluated: Compiler.EvaluationContext?) {

        var errors: [LogicEditor.ElementError] = []

        guard let root = LGCProgram.make(from: rootNode) else { return (errors, nil, nil) }

        let program: LGCSyntaxNode = .program(root.expandImports(importLoader: Library.load))

        let scopeContext = Compiler.scopeContext(program)

        scopeContext.undefinedIdentifiers.forEach { errorId in
            if case .identifier(let identifierNode)? = rootNode.find(id: errorId) {
                errors.append(
                    LogicEditor.ElementError(uuid: errorId, message: "The name \"\(identifierNode.string)\" hasn't been declared yet")
                )
            }
        }

        scopeContext.undefinedMemberExpressions.forEach { errorId in
            if case .expression(let expression)? = rootNode.find(id: errorId), let identifiers = expression.flattenedMemberExpression {
                let keyPath = identifiers.map { $0.string }
                let last = keyPath.last ?? ""
                let rest = keyPath.dropLast().joined(separator: ".")
                errors.append(
                    LogicEditor.ElementError(uuid: errorId, message: "The name \"\(last)\" hasn't been declared in \"\(rest)\" yet")
                )
            }
        }

        let unificationContext = Compiler.makeUnificationContext(program, scopeContext: scopeContext)

        guard case .success(let substitution) = Unification.unify(constraints: unificationContext.constraints) else {
            return (errors, nil, nil)
        }

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
            if evaluationContext.hasCycle {
                Swift.print("Logic cycle(s) found", evaluationContext.cycles)
            }

            let cycleErrors = evaluationContext.cycles.map { cycle in
                return cycle.map { id -> LogicEditor.ElementError in
                    return LogicEditor.ElementError(uuid: id, message: "A variable's definition can't include its name (there's a cycle somewhere)")
                }
            }

            errors.append(contentsOf: Array(cycleErrors.joined()))

            return (errors, (unificationContext, substitution), evaluationContext)
        case .failure(let error):
            Swift.print("Eval failure", error)

            return (errors, (unificationContext, substitution), nil)
        }
    }

    let makeSuggestionBuilder: (LGCSyntaxNode, LGCSyntaxNode, LogicFormattingOptions) -> ((String) -> [LogicSuggestionItem]?)? = Memoize.one({
        rootNode, node, formattingOptions in
        return StandardConfiguration.suggestions(rootNode: rootNode, node: node, formattingOptions: formattingOptions)
    })

    private func configure(blocks: [BlockEditor.Block]) {

        // TODO: topLevelDeclarations and program are created with a new ID each time, will that hurt performance?
        guard let root = LGCProgram.make(from: .topLevelDeclarations(blocks.topLevelDeclarations)) else { return }

        let rootNode = LGCSyntaxNode.program(root)

        let program: LGCSyntaxNode = .program(root.expandImports(importLoader: Library.load))

        let (errors, compiled, evaluation) = evaluate(rootNode: program)

//        Swift.print("-- RootNode \(count) --\n" + rootNode.hierarchyDescription())

        let formattingOptions: LogicFormattingOptions = LogicFormattingOptions(
            style: .visual,
            getError: ({ id in
                if let error = errors.first(where: { $0.uuid == id }) {
                    return error.message
                } else {
                    return nil
                }
            }),
            getArguments: ({ id in
                return StandardConfiguration.formatArguments(
                    rootNode: rootNode,
                    id: id,
                    unificationContext: compiled?.0,
                    substitution: compiled?.1
                )
            }),
            getColor: ({ id in
                guard let evaluation = evaluation else { return nil }
                guard let value = evaluation.evaluate(uuid: id) else { return nil }
                guard let colorString = value.colorString, let color = NSColor.parse(css: colorString) else { return nil }
                return (colorString, color)
            }),
            getTextStyle: ({ id in
                guard let evaluation = evaluation else { return nil }
                guard let value = evaluation.evaluate(uuid: id) else { return nil }
                return value.textStyle
            }),
            getShadow: ({ id in
                guard let evaluation = evaluation else { return nil }
                guard let value = evaluation.evaluate(uuid: id) else { return nil }
                return value.nsShadow
            })
        )

        let suggestionsForNode: ((LGCSyntaxNode, LGCSyntaxNode, String) -> [LogicSuggestionItem]) = { _, node, query in
//            Swift.print("-- Suggestion Root \(count) \(rootNode.uuid) --\n" + rootNode.hierarchyDescription())

            let suggestionBuilder = StandardConfiguration.suggestions(rootNode: program, node: node, formattingOptions: formattingOptions)

            if let suggestionBuilder = suggestionBuilder, let suggestions = suggestionBuilder(query) {
                return suggestions
            } else {
                return node.suggestions(within: rootNode, for: query)
//                return LogicEditor.defaultSuggestionsForNode(rootNode, node, query)
            }
        }

        blocks.forEach { block in
            switch block.content {
            case .tokens:
                let logicEditor = block.view as! LogicEditor

                logicEditor.formattingOptions = formattingOptions

                logicEditor.suggestionsForNode = suggestionsForNode

                // Only show the errors for nodes within this rootNode
                logicEditor.elementErrors = errors.filter { logicEditor.rootNode.find(id: $0.uuid) != nil }

                logicEditor.willSelectNode = { rootNode, nodeId in
                    guard let nodeId = nodeId else { return nil }

                    return rootNode.redirectSelection(nodeId)
                }
            default:
                break
            }
        }
    }

    override func makeWindowControllers() {
        containerView.boxType = .custom
        containerView.borderType = .noBorder
        containerView.contentViewMargins = .zero

        containerView.addSubview(blockEditor)

        blockEditor.onChangeBlocks = { [unowned self] blocks in
            let newBlocks = blocks.isEmpty ? [EditableBlock.makeDefaultEmptyBlock()] : blocks

            self.blockEditor.blocks = newBlocks
            self.configure(blocks: newBlocks)
            return true
        }

        containerView.translatesAutoresizingMaskIntoConstraints = false
        blockEditor.translatesAutoresizingMaskIntoConstraints = false

        blockEditor.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        blockEditor.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
        blockEditor.leadingAnchor.constraint(equalTo: containerView.leadingAnchor).isActive = true
        blockEditor.trailingAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true

        initializeWindowController(presenting: containerView)
    }

    override func data(ofType typeName: String) throws -> Data {
        return MarkdownFile.makeMarkdownData(blockEditor.blocks)!
    }

    override func read(from data: Data, ofType typeName: String) throws {
        let blocks = MarkdownFile.makeBlocks(data)!
        blockEditor.blocks = blocks
        configure(blocks: blocks)
    }
}
