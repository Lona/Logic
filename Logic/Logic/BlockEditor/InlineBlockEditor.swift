//
//  InlineBlockEditor.swift
//  Logic
//
//  Created by Devin Abbott on 9/10/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

public class InlineBlockEditor: ControlledTextField {
    private func updateSharedToolbarWindow(traits: [InlineTextTrait]) {
        InlineToolbarWindow.shared.isBoldEnabled = traits.contains(.bold)
        InlineToolbarWindow.shared.isItalicEnabled = traits.contains(.italic)
        InlineToolbarWindow.shared.isCodeEnabled = traits.contains(.code)
    }

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

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        allowsEditingTextAttributes = true

        delegate = self

        isBordered = false

        font = TextStyle(size: 18).nsFont

        onChangeTextValue = { value in
            self.textValue = value

//            Swift.print("MD:", self.attributedStringValue.markdownString())
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

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateToolbar(for range: NSRange) {
        var traits: [InlineTextTrait] = .init(attributes: self.attributedStringValue.fontAttributes(in: range))
        self.updateSharedToolbarWindow(traits: traits)

        InlineToolbarWindow.shared.onCommand = { [unowned self] command in
            let mutable = NSMutableAttributedString(attributedString: self.attributedStringValue)

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
                self.attributedStringValue = mutable
            case .italic:
                update(trait: .italic)
                self.attributedStringValue = mutable
            case .code:
                update(trait: .code)
                self.attributedStringValue = mutable
            default:
                break
            }

            traits = .init(attributes: self.attributedStringValue.fontAttributes(in: range))
            self.updateSharedToolbarWindow(traits: traits)
        }
    }

    private func showToolbar(for range: NSRange) {
        guard let editor = self.currentEditor() as? NSTextView else { return }

        let rect = editor.firstRect(forCharacterRange: range, actualRange: nil)

        InlineToolbarWindow.shared.anchorTo(rect: rect, verticalOffset: 4)
        self.window?.addChildWindow(InlineToolbarWindow.shared, ordered: .above)
    }
}
