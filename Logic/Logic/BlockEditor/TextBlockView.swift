//
//  TextBlockView.swift
//  Logic
//
//  Created by Devin Abbott on 9/10/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

public class TextBlockContainerView: NSBox {

    public override var isFlipped: Bool {
        return true
    }

    // MARK: Lifecycle

    public init() {
        super.init(frame: .zero)

        setUpViews()
        setUpConstraints()

        update()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setUpViews()
        setUpConstraints()

        update()
    }

    // MARK: Public

    public func firstRect(forCharacterRange range: NSRange) -> NSRect {
        return blockView.firstRect(forCharacterRange: range, actualRange: nil)
    }

    public func setPlaceholder(string: String) {
        blockView.setPlaceholder(string: string)
    }

    public func setSelectedRangesWithoutNotification(_ ranges: [NSValue]) {
        blockView.setSelectedRangesWithoutNotification(ranges)
    }

    public func characterIndexForInsertion(at point: NSPoint) -> Int {
        return blockView.characterIndexForInsertion(at: point)
    }

    public func showInlineToolbar(for range: NSRange) {
        blockView.showInlineToolbar(for: range)
    }

    // AttributedTextView

    public var lineRects: [NSRect] {
        return blockView.lineRects
    }

    public var linkRects: [(rect: NSRect, url: NSURL)] {
        return blockView.linkRects
    }

    public var selectedRange: NSRange {
        return blockView.selectedRange()
    }

    public var insertionPointColor: NSColor {
        get { return blockView.insertionPointColor }
        set { blockView.insertionPointColor = newValue }
    }

    public var onDidChangeText: (() -> Void)? {
        get { return blockView.onDidChangeText }
        set { blockView.onDidChangeText = newValue }
    }

    public var onChangeSelectedRange: ((NSRange) -> Void)? {
        get { return blockView.onChangeSelectedRange }
        set { blockView.onChangeSelectedRange = newValue }
    }

    public var onChangeTextValue: ((NSAttributedString) -> Void)? {
        get { return blockView.onChangeTextValue }
        set { blockView.onChangeTextValue = newValue }
    }

    public var onSubmit: (() -> Void)? {
        get { return blockView.onSubmit }
        set { blockView.onSubmit = newValue }
    }

    public var onPressEscape: (() -> Void)? {
        get { return blockView.onPressEscape }
        set { blockView.onPressEscape = newValue }
    }

    // TextBlockView

    public var sizeLevel: TextBlockView.SizeLevel {
        get { return blockView.sizeLevel }
        set { blockView.sizeLevel = newValue }
    }

    public var textValue: NSAttributedString {
        get { return blockView.textValue }
        set { blockView.textValue = newValue }
    }

    public var width: CGFloat {
        get { return blockView.width }
        set { blockView.width = newValue }
    }

    public var onFocus: (() -> Void)? {
        get { return blockView.onFocus }
        set { blockView.onFocus = newValue }
    }

    public var onOpenReplacementPalette: ((NSRect) -> Void)? {
        get { return blockView.onOpenReplacementPalette }
        set { blockView.onOpenReplacementPalette = newValue }
    }

    public var onMoveToBeginningOfDocument: (() -> Void)? {
        get { return blockView.onMoveToBeginningOfDocument }
        set { blockView.onMoveToBeginningOfDocument = newValue }
    }

    public var onMoveToEndOfDocument: (() -> Void)? {
        get { return blockView.onMoveToEndOfDocument }
        set { blockView.onMoveToEndOfDocument = newValue }
    }

    public var onOpenLinkEditor: ((NSRect) -> Void)? {
        get { return blockView.onOpenLinkEditor }
        set { blockView.onOpenLinkEditor = newValue }
    }

    public var onRequestCreateEditor: ((NSAttributedString) -> Void)? {
        get { return blockView.onRequestCreateEditor }
        set { blockView.onRequestCreateEditor = newValue }
    }

    public var onRequestDeleteEditor: (() -> Void)? {
        get { return blockView.onRequestDeleteEditor }
        set { blockView.onRequestDeleteEditor = newValue }
    }

    public var onPressUp: (() -> Void)? {
        get { return blockView.onPressUp }
        set { blockView.onPressUp = newValue }
    }

    public var onPressDown: (() -> Void)? {
        get { return blockView.onPressDown }
        set { blockView.onPressDown = newValue }
    }

    public var onMoveUp: ((NSRect) -> Void)? {
        get { return blockView.onMoveUp }
        set { blockView.onMoveUp = newValue }
    }

    public var onMoveDown: ((NSRect) -> Void)? {
        get { return blockView.onMoveDown }
        set { blockView.onMoveDown = newValue }
    }

    public var onSelectUp: (() -> Void)? {
        get { return blockView.onSelectUp }
        set { blockView.onSelectUp = newValue }
    }

    public var onSelectDown: (() -> Void)? {
        get { return blockView.onSelectDown }
        set { blockView.onSelectDown = newValue }
    }

    // MARK: Private

    let blockView = TextBlockView()

    private func setUpViews() {
        boxType = .custom
        borderType = .noBorder
        contentViewMargins = .zero

        addSubview(blockView)
    }

    private func setUpConstraints() {
        translatesAutoresizingMaskIntoConstraints = false
        blockView.translatesAutoresizingMaskIntoConstraints = false

        blockView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        blockView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        blockView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        blockView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
    }

    private func update() {}

    public func focus() {
        if blockView.acceptsFirstResponder {
            window?.makeFirstResponder(blockView)
        }
    }
}

public class TextBlockView: AttributedTextView {

    public static var defaultTextStyle = TextStyle(weight: NSFont.Weight.light, size: 16)

    public static var defaultPlaceholderTextStyle = TextStyle(weight: NSFont.Weight.light, size: 16, color: NSColor.placeholderTextColor)

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
                let font = (value as? NSFont) ?? TextBlockView.defaultTextStyle.nsFont
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
        return TextBlockView.defaultTextStyle.with(weight: sizeLevel.fontWeight, size: sizeLevel.fontSize)
    }

    private var placeholderTextStyle: [NSAttributedString.Key: Any] {
        let ps = NSMutableParagraphStyle()
        ps.lineHeightMultiple = TextBlockView.lineHeightMultiple - 0.25
        var attributes = TextBlockView.defaultPlaceholderTextStyle.with(weight: sizeLevel.fontWeight, size: sizeLevel.fontSize).attributeDictionary
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

        font = TextBlockView.defaultTextStyle.nsFont

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
