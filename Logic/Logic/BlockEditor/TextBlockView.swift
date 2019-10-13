//
//  TextBlockView.swift
//  Logic
//
//  Created by Devin Abbott on 9/10/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

private var defaultTextStyle = TextStyle(weight: NSFont.Weight.light, size: 16)
private var defaultPlaceholderTextStyle = TextStyle(weight: NSFont.Weight.light, size: 16, color: NSColor.placeholderTextColor)

public class TextBlockView: AttributedTextView {

    public enum SizeLevel: Int {
        case h1 = 1
        case h2 = 2
        case h3 = 3
        case h4 = 4
        case h5 = 5
        case h6 = 6
        case paragraph = 0

        var blockDescription: String {
            switch self {
            case .paragraph: return "Text"
            case .h6: return "Heading 6"
            case .h5: return "Heading 5"
            case .h4: return "Heading 4"
            case .h3: return "Heading 3"
            case .h2: return "Heading 2"
            case .h1: return "Heading 1"
            }
        }

        var fontSize: CGFloat {
            switch self {
            case .paragraph: return 16
            case .h6, .h5, .h4: return 16
            case .h3: return 22
            case .h2: return 28
            case .h1: return 36
            }
        }

        var fontWeight: NSFont.Weight {
            // This affects bold trait detection
            return .regular
//            switch self {
//            case .paragraph: return .light
//            case .h6, .h5, .h4: return .regular
//            case .h3: return .medium
//            case .h2: return .medium
//            case .h1: return .medium
//            }
        }

        public var prefix: String? {
            switch self {
            case .paragraph: return nil
            case .h6, .h5, .h4: return nil
            case .h3: return "###"
            case .h2: return "##"
            case .h1: return "#"
            }
        }

        func apply(to textValue: NSAttributedString) -> NSAttributedString {
            let newTextValue = NSMutableAttributedString(attributedString: textValue)

            newTextValue.enumerateAttribute(.font, in: NSRange(location: 0, length: textValue.length), options: [], using: { value, range, boolPointer in
                let font = (value as? NSFont) ?? defaultTextStyle.nsFont
                guard let newFont = NSFont(descriptor: font.fontDescriptor, size: self.fontSize) else { return }
//                newTextValue.addAttribute(.font, value: newFont, range: range)

                newTextValue.addAttributes(
                    [.font: newFont, .foregroundColor: NSColor.textColor.withAlphaComponent(0.8)],
                    range: range
                )
            })

            return newTextValue
        }

        public static let headings: [SizeLevel] = [.h1, .h2, .h3, .h4, .h5, .h6]
    }

    public var sizeLevel: SizeLevel = .paragraph {
        didSet {
//            Swift.print("set size level", sizeLevel)

            if oldValue == sizeLevel { return }

            font = textStyle.nsFont

            if let placeholderAttributedString = self.placeholderAttributedString {
                self.placeholderAttributedString = NSAttributedString(string: placeholderAttributedString.string, attributes: placeholderTextStyle)
            }
        }
    }

    private var textStyle: TextStyle {
        return defaultTextStyle.with(weight: sizeLevel.fontWeight, size: sizeLevel.fontSize)
    }

    private var placeholderTextStyle: [NSAttributedString.Key: Any] {
        let ps = NSMutableParagraphStyle()
        ps.lineHeightMultiple = TextBlockView.lineHeightMultiple - 0.25
        var attributes = defaultPlaceholderTextStyle.with(weight: sizeLevel.fontWeight, size: sizeLevel.fontSize).attributeDictionary
        attributes[.paragraphStyle] = ps
        return attributes
    }

    public func setPlaceholder(string: String) {
        placeholderAttributedString = NSAttributedString(string: string, attributes: placeholderTextStyle)
    }

    @objc private var placeholderAttributedString: NSAttributedString? {
        didSet {
            needsDisplay = true
        }
    }

    // MARK: Lifecycle

