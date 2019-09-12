//
//  SuggestionWindow.swift
//  LogicDesigner
//
//  Created by Devin Abbott on 2/17/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import AppKit

public class InlineToolbarWindow: NSWindow {
    static var shared = InlineToolbarWindow()

    public override var canBecomeMain: Bool {
        return false
    }

    public override var acceptsFirstResponder: Bool {
        return false
    }

    convenience init() {
        self.init(
            contentRect: NSRect(origin: .zero, size: .zero),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false)

        let window = self
        window.backgroundColor = NSColor.clear
        window.isOpaque = false

        let shadow = NSShadow()
        shadow.shadowBlurRadius = 4
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.4)
        shadow.shadowOffset = NSSize(width: 0, height: -2)

        shadowView.boxType = .custom
        shadowView.borderType = .noBorder
        shadowView.contentViewMargins = .zero
        shadowView.fillColor = Colors.suggestionWindowBackground
        shadowView.shadow = shadow
        shadowView.cornerRadius = 4

        let view = NSView()

        view.addSubview(shadowView)
        shadowView.addSubview(toolbarView)

        shadowView.translatesAutoresizingMaskIntoConstraints = false
        shadowView.topAnchor.constraint(equalTo: view.topAnchor, constant: InlineToolbarWindow.shadowViewMargin).isActive = true
        shadowView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: InlineToolbarWindow.shadowViewMargin).isActive = true
        shadowView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -InlineToolbarWindow.shadowViewMargin).isActive = true
        shadowView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -InlineToolbarWindow.shadowViewMargin).isActive = true

        toolbarView.translatesAutoresizingMaskIntoConstraints = false
        toolbarView.topAnchor.constraint(equalTo: shadowView.topAnchor).isActive = true
        toolbarView.leadingAnchor.constraint(equalTo: shadowView.leadingAnchor).isActive = true
        toolbarView.trailingAnchor.constraint(equalTo: shadowView.trailingAnchor).isActive = true
        toolbarView.bottomAnchor.constraint(equalTo: shadowView.bottomAnchor).isActive = true

        window.contentView = view

        let notificationTokens = [
            NotificationCenter.default.addObserver(
                forName: NSWindow.didResignKeyNotification,
                object: self,
                queue: nil,
                using: { [weak self] notification in self?.handleHide() }
            ),
            NotificationCenter.default.addObserver(
                forName: NSWindow.didResignMainNotification,
                object: self,
                queue: nil,
                using: { [weak self] notification in self?.handleHide() }
            )
        ]

        subscriptions.append({
            notificationTokens.forEach {
                NotificationCenter.default.removeObserver($0)
            }
        })
    }

    deinit {
        subscriptions.forEach { subscription in subscription() }
    }

    private var subscriptions: [() -> Void] = []

    var shadowView = NSBox()

    var toolbarView = InlineToolbar()

    private func handleHide() {
        self.onRequestHide?()
    }

    // MARK: Public

    public var onCommand: ((InlineToolbar.Command) -> Void)? {
        get { return toolbarView.onCommand }
        set { toolbarView.onCommand = newValue }
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

    public var allowedShrinkingSize = CGSize(width: 180, height: 200)

    public var onRequestHide: (() -> Void)?

    public var onSubmit: ((Int) -> Void)?

    public func anchorTo(rect: NSRect, verticalOffset: CGFloat = 0) {
        let contentViewSize = defaultContentViewSize
        let contentRect = NSRect(
            origin: NSPoint(x: rect.minX, y: rect.maxY + verticalOffset),
            size: NSSize(
                width: contentViewSize.width + InlineToolbarWindow.shadowViewMargin * 2,
                height: contentViewSize.height + InlineToolbarWindow.shadowViewMargin * 2))

//        if let visibleFrame = NSScreen.main?.visibleFrame {
//            if contentRect.maxX > visibleFrame.maxX {
//                contentRect.origin.x = min(contentRect.minX, visibleFrame.maxX - contentRect.width + 16)
//            }
//
//            if contentRect.minY < visibleFrame.minY {
//                contentRect.origin.y = rect.maxY + verticalOffset
//            }
//        }

        setContentSize(contentRect.size)
        setFrameOrigin(contentRect.origin)
    }

    public var defaultContentViewSize: CGSize {
        return toolbarView.fittingSize
    }

    private static var shadowViewMargin: CGFloat = 12

    // MARK: Overrides

    public override var canBecomeKey: Bool {
        return true
    }

    // Offset the origin to account for the shadow view's margin
    public override func setFrameOrigin(_ point: NSPoint) {
        let offsetOrigin = NSPoint(x: point.x - InlineToolbarWindow.shadowViewMargin, y: point.y - InlineToolbarWindow.shadowViewMargin)
        super.setFrameOrigin(offsetOrigin)
    }
}
