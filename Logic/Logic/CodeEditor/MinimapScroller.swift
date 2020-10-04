//
//  MinimapScroller.swift
//  Logic
//
//  Created by Devin Abbott on 7/27/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

public class MinimapScroller: NSScroller {

    // MARK: Public

    public var drawKnobSlot: ((NSRect, NSSize, Bool) -> Void)?

    public var knobColor = MinimapScroller.defaultKnobColor { didSet { needsDisplay = true } }

    public var dividerColor = MinimapScroller.defaultDividerColor { didSet { needsDisplay = true } }

    public var fillColor = MinimapScroller.defaultFillColor { didSet { needsDisplay = true } }

    public static var defaultFillColor: NSColor = Colors.blockBackground

    public static var defaultDividerColor: NSColor = NSColor.clear

    public static var defaultKnobColor: NSColor = NSColor.systemBlue.withAlphaComponent(0.2)

    public static var renderingScale: CGFloat = 0.2

    public static var standardScrollerWidth: CGFloat = 100

    // MARK: Rendering

    public override func drawKnob() {
        var knobRect = rect(for: NSScroller.Part.knob)
        knobRect.origin.x += 1
        knobRect.size.width -= 1

        knobColor.setFill()
        knobRect.fill()
    }

    public override func drawKnobSlot(in slotRect: NSRect, highlight flag: Bool) {
        dividerColor.setFill()
        NSRect(x: slotRect.origin.x, y: slotRect.origin.y, width: 1, height: bounds.height).fill()

        var slotRect = slotRect
        slotRect.origin.x += 2
        slotRect.size.width -= 2
        slotRect.origin.y -= slotOverflow * CGFloat(floatValue)

        let scaledDocumentSize = NSSize(width: slotRect.width, height: slotDocumentHeight)

        drawKnobSlot?(slotRect, scaledDocumentSize, flag)
    }

    public override func draw(_ dirtyRect: NSRect) {
        fillColor.setFill()
        dirtyRect.fill()

        super.draw(dirtyRect)
    }

    // MARK: Measuring

    public override class func scrollerWidth(for controlSize: NSControl.ControlSize, scrollerStyle: NSScroller.Style) -> CGFloat {
        switch controlSize {
        case .mini:
            return standardScrollerWidth
        case .small:
            return standardScrollerWidth * 4 / 3
        case .regular:
            return standardScrollerWidth * 5 / 3
        default:
            return standardScrollerWidth
        }
    }

    public override var floatValue: Float {
        didSet {
            if floatValue != oldValue {
                needsDisplay = true
            }
        }
    }

    private var scrollViewContentHeight: CGFloat {
        guard let scrollView = superview as? NSScrollView else { return 0 }

        return scrollView.contentSize.height
    }

    private var scrollViewDocumentHeight: CGFloat {
        guard let scrollView = superview as? NSScrollView else { return 0 }

        let padding = scrollView.contentInsets.top + scrollView.contentInsets.bottom
        
        return (scrollView.documentView?.frame.height ?? 0) + padding
    }

    private var slotDocumentHeight: CGFloat {
        return pages * scrollViewContentHeight * MinimapScroller.renderingScale
    }

    private var slotHeight: CGFloat {
        return min(slotDocumentHeight, bounds.height)
    }

    private var slotOverflow: CGFloat {
        return slotDocumentHeight - slotHeight
    }

    private var pages: CGFloat {
        return scrollViewDocumentHeight / scrollViewContentHeight
    }

    public override func rect(for partCode: NSScroller.Part) -> NSRect {
        let scrollerWidth = MinimapScroller.scrollerWidth(for: controlSize, scrollerStyle: scrollerStyle)

        switch partCode {
        case .knob:
            let slotRemainderHeight = (pages - 1) * scrollViewContentHeight * MinimapScroller.renderingScale
            let knobHeight = scrollViewContentHeight * MinimapScroller.renderingScale

            return NSRect(
                x: 0,
                y: slotRemainderHeight * CGFloat(floatValue) * ((slotHeight - knobHeight) / (slotDocumentHeight - knobHeight)),
                width: scrollerWidth,
                height: knobHeight
            )
        case .knobSlot:
            return NSRect(x: 0, y: 0, width: scrollerWidth, height: slotHeight)
        case .incrementPage:
            let knobRect = rect(for: .knob)
            let slotRect = rect(for: .knobSlot)

            return NSRect(x: 0, y: knobRect.maxY, width: scrollerWidth, height: slotRect.maxY - knobRect.maxY)
        case .decrementPage:
            let knobRect = rect(for: .knob)

            return NSRect(x: 0, y: 0, width: scrollerWidth, height: knobRect.minY)
        default:
            return .zero
        }
    }

    // MARK: Event handling

    public override func trackKnob(with event: NSEvent) {
        guard let window = window, let scrollView = superview as? NSScrollView else { return }

        let scrollableHeight = scrollViewDocumentHeight - scrollViewContentHeight

        if scrollableHeight <= 0 { return }

        let initialPosition = convert(event.locationInWindow, from: nil)
        let initialValue = CGFloat(floatValue)

        let slotHeight = rect(for: .knobSlot).height
        let knobHeight = rect(for: .knob).height

        trackingLoop: while true {
            let event = window.nextEvent(matching: [.leftMouseUp, .leftMouseDragged])!
            let position = convert(event.locationInWindow, from: nil)

            switch event.type {
            case .leftMouseDragged:
                let percent = (position.y - initialPosition.y) / (slotHeight - knobHeight)
                let value = max(min(initialValue + percent, 1), 0)

                floatValue = Float(value)

                scrollView.scroll(
                    scrollView.contentView,
                    to: NSPoint(
                        x: scrollView.contentView.bounds.origin.x,
                        y: scrollableHeight * value - scrollView.contentInsets.top
                    )
                )
            case .leftMouseUp:
                break trackingLoop
            default:
                break
            }
        }
    }

    public override func mouseDown(with event: NSEvent) {
        let position = convert(event.locationInWindow, from: nil)

        if rect(for: .incrementPage).contains(position) || rect(for: .decrementPage).contains(position) {
            guard let scrollView = superview as? NSScrollView else { return }

            let scrollableHeight = scrollViewDocumentHeight - scrollViewContentHeight

            if scrollableHeight <= 0 { return }

            let slotHeight = rect(for: .knobSlot).height
            let knobHeight = rect(for: .knob).height

            let percent = (position.y - (knobHeight / 2)) / (slotHeight - knobHeight)
            let value = max(min(percent, 1), 0)

            floatValue = Float(value)

            scrollView.scroll(
                scrollView.contentView,
                to: NSPoint(
                    x: scrollView.contentView.bounds.origin.x,
                    y: scrollableHeight * value - scrollView.contentInsets.top
                )
            )

            trackKnob(with: event)
        } else {
            super.mouseDown(with: event)
        }
    }
}
