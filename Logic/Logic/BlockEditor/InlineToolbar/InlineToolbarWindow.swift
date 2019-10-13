//
//  SuggestionWindow.swift
//  LogicDesigner
//
//  Created by Devin Abbott on 2/17/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import AppKit

public class InlineToolbarWindow: OverlayWindow {
    static var shared = InlineToolbarWindow()

    convenience init() {
        self.init(
            contentRect: NSRect(origin: .zero, size: .zero),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false)

        innerContentView = toolbarView
    }

    private var toolbarView = InlineToolbar()

    // MARK: Public

    public var onCommand: ((InlineToolbar.Command) -> Void)? {
        get { return toolbarView.onCommand }
        set { toolbarView.onCommand = newValue }
    }

    public var replaceCommandLabel: String {
        get { return toolbarView.replaceCommandLabel }
        set { toolbarView.replaceCommandLabel = newValue }
    }

    public var isBoldEnabled: Bool {
        get { return toolbarView.isBoldEnabled }
        set { toolbarView.isBoldEnabled = newValue }
    }

    public var isItalicEnabled: Bool {
        get { return toolbarView.isItalicEnabled }
        set { toolbarView.isItalicEnabled = newValue }
    }

    public var isCodeEnabled: Bool {
        get { return toolbarView.isCodeEnabled }
        set { toolbarView.isCodeEnabled = newValue }
    }

    public var isLinkEnabled: Bool {
        get { return toolbarView.isLinkEnabled }
        set { toolbarView.isLinkEnabled = newValue }
    }

    public var isStrikethroughEnabled: Bool {
        get { return toolbarView.isStrikethroughEnabled }
        set { toolbarView.isStrikethroughEnabled = newValue }
    }

    public var onSubmit: ((Int) -> Void)?

    public func screenRect(for command: InlineToolbar.Command) -> NSRect? {
        guard let rect = toolbarView.rect(for: command) else { return nil }
        let windowRect = toolbarView.convert(rect, to: nil)
        let screenRect = convertToScreen(windowRect)
        return screenRect
    }

    public func screenRectForFirstCommand() -> NSRect? {
        guard let rect = toolbarView.buttonRects.first else { return nil }
        let windowRect = toolbarView.convert(rect, to: nil)
        let screenRect = convertToScreen(windowRect)
        return screenRect
    }

    // MARK: Overrides

    public override var canBecomeKey: Bool {
        return true
    }

    public override var canBecomeMain: Bool {
        return false
    }

    public override var acceptsFirstResponder: Bool {
        return false
    }
}
