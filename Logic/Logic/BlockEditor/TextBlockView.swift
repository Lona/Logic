//
//  TextBlockView.swift
//  Logic
//
//  Created by Devin Abbott on 9/10/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

extension NSPasteboard.PasteboardType {
    public static var mdx = NSPasteboard.PasteboardType.init("mdx")
}

// MARK: - TextBlockContainerView

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
        return blockView.characterIndexForInsertion(at: convert(point, to: blockView))
    }

    public func showInlineToolbar(for range: NSRange) {
        blockView.showInlineToolbar(for: range)
    }

    // AttributedTextView

    public var lineRects: [NSRect] {
        return blockView.lineRects.map { convert($0, from: blockView) }
    }

    public var linkRects: [(rect: NSRect, url: NSURL)] {
        return blockView.linkRects.map {
            return (rect: convert($0.rect, from: blockView), url: $0.url)
        }
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

    private var showsBorderView: Bool = false {
        didSet {
            if showsBorderView == oldValue { return }

            if showsBorderView {
                if borderView == nil {
                    let borderView = NSBox()

                    addSubview(borderView)

                    borderView.boxType = .custom
                    borderView.borderType = .noBorder
                    borderView.fillColor = TextBlockView.SizeLevel.quoteTextColor.withAlphaComponent(0.3)

                    borderView.translatesAutoresizingMaskIntoConstraints = false
                    borderView.widthAnchor.constraint(equalToConstant: 3).isActive = true
                    borderView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6).isActive = true
                    borderView.topAnchor.constraint(equalTo: topAnchor).isActive = true
                    borderView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true

                    self.borderView = borderView
                }

                borderView?.isHidden = false
                leadingAnchorConstraint?.constant = 14
            } else {
                borderView?.isHidden = true
                leadingAnchorConstraint?.constant = 0
            }
        }
    }

    public var sizeLevel: TextBlockView.SizeLevel {
        get { return blockView.sizeLevel }
        set {
            showsBorderView = newValue == .quote
            blockView.sizeLevel = newValue
        }
    }

    public var textValue: NSAttributedString {
        get { return blockView.textValue }
        set { blockView.textValue = newValue }
    }

    public var width: CGFloat {
        get { return blockView.width }
        set { blockView.width = newValue - indentWidth }
    }

    public var onFocus: (() -> Void)? {
        get { return blockView.onFocus }
        set { blockView.onFocus = newValue }
    }

    public var onPasteBlocks: (() -> Void)? {
        get { return blockView.onPasteBlocks }
        set { blockView.onPasteBlocks = newValue }
    }

    public var onRequestInvalidateIntrinsicContentSize: (() -> Void)? {
        get { return blockView.onRequestInvalidateIntrinsicContentSize }
        set { blockView.onRequestInvalidateIntrinsicContentSize = newValue }
    }

    public var onOpenReplacementPalette: ((NSRect) -> Void)? {
        get { return blockView.onOpenReplacementPalette }
        set { blockView.onOpenReplacementPalette = newValue }
    }

    public var onIndent: (() -> Void)? {
        get { return blockView.onIndent }
        set { blockView.onIndent = newValue }
    }

    public var onOutdent: (() -> Void)? {
        get { return blockView.onOutdent }
        set { blockView.onOutdent = newValue }
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

    private var indentWidth: CGFloat {
        return leadingAnchorConstraint?.constant ?? 0
    }

    private var leadingAnchorConstraint: NSLayoutConstraint?

    private var borderView: NSBox?

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
        blockView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true

        leadingAnchorConstraint = blockView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0)
        leadingAnchorConstraint?.isActive = true
    }

    private func update() {}

    public func focus() {
        if blockView.acceptsFirstResponder {
            window?.makeFirstResponder(blockView)
        }
    }

    public override var intrinsicContentSize: NSSize {
        let contentSize = blockView.intrinsicContentSize

        return .init(width: contentSize.width + indentWidth, height: contentSize.height)
    }

    public override func invalidateIntrinsicContentSize() {
        blockView.invalidateIntrinsicContentSize()
        
        super.invalidateIntrinsicContentSize()
    }
}

// MARK: - TextBlockView

public class TextBlockView: AttributedTextView {

    // MARK: SizeLevel

    public enum SizeLevel: Int {
        case h1 = 1
        case h2 = 2
        case h3 = 3
        case h4 = 4
        case h5 = 5
        case h6 = 6
        case paragraph = 0

        case quote = -1

        var blockDescription: String {
            switch self {
            case .paragraph: return "Text"
            case .h6: return "Heading 6"
            case .h5: return "Heading 5"
            case .h4: return "Heading 4"
            case .h3: return "Heading 3"
            case .h2: return "Heading 2"
            case .h1: return "Heading 1"
            case .quote: return "Quote"
            }
        }

