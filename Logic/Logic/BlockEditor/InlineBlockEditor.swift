//
//  InlineBlockEditor.swift
//  Logic
//
//  Created by Devin Abbott on 9/10/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

private var defaultTextStyle = TextStyle(size: 18, lineHeight: 22)

public class InlineBlockEditor: AttributedTextView {

//    public override func hitTest(_ point: NSPoint) -> NSView? {
//        return nil
//    }

    // MARK: Lifecycle

    public override func sharedInit() {
        super.sharedInit()

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

        onPressEscape = { [unowned self] in
            if self.commandPaletteIndex != nil {
                self.commandPaletteIndex = nil

                self.onHideCommandPalette?()
            } else {
                self.window?.makeFirstResponder(nil)

//                self.placeholderString = " "
            }
        }

        onChangeSelectedRange = { [weak self] range in
            guard let self = self else { return }

            if range.length > 0 {
                self.updateToolbar(for: range)
                self.showToolbar(for: range)
            } else {
                InlineToolbarWindow.shared.orderOut(nil)
            }
        }
    }

    // MARK: Public

    public var onFocus: (() -> Void)?

    public var onRequestCreateEditor: ((NSAttributedString) -> Void)?

    public var onRequestDeleteEditor: (() -> Void)?

    public var onSearchCommandPalette: ((String, NSRect) -> Void)?

    public var onHideCommandPalette: (() -> Void)?

    public func resetCommandPaletteIndex() {
        commandPaletteIndex = nil
    }

    open override func handleChangeTextValue(_ value: NSAttributedString) {
        super.handleChangeTextValue(value)

        let range = self.selectedRange
        let string = value.string
        let location = range.location
        let prefix = string.prefix(location)

        let rect = firstRect(forCharacterRange: range, actualRange: nil)

        if prefix.last == "/" {
            self.commandPaletteIndex = location
            self.onSearchCommandPalette?("", rect)
        } else if let index = self.commandPaletteIndex, location > index {
            let query = (string as NSString).substring(with: NSRange(location: index, length: location - index))
            self.onSearchCommandPalette?(query, rect)
        } else {
            self.commandPaletteIndex = nil
            self.onHideCommandPalette?()
        }
    }

    // MARK: Private

    private var commandPaletteIndex: Int?

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
//            Swift.print("Resign")
//
//            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.05) { [weak self] in
//                guard let self = self, self.window?.firstResponder != self else { return }
//
//                Swift.print("Ps")
//
//                self.placeholderString = " "
//                self.needsDisplay = true
//            }
        }

        return result
    }

    public override func doCommand(by selector: Selector) {
        if selector == #selector(NSResponder.deleteBackward(_:)) && selectedRange.location == 0 {
            onRequestDeleteEditor?()
            return
        } else if selector == #selector(NSResponder.insertNewline(_:)) {
            let selectedRange = self.selectedRange
            let remainingRange = NSRange(location: selectedRange.upperBound, length: textValue.length - selectedRange.upperBound)
            let suffix = textValue.attributedSubstring(from: remainingRange)
            let prefix = textValue.attributedSubstring(from: NSRange(location: 0, length: selectedRange.upperBound))

            onRequestCreateEditor?(suffix)
            onChangeTextValue?(prefix)

            Swift.print("remainder", suffix.string)

            return
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
        get {
            let intrinsicSize = super.intrinsicContentSize

            var size: NSSize

            if textValue.length > 0 {
                size = textValue.measure(width: bounds.width)
            } else {
                size = NSAttributedString(string: " ", attributes: [.font: defaultTextStyle.nsFont]).measure(width: bounds.width)
//                size = defaultTextStyle.apply(to: placeholderString ?? " ").measure(width: bounds.width)
            }

            return .init(width: intrinsicSize.width, height: size.height)
        }
    }

//    public override func setSelectedRanges(
//        _ ranges: [NSValue],
//        affinity: NSSelectionAffinity,
//        stillSelecting stillSelectingFlag: Bool) {
//
//        layoutManager?.removeTemporaryAttribute(.backgroundColor, forCharacterRange: NSRange(location: 0, length: string.count))
//
//        for value in ranges {
//            let range = value.rangeValue
//            layoutManager?.addTemporaryAttribute(.backgroundColor, value: NSColor.selectedTextBackgroundColor, forCharacterRange: range)
//        }
//    }
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


protocol FieldEditable {
    var isFieldEditorFirstResponder: Bool { get }
}

extension InlineBlockEditor: FieldEditable {
    var isFieldEditorFirstResponder: Bool {
//        guard let window = window, let currentEditor = currentEditor() else { return false }

        return window?.firstResponder == self
    }
}
