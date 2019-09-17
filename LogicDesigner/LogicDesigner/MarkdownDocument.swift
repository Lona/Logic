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

    var markdownString = ""

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

    let blockEditor = BlockEditor()

    override func makeWindowControllers() {
        containerView.boxType = .custom
        containerView.borderType = .noBorder
        containerView.contentViewMargins = .zero

        containerView.addSubview(blockEditor)

        blockEditor.blocks = MarkdownDocument.makeBlocks(from: markdownString)

        blockEditor.onChangeBlocks = { [unowned self] blocks in
            self.blockEditor.blocks = blocks
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
        return markdownString.data(using: .utf8)!
    }

    override func read(from data: Data, ofType typeName: String) throws {
        markdownString = String(data: data, encoding: .utf8)!

        blockEditor.blocks = MarkdownDocument.makeBlocks(from: markdownString)
    }

    private static func makeBlocks(from markdownString: String) -> [BlockEditor.Block] {
        let parsed = LightMark.parse(markdownString)

        if parsed.count == 0 {
            return [
                EditableBlock.makeDefaultEmptyBlock()
            ]
        }

        let blocks: [BlockEditor.Block] = parsed.compactMap { blockElement in
            switch blockElement {
            case .paragraph(content: let inlineElements):
                let value: NSAttributedString = inlineElements.map { $0.editableString }.joined()
                return BlockEditor.Block(.text(value, .paragraph))
            default:
                return nil
            }
        }
        return blocks
    }
}
