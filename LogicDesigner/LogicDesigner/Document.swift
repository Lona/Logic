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

        logicEditor.decorationForNodeID = { id in
            guard let node = self.logicEditor.rootNode.find(id: id) else { return nil }
            switch node {
            case .literal(.color(id: _, value: _)):
                return .color(.red)
            case .identifier(let identifier) where identifier.string.starts(with: "TextStyles."):
                return .text(TextStyle(size: 18, color: .purple).apply(to: "S"), .purple)
            default:
                return nil
            }
        }

        logicEditor.onChangeRootNode = { [unowned self] rootNode in
            self.logicEditor.rootNode = rootNode
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

