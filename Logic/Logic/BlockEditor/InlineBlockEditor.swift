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
                    [.font: newFont, .foregroundColor: NSColor.textColor],
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
                self.placeholderAttributedString = placeholderTextStyle.apply(to: placeholderAttributedString)
            }
        }
    }

    private var textStyle: TextStyle {
        return defaultTextStyle.with(weight: sizeLevel.fontWeight, size: sizeLevel.fontSize)
    }

    private var placeholderTextStyle: TextStyle {
        return defaultPlaceholderTextStyle.with(weight: sizeLevel.fontWeight, size: sizeLevel.fontSize)
    }

    public func setPlaceholder(string: String) {
        placeholderAttributedString = placeholderTextStyle.apply(to: string)
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

//    override public var intrinsicContentSize: NSSize {
//        get {
//            let intrinsicSize = super.intrinsicContentSize
//
//            var size: NSSize
//
//            if textValue.length > 0 {
//                size = textValue.measure(width: bounds.width)
//            } else if let placeholder = placeholderAttributedString {
//                size = placeholder.measure(width: bounds.width)
//            } else {
//                size = NSAttributedString(string: " ", attributes: [.font: defaultTextStyle.nsFont]).measure(width: bounds.width)
//            }
//
//            Swift.print(size)
//
//            return .init(width: intrinsicSize.width, height: size.height)
//        }
//    }

    override public var intrinsicContentSize: NSSize {
        guard let container = textContainer, let manager = container.layoutManager else {
            return super.intrinsicContentSize
        }
        manager.ensureLayout(for: container)
        let size = manager.usedRect(for: container).size

        return .init(width: size.width, height: ceil(size.height + sizeLevel.fontSize * 0.2))
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

extension NSAttributedString {
    func measure(width: CGFloat, maxNumberOfLines: Int = -1) -> NSSize {
        let textContainer = NSTextContainer(containerSize: NSSize(width: width, height: CGFloat.greatestFiniteMagnitude))
        textContainer.lineBreakMode = .byTruncatingTail
        textContainer.lineFragmentPadding = 0.0
        if maxNumberOfLines > -1 {
            textContainer.maximumNumberOfLines = maxNumberOfLines
        }

        let textStorage = NSTextStorage(attributedString: self)

        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        layoutManager.glyphRange(for: textContainer)

        return layoutManager.usedRect(for: textContainer).size
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
