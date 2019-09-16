//
//  OverlayWindow.swift
//  Logic
//
//  Created by Devin Abbott on 9/12/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import AppKit

public class OverlayWindow: NSWindow {
    public override init(
        contentRect: NSRect,
        styleMask style: NSWindow.StyleMask,
        backing backingStoreType: NSWindow.BackingStoreType,
        defer flag: Bool) {

        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)

        setUpViews()
        setUpConstraints()
        setUpSubscriptions()

        super.contentView = contentContainerView
    }

    public convenience init() {
        self.init(
            contentRect: NSRect(origin: .zero, size: .zero),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
    }

    deinit {
        subscriptions.forEach { subscription in subscription() }
    }

    // MARK: Private

    private var subscriptions: [() -> Void] = []

    private var contentContainerView = NSView()

    private var shadowView = NSBox()

    private func setUpViews() {
        backgroundColor = NSColor.clear
        isOpaque = false

        shadowView.boxType = .custom
        shadowView.borderType = .noBorder
        shadowView.contentViewMargins = .zero
        shadowView.fillColor = Colors.suggestionWindowBackground
        shadowView.shadow = OverlayWindow.shadow
        shadowView.cornerRadius = 4

        contentContainerView.addSubview(shadowView)
    }

    private func setUpConstraints() {
        shadowView.translatesAutoresizingMaskIntoConstraints = false
        shadowView.topAnchor.constraint(equalTo: contentContainerView.topAnchor, constant: OverlayWindow.shadowViewMargin).isActive = true
        shadowView.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor, constant: OverlayWindow.shadowViewMargin).isActive = true
        shadowView.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor, constant: -OverlayWindow.shadowViewMargin).isActive = true
        shadowView.bottomAnchor.constraint(equalTo: contentContainerView.bottomAnchor, constant: -OverlayWindow.shadowViewMargin).isActive = true
    }

    private func setUpSubscriptions() {
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

    private func handleHide() {
        self.onRequestHide?()
    }

    private var innerContentViewSize: CGSize {
        return innerContentView?.fittingSize ?? .zero
    }

    public static var shadowViewMargin: CGFloat = 12

    // MARK: Public

    public var innerContentView: NSView? {
        didSet {
            if innerContentView != oldValue {
                oldValue?.removeFromSuperview()

                if let innerContentView = innerContentView {
                    shadowView.addSubview(innerContentView)

                    innerContentView.translatesAutoresizingMaskIntoConstraints = false
                    innerContentView.topAnchor.constraint(equalTo: shadowView.topAnchor).isActive = true
                    innerContentView.leadingAnchor.constraint(equalTo: shadowView.leadingAnchor).isActive = true
                    innerContentView.trailingAnchor.constraint(equalTo: shadowView.trailingAnchor).isActive = true
                    innerContentView.bottomAnchor.constraint(equalTo: shadowView.bottomAnchor).isActive = true
                }
            }
        }
    }

    public var onRequestHide: (() -> Void)?

    public func anchorTo(rect: NSRect, verticalOffset: CGFloat = 0) {
        let contentViewSize = innerContentViewSize
        let contentRect = NSRect(
            origin: NSPoint(x: rect.minX, y: rect.maxY + verticalOffset),
            size: NSSize(
                width: contentViewSize.width + OverlayWindow.shadowViewMargin * 2,
                height: contentViewSize.height + OverlayWindow.shadowViewMargin * 2))
        setContentSize(contentRect.size)
        setFrameOrigin(contentRect.origin)
    }

    // MARK: Overrides

    // Offset the origin to account for the shadow view's margin
    public override func setFrameOrigin(_ point: NSPoint) {
        let offsetOrigin = NSPoint(x: point.x - OverlayWindow.shadowViewMargin, y: point.y - OverlayWindow.shadowViewMargin)
        super.setFrameOrigin(offsetOrigin)
    }

    public static var shadow: NSShadow {
        let shadow = NSShadow()
        shadow.shadowBlurRadius = 4
        shadow.shadowOffset = NSSize(width: 0, height: -2)

        if #available(OSX 10.14, *) {
            switch NSApp.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) {
            case .some(.darkAqua):
                shadow.shadowColor = NSColor.black.withAlphaComponent(0.85)
                return shadow
            default:
                break
            }
        }

        shadow.shadowColor = NSColor.black.withAlphaComponent(0.4)
        return shadow
    }
}