        var fontSize: CGFloat {
            switch self {
            case .paragraph, .quote: return 16
            case .h6, .h5, .h4: return 16
            case .h3: return 22
            case .h2: return 28
            case .h1: return 36
            }
        }

        var standardFontWeight: NSFont.Weight {
            switch self {
            case .paragraph, .quote: return .light
            case .h6, .h5, .h4: return .regular
            case .h3: return .medium
            case .h2: return .medium
            case .h1: return .semibold
            }
        }

        var boldFontWeight: NSFont.Weight {
            switch self {
            case .paragraph, .quote: return .bold
            case .h6, .h5, .h4: return .bold
            case .h3: return .bold
            case .h2: return .bold
            case .h1: return .heavy
            }
        }

        public var prefix: String? {
            switch self {
            case .paragraph: return nil
            case .h6, .h5, .h4: return nil
            case .h3: return "###"
            case .h2: return "##"
            case .h1: return "#"
            case .quote: return ">"
            }
        }

        public var textColor: NSColor {
            switch self {
            case .quote:
                return SizeLevel.quoteTextColor
            default:
                return SizeLevel.textColor
            }
        }

        public var textStyle: TextStyle {
            return SizeLevel.textStyleForSizeLevel(self)
        }

        public var placeholderFontAttributes: [NSAttributedString.Key: Any] {
            return SizeLevel.placeholderFontAttributesForSizeLevel(self)
        }

        func apply(to string: String) -> NSAttributedString {
            return apply(to: NSAttributedString(string: string))
        }

        func apply(to textValue: NSAttributedString) -> NSAttributedString {
            let newTextValue = NSMutableAttributedString(attributedString: textValue)

            newTextValue.enumerateAttributes(in: NSRange(location: 0, length: textValue.length), options: []) { (attributes, range, _) in
                let traits: [InlineTextTrait] = .init(attributes: attributes)
                let newAttributes = SizeLevel.attributesForSizeAndTraits(self, traits)

                newTextValue.addAttributes(newAttributes, range: range)

                if !traits.isCode {
                    newTextValue.removeAttribute(.backgroundColor, range: range)
                }
            }

            return newTextValue
        }

        // MARK: Static

        public static var attributesForSizeAndTraits: (SizeLevel, [InlineTextTrait]) -> [NSAttributedString.Key : Any] = Memoize.all { sizeLevel, traits in
            let textStyle = TextStyle(
                family: traits.isCode ? SizeLevel.monospacedFont : nil,
                weight: traits.isBold ? sizeLevel.boldFontWeight : sizeLevel.standardFontWeight,
                size: sizeLevel.fontSize,
                color: sizeLevel.textColor
            )

            var newAttributes = textStyle.attributeDictionary

            if traits.isCode {
                newAttributes[.backgroundColor] = Colors.commentBackground
            }

            if let font = newAttributes[.font] as? NSFont, traits.isItalic {
                newAttributes[.font] = NSFontManager.shared.convert(font, toHaveTrait: .italicFontMask)
            }

            return newAttributes
        }

        public static var textStyleForSizeLevel: (SizeLevel) -> TextStyle = Memoize.all { sizeLevel in
            return TextStyle(weight: sizeLevel.standardFontWeight, size: sizeLevel.fontSize)
        }

        public static var placeholderFontAttributesForSizeLevel: (SizeLevel) -> [NSAttributedString.Key: Any] = Memoize.all { sizeLevel in
             let ps = NSMutableParagraphStyle()
             ps.lineHeightMultiple = TextBlockView.lineHeightMultiple - 0.25
             var attributes = TextStyle(weight: sizeLevel.standardFontWeight, size: sizeLevel.fontSize, color: NSColor.placeholderTextColor).attributeDictionary
             attributes[.paragraphStyle] = ps
             return attributes
        }

        public static let prefixShortcutSizes: [SizeLevel] = [.h1, .h2, .h3, .h4, .h5, .h6, .quote]

        public static var monospacedFont = "Menlo"

        public static var textColor = NSColor.textColor.withAlphaComponent(0.8)

        public static var quoteTextColor = NSColor.textColor.withAlphaComponent(0.5)
    }

    public var sizeLevel: SizeLevel = .paragraph {
        didSet {
            if oldValue == sizeLevel { return }

            updateSizeLevel(to: sizeLevel)
        }
    }

    private func updateSizeLevel(to sizeLevel: SizeLevel) {
        font = sizeLevel.textStyle.nsFont
        textColor = sizeLevel.textColor

        if let placeholderAttributedString = self.placeholderAttributedString {
            self.placeholderAttributedString = NSAttributedString(string: placeholderAttributedString.string, attributes: sizeLevel.placeholderFontAttributes)
        }
    }

    public func setPlaceholder(string: String) {
        placeholderAttributedString = NSAttributedString(string: string, attributes: sizeLevel.placeholderFontAttributes)
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
            return self.sizeLevel.textStyle.nsFont
        }
        layoutManager.delegate = self

