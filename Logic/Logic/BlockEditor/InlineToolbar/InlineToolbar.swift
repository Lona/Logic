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

private let menuTextStyle = TextStyle(size: 14, lineHeight: 16, color: .black)
private let monospacedMenuTextStyle = TextStyle(family: "Andale Mono", size: 15, lineHeight: 15, kerning: -2, color: .black)

public class InlineToolbar: NSView {

    public enum Command: Hashable {
        case replace(String), divider, bold, italic, strikethrough, code, link

        var label: String {
            switch self {
            case .replace(let label):
                return label
            case .divider:
                return ""
            case .bold:
                return "b"
            case .italic:
                return "i"
            case .strikethrough:
                return "s"
            case .code:
                return "<>"
            case .link:
                return "Link"
            }
        }

        var width: CGFloat {
            switch self {
            case .replace:
                return menuTextStyle.apply(to: label).size().width + 32
            case .link:
                return menuTextStyle.apply(to: label).size().width + 16
            case .divider:
                return 1
            case .bold, .italic, .strikethrough, .code:
                return 24
            }
        }

        var imageTemplate: NSImage {
            if let cached = Command.imageCache[self] {
                return cached
            }

            let image = NSImage(size: .init(width: width, height: InlineToolbar.height), flipped: false, drawingHandler: { rect in
                var string: NSAttributedString? = nil

                NSGraphicsContext.current?.cgContext.setShouldSmoothFonts(false)

                switch self {
                case .replace(let value):
                    string = menuTextStyle.apply(to: value)
                case .link:
                    let mutable = NSMutableAttributedString(attributedString: menuTextStyle.apply(to: "Link"))
                    mutable.addAttributes([NSAttributedString.Key.underlineStyle: 1], range: NSRange(location: 0, length: mutable.length))
                    string = mutable
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
                case .strikethrough:
                    string = menuTextStyle.apply(to: "s")

                    // A single character with a strikethrough doesn't look very clear, so we draw our own
                    NSColor.black.setFill()
                    NSRect(x: rect.midX - 6, y: rect.midY - 2, width: 12, height: 1).fill()
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

                    if case .replace = self {
                        boundingRect.origin.x -= 8

                        let caretRect = NSRect(
                            x: rect.maxX - 16, y: rect.midY - 2.5, width: 6, height: 3.5)

                        Colors.text.withAlphaComponent(0.5).setStroke()
                        let path = NSBezierPath(caretWithin: caretRect, pointing: .down)
                        path.lineCapStyle = .round
                        path.stroke()
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
        let buttonRects = self.buttonRects

        for index in 0..<commands.count {
            if buttonRects[index].contains(point) {
                return index
            }
        }

        return nil
    }

    public override func mouseMoved(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        hoveredIndex = index(at: point)

        if hoveredIndex != clickedIndex {
            clickedIndex = nil
        }
    }

    public override func mouseDown(with event: NSEvent) {
        // https://stackoverflow.com/questions/18614974/how-to-prevent-focus-window-when-its-view-is-clicked-by-mouse-on-osx
        NSApp.preventWindowOrdering()

        let point = convert(event.locationInWindow, from: nil)
        if let clickedIndex = index(at: point) {
            self.clickedIndex = clickedIndex
            TooltipManager.shared.hideTooltip()

            Swift.print("Clicked", commands[clickedIndex])
            onCommand?(commands[clickedIndex])
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

    // https://stackoverflow.com/questions/18614974/how-to-prevent-focus-window-when-its-view-is-clicked-by-mouse-on-osx
    public override func shouldDelayWindowOrdering(for event: NSEvent) -> Bool {
        return true
    }

    private func showToolTip(string: String, at point: NSPoint) {
        guard let window = window else { return }
        let windowPoint = convert(point, to: nil)
        let screenPoint = window.convertPoint(toScreen: windowPoint)

        TooltipManager.shared.showTooltip(string: string, point: screenPoint, preferredEdge: .top, delay: .milliseconds(240))
    }

    // MARK: Public

    public var onCommand: ((Command) -> Void)?

    public var replaceCommandLabel: String = "" {
        didSet {
            if oldValue != replaceCommandLabel {
                invalidateIntrinsicContentSize()
                update()
            }
        }
    }

    public var isBoldEnabled: Bool = false {
        didSet {
            if oldValue != isBoldEnabled {
                update()
            }
        }
    }

    public var isItalicEnabled: Bool = false {
        didSet {
            if oldValue != isItalicEnabled {
                update()
            }
        }
    }

    public var isStrikethroughEnabled: Bool = false {
        didSet {
            if oldValue != isStrikethroughEnabled {
                update()
            }
        }
    }

    public var isCodeEnabled: Bool = false {
        didSet {
            if oldValue != isCodeEnabled {
                update()
            }
        }
    }

    public var isLinkEnabled: Bool = false {
        didSet {
            if oldValue != isLinkEnabled {
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

    private var clickedIndex: Int?

    private var hoveredIndex: Int? {
        didSet {
            if oldValue != hoveredIndex {
                update()

                if let index = hoveredIndex, clickedIndex != hoveredIndex {
                    let rect = buttonRects[index]
                    let midpoint = NSPoint(x: rect.midX, y: rect.maxY + 4)
                    switch commands[index] {
                    case .replace:
                        showToolTip(string: "**Replace with...**", at: midpoint)
                    case .bold:
                        showToolTip(string: "**Bold**\n⌘+B", at: midpoint)
                    case .italic:
                        showToolTip(string: "**Italic**\n⌘+I", at: midpoint)
                    case .strikethrough:
                        showToolTip(string: "**Strikethrough**\n⌘+Shift+S", at: midpoint)
                    case .code:
                        showToolTip(string: "**Code**\n⌘+E", at: midpoint)
                    case .link:
                        showToolTip(string: "**Add Link**\n⌘+K", at: midpoint)
                    case .divider:
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
        return NSSize(width: commands.map { $0.width }.reduce(0, +), height: InlineToolbar.height)
    }

    // MARK: Drawing

    public var buttonRects: [NSRect] {
        var result: [NSRect] = []

        var x: CGFloat = 0
        for command in commands {
            let size = NSSize(width: command.width, height: InlineToolbar.height)
            let boundingRect = NSRect(x: x, y: bounds.minY, width: size.width, height: size.height)
            result.append(boundingRect)
            x += command.width
        }

        return result
    }

    public func rect(for command: Command) -> NSRect? {
        guard let index = commands.firstIndex(of: command) else { return nil }
        return buttonRects[index]
    }

    public override func draw(_ dirtyRect: NSRect) {
        NSBezierPath(roundedRect: bounds, xRadius: 4, yRadius: 4).setClip()

        var x: CGFloat = 0
        for (index, command) in commands.enumerated() {
            let size = NSSize(width: command.width, height: InlineToolbar.height)
            let boundingRect = NSRect(x: x, y: bounds.minY, width: size.width, height: size.height)

            if command == .divider {
                Colors.indentGuide.set()
                boundingRect.fill()
            } else if index == hoveredIndex {
                Colors.divider.set()
                boundingRect.fill()
            }

            var selected = false

            switch command {
            case .bold:
                selected = isBoldEnabled
            case .italic:
                selected = isItalicEnabled
            case .strikethrough:
                selected = isStrikethroughEnabled
            case .code:
                selected = isCodeEnabled
            case .link:
                selected = isLinkEnabled
            default:
                break
            }

            command.imageTemplate.tint(color: selected ? Colors.editableText : Colors.text.withAlphaComponent(0.8)).draw(in: boundingRect)

            x += command.width
        }
    }

    public var commands: [Command] {
        return [.replace(replaceCommandLabel), .divider, .bold, .italic, .strikethrough, .code, .link]
    }

    public static var height: CGFloat = 28
}

// MARK: - Parameters

extension InlineToolbar {
    public struct Parameters: Equatable {
        public init() {}
    }
}
