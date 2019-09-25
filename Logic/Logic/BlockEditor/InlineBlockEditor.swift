//
//  InlineBlockEditor.swift
//  Logic
//
//  Created by Devin Abbott on 9/10/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

private var defaultTextStyle = TextStyle(weight: NSFont.Weight.light, size: 16)
private var defaultPlaceholderTextStyle = TextStyle(weight: NSFont.Weight.light, size: 16, color: NSColor.placeholderTextColor)

public class InlineBlockEditor: AttributedTextView {

    public enum SizeLevel {
        case h1
        case h2
        case h3
        case h4
        case h5
        case h6
        case paragraph

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
        ps.lineHeightMultiple = InlineBlockEditor.lineHeightMultiple - 0.25
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

//    public override func hitTest(_ point: NSPoint) -> NSView? {
//        return nil
//    }

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

//        setContentCompressionResistancePriority(.defaultLow, for: .vertical)
//        setContentHuggingPriority(.defaultLow, for: .horizontal)
//        setContentCompressionResistancePriority(.defaultLow, for: .horizontal)


//        textContainer?.maximumNumberOfLines = -1
//        textContainer?.lineBreakMode = .byWordWrapping
//        textContainer?.widthTracksTextView = true
//        textContainer?.heightTracksTextView = true
//
//        isVerticallyResizable = true

//        selectedTextAttributes = [
//            NSAttributedString.Key.backgroundColor: NSColor.green
//        ]

        delegate = self

//        allowsEditingTextAttributes = true
//
//        isBordered = false

        font = defaultTextStyle.nsFont

//        attributedStringValue = defaultTextStyle.apply(to: "")
//
//        placeholderString = " "
//
//        usesSingleLineMode = false
//
//        lineBreakMode = .byWordWrapping

        focusRingType = .none

        drawsBackground = true

        backgroundColor = .clear

//        onPressEscape = { [unowned self] in
//            if self.commandPaletteIndex != nil {
//                self.commandPaletteIndex = nil
//
//                self.onHideCommandPalette?()
//            } else {
//                self.window?.makeFirstResponder(nil)
//
////                self.placeholderString = " "
//            }
//        }

//        onChangeSelectedRange = { [weak self] range in
//            guard let self = self else { return }
//
//            if range.length > 0 {
//                self.updateToolbar(for: range)
//                self.showToolbar(for: range)
//            } else {
//                InlineToolbarWindow.shared.orderOut(nil)
//            }
//        }
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

//    public override func handleChangeTextValue(_ value: NSAttributedString) {
//        super.handleChangeTextValue(value)
//    }

    private func updateSharedToolbarWindow(traits: [InlineTextTrait]) {
        InlineToolbarWindow.shared.isBoldEnabled = traits.contains(.bold)
        InlineToolbarWindow.shared.isItalicEnabled = traits.contains(.italic)
        InlineToolbarWindow.shared.isCodeEnabled = traits.contains(.code)
        InlineToolbarWindow.shared.isStrikethroughEnabled = traits.contains(.strikethrough)
    }

    private func updateToolbar(for range: NSRange) {
        var traits: [InlineTextTrait] = .init(attributes: self.textValue.fontAttributes(in: range))
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

            traits = .init(attributes: self.textValue.fontAttributes(in: range))
            self.updateSharedToolbarWindow(traits: traits)
        }
    }

    private func showToolbar(for range: NSRange) {
        let rect = firstRect(forCharacterRange: range, actualRange: nil)

        InlineToolbarWindow.shared.anchorTo(rect: rect, verticalOffset: 4)
        self.window?.addChildWindow(InlineToolbarWindow.shared, ordered: .above)
    }

//    public override func becomeFirstResponder() -> Bool {
//        let result = super.becomeFirstResponder()
//
//        if result {
//            //            Swift.print("Become")
////            placeholderString = "Type '/' for commands"
////            needsDisplay = true
//
//            selectedRange = .init(location: 0, length: 0)
//            onFocus?()
//        }
//
//        return result
//    }

    public override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()

        if result {
            InlineToolbarWindow.shared.orderOut(nil)
        }

        return result
    }

    public override func doCommand(by selector: Selector) {
        if selector == #selector(NSResponder.deleteBackward(_:)) && selectedRange == .empty {
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

        let marginBottom: CGFloat = 10

        return .init(width: size.width, height: ceil(size.height + marginBottom))
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
}

// MARK: - NSLayoutManagerDelegate

// https://christiantietze.de/posts/2017/07/nstextview-proper-line-height/

extension InlineBlockEditor: NSLayoutManagerDelegate {

    public func layoutManager(
        _ layoutManager: NSLayoutManager,
        shouldSetLineFragmentRect lineFragmentRect: UnsafeMutablePointer<NSRect>,
        lineFragmentUsedRect: UnsafeMutablePointer<NSRect>,
        baselineOffset: UnsafeMutablePointer<CGFloat>,
        in textContainer: NSTextContainer,
        forGlyphRange glyphRange: NSRange) -> Bool {

        let fontLineHeight = layoutManager.defaultLineHeight(for: textStyle.nsFont)
        let lineHeight = fontLineHeight * InlineBlockEditor.lineHeightMultiple
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
        let lineHeight = fontLineHeight * InlineBlockEditor.lineHeightMultiple
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
