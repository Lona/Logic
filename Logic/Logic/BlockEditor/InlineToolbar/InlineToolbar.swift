//
//  InlineToolbar.swift
//  Logic
//
//  Created by Devin Abbott on 9/10/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import AppKit

private extension NSImage {
    func tint(color: NSColor) -> NSImage {
        let image = self.copy() as! NSImage
        image.lockFocus()

        color.set()

        let imageRect = NSRect(origin: NSZeroPoint, size: image.size)
        imageRect.fill(using: .sourceAtop)

        image.unlockFocus()

        return image
    }
}

// MARK: - InlineToolbar

public class InlineToolbar: NSView {

    public enum Command {
        case divider, blockType, bold, italic, code, link

        var width: CGFloat {
            switch self {
            case .divider:
                return 1
            case .blockType:
                return 80
            case .bold:
                return 24
            case .italic:
                return 24
            case .code:
                return 24
            case .link:
                return 40
            }
        }

        var imageTemplate: NSImage {
            if let cached = Command.imageCache[self] {
                return cached
            }

            let image = NSImage(size: .init(width: width, height: InlineToolbar.height), flipped: false, drawingHandler: { rect in
                let menuTextStyle = TextStyle(size: 14, lineHeight: 14, color: .black)
                let monospacedMenuTextStyle = TextStyle(family: "Andale Mono", size: 15, lineHeight: 15, kerning: -2, color: .black)

                var string: NSAttributedString? = nil

                switch self {
                case .bold:
                    let font = NSFontManager.shared.convert(menuTextStyle.nsFont, toHaveTrait: NSFontTraitMask.boldFontMask)
                    let mutable = NSMutableAttributedString(attributedString: menuTextStyle.apply(to: "b"))
                    mutable.addAttributes([.font: font], range: NSRange(location: 0, length: mutable.length))
                    string = mutable
                case .italic:
                    let font = NSFontManager.shared.convert(menuTextStyle.nsFont, toHaveTrait: NSFontTraitMask.italicFontMask)
                    let mutable = NSMutableAttributedString(attributedString: menuTextStyle.apply(to: "i"))
                    mutable.addAttributes([.font: font], range: NSRange(location: 0, length: mutable.length))
                    string = mutable
                case .code:
                    string = monospacedMenuTextStyle.apply(to: "<>")
                default:
                    break
                }

                if let string = string {
                    let size = string.size()
                    var boundingRect = NSRect(
                        x: rect.midX - size.width / 2,
                        y: rect.midY - size.height / 2,
                        width: size.width,
                        height: size.height
                    )

                    // Nudge
                    if self == .code {
                        boundingRect.origin.x -= 1
                    }

                    string.draw(with: boundingRect, options: [.usesLineFragmentOrigin])
                }

                return true
            })

            image.isTemplate = true

            Command.imageCache[self] = image

            return image
        }

        private static var imageCache: [Command: NSImage] = [:]
    }

    // MARK: Lifecycle

    public init(_ parameters: Parameters) {
        self.parameters = parameters

        super.init(frame: .zero)

        setUpViews()
        setUpConstraints()

        update()

        addTrackingArea(trackingArea)
    }

    public convenience init() {
        self.init(Parameters())
    }

    public required init?(coder aDecoder: NSCoder) {
        self.parameters = Parameters()

        super.init(coder: aDecoder)

        setUpViews()
        setUpConstraints()

        update()

        addTrackingArea(trackingArea)
    }

    private lazy var trackingArea = NSTrackingArea(
        rect: self.frame,
        options: [.mouseEnteredAndExited, .activeInActiveApp, .mouseMoved, .inVisibleRect],
        owner: self)

    deinit {
        removeTrackingArea(trackingArea)
    }

    func index(at point: NSPoint) -> Int? {
        var buttonRects = self.buttonRects

        for index in 0..<InlineToolbar.commands.count {
            if buttonRects[index].contains(point) {
                return index
            }
        }

        return nil
    }

    public override func mouseMoved(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        hoveredIndex = index(at: point)
    }

    public override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        if let clickedIndex = index(at: point) {
            Swift.print("Clicked", InlineToolbar.commands[clickedIndex])
        }
    }

    public override func mouseExited(with event: NSEvent) {
        hoveredIndex = nil
    }

    public override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }

    public override var acceptsFirstResponder: Bool {
        return false
    }

    private func showToolTip(string: String, at point: NSPoint) {
        guard let window = window else { return }
        let windowPoint = convert(point, to: nil)
        let screenPoint = window.convertPoint(toScreen: windowPoint)

        TooltipManager.shared.showTooltip(string: string, point: screenPoint, delay: .milliseconds(240))
    }

    // MARK: Public

    public var onCommand: ((Command) -> Void)?

    public var isBoldEnabled: Bool = false {
        didSet {
            if oldValue != isBoldEnabled {
                update()
            }
        }
    }

    public var parameters: Parameters {
        didSet {
            if parameters != oldValue {
                update()
            }
        }
    }

    // MARK: Private

    private var hoveredIndex: Int? {
        didSet {
            if oldValue != hoveredIndex {
                update()

                if let index = hoveredIndex {
                    let rect = buttonRects[index]
                    let midpoint =  NSPoint(x: rect.midX, y: rect.minY)
                    switch InlineToolbar.commands[index] {
                    case .bold:
                        showToolTip(string: "**Bold**\n⌘+B", at: midpoint)
                    case .italic:
                        showToolTip(string: "**Italic**\n⌘+I", at: midpoint)
                    case .code:
                        showToolTip(string: "**Code**\n⌘+E", at: midpoint)
                    default:
                        break
                    }
                } else {
                    TooltipManager.shared.hideTooltip()
                }
            }
        }
    }

    private func setUpViews() {
    }

    private func setUpConstraints() {
        translatesAutoresizingMaskIntoConstraints = false
    }

    private func update() {
        needsDisplay = true
    }

    public override var intrinsicContentSize: NSSize {
        return NSSize(width: InlineToolbar.commands.map { $0.width }.reduce(0, +), height: InlineToolbar.height)
    }

    // MARK: Drawing

    public var buttonRects: [NSRect] {
        var result: [NSRect] = []

        var x: CGFloat = 0
        for command in InlineToolbar.commands {
            let size = NSSize(width: command.width, height: InlineToolbar.height)
            let boundingRect = NSRect(x: x, y: bounds.minY, width: size.width, height: size.height)
            result.append(boundingRect)
            x += command.width
        }

        return result
    }

    public override func draw(_ dirtyRect: NSRect) {
        NSBezierPath(roundedRect: bounds, xRadius: 4, yRadius: 4).setClip()

//        Colors.background.setFill()
//        dirtyRect.fill()

        var x: CGFloat = 0
        for (index, command) in InlineToolbar.commands.enumerated() {
            let size = NSSize(width: command.width, height: InlineToolbar.height)
            let boundingRect = NSRect(x: x, y: bounds.minY, width: size.width, height: size.height)

            if index == hoveredIndex {
                Colors.divider.set()
                boundingRect.fill()
            }

//            boundingRect.fill(using: .sourceAtop)

            var selected = false

            switch command {
            case .bold:
                selected = isBoldEnabled
            default:
                break
            }

            command.imageTemplate.tint(color: selected ? Colors.editableText : Colors.text.withAlphaComponent(0.8)).draw(in: boundingRect)

            x += command.width
        }
    }

    public static var commands: [Command] = [.bold, .italic, .code, .link]

    public static var height: CGFloat = 28
}

// MARK: - Parameters

extension InlineToolbar {
    public struct Parameters: Equatable {
        public init() {}
    }
}
