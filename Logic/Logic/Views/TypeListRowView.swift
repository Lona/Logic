//
//  TypeListRowView.swift
//  Logic
//
//  Created by Devin Abbott on 9/24/18.
//  Copyright © 2018 BitDisco, Inc. All rights reserved.
//

import AppKit
import Foundation

class TypeListRowView: NSTableRowView {

    // MARK: Lifecycle

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        addTrackingArea(trackingArea)
    }

    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        removeTrackingArea(trackingArea)
    }

    // MARK: Public

    override var isSelected: Bool {
        didSet {
            subviews.forEach({ view in
                if var view = view as? Selectable {
                    view.isSelected = isSelected
                }
            })
        }
    }

    // MARK: Private

    private var hovered = false {
        didSet {
            subviews.forEach({ view in
                if var view = view as? Hoverable {
                    view.isHovered = hovered
                }
            })
        }
    }

    private lazy var trackingArea = NSTrackingArea(
        rect: self.frame,
        options: [.mouseEnteredAndExited, .activeAlways, .mouseMoved, .inVisibleRect],
        owner: self)


    public override func mouseEntered(with event: NSEvent) {
        updateHoverState(with: event)
    }

    public override func mouseExited(with event: NSEvent) {
        updateHoverState(with: event)
    }

    private func updateHoverState(with event: NSEvent) {
        let hovered = bounds.contains(convert(event.locationInWindow, from: nil))

        if hovered != self.hovered {
            self.hovered = hovered
        }
    }
}