        textContainer?.replaceLayoutManager(layoutManager)

        setContentHuggingPriority(.defaultHigh, for: .vertical)

        delegate = self

        focusRingType = .none

        drawsBackground = true

        backgroundColor = .clear

        updateSizeLevel(to: .paragraph)
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

    public var onPasteBlocks: (() -> Void)?

    public var onRequestInvalidateIntrinsicContentSize: (() -> Void)?

    public var onOpenReplacementPalette: ((NSRect) -> Void)?

    public var onIndent: (() -> Void)?

    public var onOutdent: (() -> Void)?

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
            var mutable = NSMutableAttributedString(attributedString: self.textValue)

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
        if selector == #selector(NSResponder.insertTab) {
            onIndent?()
            return
        } else if selector == #selector(NSResponder.insertBacktab) {
            onOutdent?()
            return
        } else if selector == #selector(NSResponder.moveToBeginningOfDocument) {
            onMoveToBeginningOfDocument?()
            return
        } else if selector == #selector(NSResponder.moveToEndOfDocument) {
            onMoveToEndOfDocument?()
            return
        } else if selector == #selector(NSResponder.deleteBackward(_:)) && selectedRange == .empty {
            onRequestDeleteEditor?()
            return
        } else if selector == #selector(NSResponder.insertNewline(_:)),
            let event = NSApp.currentEvent, event.modifierFlags.contains(.shift) {

            super.doCommand(by: #selector(NSResponder.insertNewlineIgnoringFieldEditor))
            return
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
            switch menuItem.tag {
            case 1:
                let enabled = (typingAttributes[.italic] as? Bool) ?? false
                typingAttributes[.italic] = !enabled
            case 2:
                let enabled = (typingAttributes[.bold] as? Bool) ?? false
                typingAttributes[.bold] = !enabled
            default:
                break
            }

            let traits: [InlineTextTrait] = .init(attributes: typingAttributes)
            let updatedAttributes = SizeLevel.attributesForSizeAndTraits(sizeLevel, traits)

            typingAttributes[.font] = updatedAttributes[.font]
        }
    }

    // MARK: Layout

    override public var intrinsicContentSize: NSSize {
        let size = lineRects.union.size

        return .init(width: size.width, height: ceil(size.height))
    }

    func textDidChange(_ notification: Notification) {
        onRequestInvalidateIntrinsicContentSize?()
    }

    public override func layout() {
        super.layout()

        // Workaround to fix extra blank line on first render
        onRequestInvalidateIntrinsicContentSize?()
    }

    public func setSelectedRangesWithoutNotification(_ ranges: [NSValue]) {
        super.setSelectedRanges(ranges, affinity: .downstream, stillSelecting: true)
    }

    public override func copy(_ sender: Any?) {
        let selectedText = textValue.attributedSubstring(from: selectedRange())

        let mdxNodes = selectedText.markdownInlineBlock()
        let mdxContent = MDXPasteboardContent(nodes: mdxNodes)

        guard let data = try? JSONEncoder().encode(mdxContent) else {
            Swift.print("Failed to serialize clipboard")
            return
        }

        NSPasteboard.general.declareTypes([.string, .mdx], owner: self)
        NSPasteboard.general.setString(selectedText.string, forType: .string)
        NSPasteboard.general.setData(data, forType: .mdx)
    }

    public override func pasteAsPlainText(_ sender: Any?) {
        if NSPasteboard.general.availableType(from: [.blocks]) == .blocks {
            onPasteBlocks?()
            return
        } else if let mdxData = NSPasteboard.general.data(forType: .mdx) {
            if let mdxContent = try? JSONDecoder().decode(MDXPasteboardContent.self, from: mdxData) {
                let pastedValue = mdxContent.nodes.map { $0.attributedString(for: sizeLevel) }.joined()

                let range = selectedRange()

                let prefix = textValue.attributedSubstring(from: .init(location: 0, length: range.location))
                let suffix = textValue.attributedSubstring(from: .init(location: range.upperBound, length: textValue.length - range.upperBound))
                let result = [prefix, pastedValue, suffix].joined()

                onChangeTextValue?(result)
                setSelectedRange(.init(location: prefix.length + pastedValue.length, length: 0))
            }
        } else {
            super.pasteAsPlainText(sender)
        }
    }

    private struct MDXPasteboardContent: Codable {
        var nodes: [MDXInlineNode]
    }

    public override func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        if item.action == #selector(NSTextView.pasteAsPlainText) && NSPasteboard.general.availableType(from: [.blocks]) == .blocks {
            return true
        }

        return super.validateUserInterfaceItem(item)
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

        let fontLineHeight = layoutManager.defaultLineHeight(for: sizeLevel.textStyle.nsFont)
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

