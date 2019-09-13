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

    override func makeWindowControllers() {
        containerView.boxType = .custom
        containerView.borderType = .noBorder
        containerView.contentViewMargins = .zero

        let inlineBlockEditor = BlockEditor()

        inlineBlockEditor.blocks = [
            .text("hello, world"),
            .text("**bold** text")
        ]

        containerView.addSubview(inlineBlockEditor)

        containerView.translatesAutoresizingMaskIntoConstraints = false
        inlineBlockEditor.translatesAutoresizingMaskIntoConstraints = false

        inlineBlockEditor.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        inlineBlockEditor.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
        inlineBlockEditor.leadingAnchor.constraint(equalTo: containerView.leadingAnchor).isActive = true
        inlineBlockEditor.trailingAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true

//        inlineBlockEditor.widthAnchor.constraint(equalToConstant: 400).isActive = true
//        inlineBlockEditor.heightAnchor.constraint(equalToConstant: 300).isActive = true

        initializeWindowController(presenting: containerView)
    }
}