    public override func sharedInit() {
        super.sharedInit()

        let layoutManager = InlineBlockLayoutManager()
        layoutManager.getFont = { [weak self] in
            guard let self = self else { return nil }
            return self.textStyle.nsFont
        }
        layoutManager.delegate = self

        textContainer?.replaceLayoutManager(layoutManager)

        setContentHuggingPriority(.defaultHigh, for: .vertical)

        delegate = self

        font = defaultTextStyle.nsFont

        focusRingType = .none

        drawsBackground = true

        backgroundColor = .clear
    }

    public func showInlineToolbar(for range: NSRange) {
        if range.length > 0 {
            self.updateToolbar(for: range)
            self.showToolbar(for: range)
        } else {
            InlineToolbarWindow.shared.orderOut(nil)
        }
    }

    // MARK: Public

    public var onFocus: (() -> Void)?

    public var onOpenReplacementPalette: ((NSRect) -> Void)?

    public var onMoveToBeginningOfDocument: (() -> Void)?

    public var onMoveToEndOfDocument: (() -> Void)?

    public var onOpenLinkEditor: ((NSRect) -> Void)?

    public var onRequestCreateEditor: ((NSAttributedString) -> Void)?

    public var onRequestDeleteEditor: (() -> Void)?

    public var onPressUp: (() -> Void)?

    public var onPressDown: (() -> Void)?

    public var onMoveUp: ((NSRect) -> Void)?

    public var onMoveDown: ((NSRect) -> Void)?

    public var onSelectUp: (() -> Void)?

    public var onSelectDown: (() -> Void)?

    public var width: CGFloat = 0 {
        didSet {
            widthConstraint.constant = width
            if !widthConstraint.isActive {
                widthConstraint.isActive = true
            }
        }
    }

    public static var lineHeightMultiple: CGFloat = 1.44

    // MARK: Private

    private lazy var widthConstraint: NSLayoutConstraint = {
        let constraint = self.widthAnchor.constraint(equalToConstant: self.width)
        return constraint
    }()

    public override func prepareTextValue(_ value: NSAttributedString) -> NSAttributedString {
        return sizeLevel.apply(to: value)
//        let mutable = NSMutableAttributedString(attributedString: value)
//
//        let style = NSMutableParagraphStyle()
//
//        style.lineSpacing = 10
//
//        mutable.addAttribute(.paragraphStyle, value: style, range: NSRange(location: 0, length: value.length))
//
//        return mutable
    }

    private func updateSharedToolbarWindow(traits: [InlineTextTrait]) {
        InlineToolbarWindow.shared.isBoldEnabled = traits.contains(.bold)
        InlineToolbarWindow.shared.isItalicEnabled = traits.contains(.italic)
        InlineToolbarWindow.shared.isCodeEnabled = traits.contains(.code)
        InlineToolbarWindow.shared.isStrikethroughEnabled = traits.contains(.strikethrough)
        InlineToolbarWindow.shared.isLinkEnabled = traits.isLink
        InlineToolbarWindow.shared.replaceCommandLabel = sizeLevel.blockDescription
    }

    private func updateToolbar(for range: NSRange) {
        var traits: [InlineTextTrait] = .init(attributes: self.textValue.attributes(at: range.location, longestEffectiveRange: nil, in: range))

        self.updateSharedToolbarWindow(traits: traits)

        InlineToolbarWindow.shared.onCommand = { [unowned self] command in
            let mutable = NSMutableAttributedString(attributedString: self.textValue)

            func update(trait: InlineTextTrait) {
                if traits.contains(trait) {
                    mutable.remove(trait: trait, range: range)
                } else {
                    mutable.add(trait: trait, range: range)
                }
            }

            switch command {
            case .replace:
                if let rect = InlineToolbarWindow.shared.screenRect(for: command) {
                    self.onOpenReplacementPalette?(rect)
                }
                return
            case .link:
                if let rect = InlineToolbarWindow.shared.screenRectForFirstCommand() {
                    self.onOpenLinkEditor?(rect)
                }
                return
            case .bold:
                update(trait: .bold)
                self.onChangeTextValue?(mutable)
            case .italic:
                update(trait: .italic)
                self.onChangeTextValue?(mutable)
            case .strikethrough:
                update(trait: .strikethrough)
                self.onChangeTextValue?(mutable)
            case .code:
                update(trait: .code)
                self.onChangeTextValue?(mutable)
            default:
                break
            }

            traits = .init(attributes: self.textValue.attributes(at: range.location, longestEffectiveRange: nil, in: range))

            self.updateSharedToolbarWindow(traits: traits)
        }
    }

