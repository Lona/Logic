//
//  SuggestionWindow.swift
//  LogicDesigner
//
//  Created by Devin Abbott on 2/17/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import AppKit

class SuggestionWindow: NSWindow {
    convenience init() {
        self.init(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
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

        let box = NSBox()
        box.boxType = .custom
        box.borderType = .noBorder
        box.contentViewMargins = .zero
        box.fillColor = .white
        box.shadow = shadow
        box.cornerRadius = 4

        let view = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 100))
        view.addSubview(box)

        box.translatesAutoresizingMaskIntoConstraints = false
        box.topAnchor.constraint(equalTo: view.topAnchor, constant: 12).isActive = true
        box.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12).isActive = true
        box.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12).isActive = true
        box.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -12).isActive = true

        self.contentBox = box

        window.contentView = view
    }

    var contentBox: NSView?

    // MARK: Public

    public func anchorTo(rect: NSRect) {
        let margin: CGFloat = 2.0
        if let contentBox = contentBox {
            let origin = NSPoint(x: rect.minX, y: rect.minY - contentBox.frame.height - margin)
            setFrameOrigin(origin)
        }
    }

    // MARK: Overrides

    override func setFrameOrigin(_ point: NSPoint) {
        super.setFrameOrigin(NSPoint(x: point.x - 12, y: point.y - 12))
    }
}
