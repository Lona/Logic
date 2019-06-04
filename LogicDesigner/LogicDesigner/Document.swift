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
        
        logicEditor.suggestionsForNode = { rootNode, node, query in
            guard case .program(let root) = rootNode else { return [] }

            let program: LGCSyntaxNode = .program(root.expandImports(importLoader: Library.load))

            if let suggestions = StandardConfiguration.suggestionsForNode(rootNode: program, node: node, query: query) {
                return suggestions
            } else {
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