    private func showToolbar(for range: NSRange) {
        let rect = firstRect(forCharacterRange: range, actualRange: nil)

        InlineToolbarWindow.shared.anchorTo(rect: rect, verticalOffset: 4)
        self.window?.addChildWindow(InlineToolbarWindow.shared, ordered: .above)
    }

    public override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()

        if result {
            InlineToolbarWindow.shared.orderOut(nil)
        }

        return result
    }

    public override func doCommand(by selector: Selector) {
        if selector == #selector(NSResponder.moveToBeginningOfDocument) {
            onMoveToBeginningOfDocument?()
            return
        } else if selector == #selector(NSResponder.moveToEndOfDocument) {
            onMoveToEndOfDocument?()
            return
        } else if selector == #selector(NSResponder.deleteBackward(_:)) && selectedRange == .empty {
            onRequestDeleteEditor?()
            return
//        } else if selector == #selector(NSResponder.insertNewline(_:)) {
//            let selectedRange = self.selectedRange
//            let remainingRange = NSRange(location: selectedRange.upperBound, length: textValue.length - selectedRange.upperBound)
//            let suffix = textValue.attributedSubstring(from: remainingRange)
//            let prefix = textValue.attributedSubstring(from: NSRange(location: 0, length: selectedRange.upperBound))
//
//            onRequestCreateEditor?(suffix)
//            onChangeTextValue?(prefix)
//
////            Swift.print("remainder", suffix.string)
//
//            return
        } else if selector == #selector(NSResponder.moveUp) {
            onPressUp?()

            if currentLineFragmentIndex == 0 {
                let rect = firstRect(forCharacterRange: selectedRange(), actualRange: nil)
                onMoveUp?(rect)
                return
            }
        } else if selector == #selector(NSResponder.moveUpAndModifySelection) {
            if currentLineFragmentIndex == 0 {
                onSelectUp?()
                return
            }
        } else if selector == #selector(NSResponder.moveDown) {
            onPressDown?()

            if currentLineFragmentIndex == lineRects.count - 1 {
                let rect = firstRect(forCharacterRange: selectedRange(), actualRange: nil)
                onMoveDown?(rect)
                return
            }
        } else if selector == #selector(NSResponder.moveDownAndModifySelection) {
            if currentLineFragmentIndex == lineRects.count - 1 {
                onSelectDown?()
                return
            }
        }

        return super.doCommand(by: selector)
    }

    // MARK: Menu Actions

    @objc public func addFontTrait(_ sender: AnyObject) {
        guard let menuItem = sender as? NSMenuItem else { return }

        if self.selectedRange.length > 0 {
            switch menuItem.tag {
            case 1:
                InlineToolbarWindow.shared.onCommand?(.italic)
            case 2:
                InlineToolbarWindow.shared.onCommand?(.bold)
            default:
                break
            }
        } else {
            // If there's no selection, we only update the NSAttributedString internally
            NSFontManager.shared.addFontTrait(sender)
        }
    }

    // MARK: Layout

    override public var intrinsicContentSize: NSSize {
        let size = lineRects.union.size

        return .init(width: size.width, height: ceil(size.height))
    }

    func textDidChange(_ notification: Notification) {
        invalidateIntrinsicContentSize()
    }

    public override func layout() {
        super.layout()

        // Workaround to fix extra blank line on first render
        invalidateIntrinsicContentSize()
    }

    public func setSelectedRangesWithoutNotification(_ ranges: [NSValue]) {
        super.setSelectedRanges(ranges, affinity: .downstream, stillSelecting: true)
    }
}

extension NSTextView {
    var lineRects: [NSRect] {
        guard let container = textContainer, let manager = container.layoutManager else { return [] }

        let fullGlyphRange = manager.glyphRange(for: container)
        var rects: [NSRect] = []

        manager.enumerateLineFragments(forGlyphRange: fullGlyphRange) { (rect, usedRect, textContainer, glyphRange, boolPointer) in
            rects.append(rect)
        }

        if manager.extraLineFragmentRect.height > 4 {
            rects.append(manager.extraLineFragmentRect)
        }

        return rects
    }

    var currentLineFragmentIndex: Int? {
        guard let container = textContainer, let manager = container.layoutManager else { return nil }

        let selectedGlyphRange = manager.glyphRange(forCharacterRange: selectedRange(), actualCharacterRange: nil)
        let selectedGlyphRect = manager.boundingRect(forGlyphRange: selectedGlyphRange, in: container)

        for (line, rect) in lineRects.enumerated() {
            if rect.minY <= selectedGlyphRect.midY && selectedGlyphRect.midY <= rect.maxY {
                return line
            }
        }

        return nil
    }

    public func nearestCharacter(at point: NSPoint) -> Int? {
        guard let container = textContainer, let manager = container.layoutManager else { return nil }

        let glyph = manager.glyphIndex(for: point, in: container, fractionOfDistanceThroughGlyph: nil)

        return manager.characterIndexForGlyph(at: glyph)
    }


    public var linkRects: [(rect: NSRect, url: NSURL)] {
        guard let container = textContainer, let manager = container.layoutManager else { return [] }

        let textValue = attributedString()
        var values: [(NSRect, NSURL)] = []

        textValue.enumerateAttribute(.link, in: .init(location: 0, length: textValue.length), options: []) { (value, range, pointer) in
            guard let link = value as? NSURL else { return }

            let glyphRange = manager.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
            let rect = manager.boundingRect(forGlyphRange: glyphRange, in: container)

            values.append((rect, link))
        }

        return values
    }
}

// MARK: - NSLayoutManagerDelegate

// https://christiantietze.de/posts/2017/07/nstextview-proper-line-height/

extension TextBlockView: NSLayoutManagerDelegate {

    public func layoutManager(
        _ layoutManager: NSLayoutManager,
        shouldSetLineFragmentRect lineFragmentRect: UnsafeMutablePointer<NSRect>,
        lineFragmentUsedRect: UnsafeMutablePointer<NSRect>,
        baselineOffset: UnsafeMutablePointer<CGFloat>,
        in textContainer: NSTextContainer,
        forGlyphRange glyphRange: NSRange) -> Bool {

        let fontLineHeight = layoutManager.defaultLineHeight(for: textStyle.nsFont)
        let lineHeight = fontLineHeight * TextBlockView.lineHeightMultiple
        let baselineNudge = (lineHeight - fontLineHeight)
            // The following factor is a result of experimentation:
            * 0.5

        var rect = lineFragmentRect.pointee
        rect.size.height = lineHeight

        var usedRect = lineFragmentUsedRect.pointee
        usedRect.size.height = max(lineHeight, usedRect.size.height) // keep emoji sizes

        lineFragmentRect.pointee = rect
        lineFragmentUsedRect.pointee = usedRect
        baselineOffset.pointee = baselineOffset.pointee + baselineNudge

        return true
    }
}

class InlineBlockLayoutManager: NSLayoutManager {

    var getFont: (() -> NSFont?) = { return nil }

    private var font: NSFont {
        return getFont() ?? defaultTextStyle.nsFont
    }

    private var lineHeight: CGFloat {
        let fontLineHeight = self.defaultLineHeight(for: font)
        let lineHeight = fontLineHeight * TextBlockView.lineHeightMultiple
        return lineHeight
    }

    // Takes care only of the last empty newline in the text backing
    // store, or totally empty text views.
    override func setExtraLineFragmentRect(
        _ fragmentRect: NSRect,
        usedRect: NSRect,
        textContainer container: NSTextContainer) {

        // This is only called when editing, and re-computing the
        // `lineHeight` isn't that expensive, so I do no caching.
        let lineHeight = self.lineHeight
        var fragmentRect = fragmentRect
        fragmentRect.size.height = lineHeight
        var usedRect = usedRect
        usedRect.size.height = lineHeight

        super.setExtraLineFragmentRect(fragmentRect,
            usedRect: usedRect,
            textContainer: container)
    }
}
