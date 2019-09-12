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

            if range.length > 0, let editor = self.currentEditor() as? NSTextView {
                let rect = editor.firstRect(forCharacterRange: range, actualRange: nil)

                var traits: [InlineTextTrait] = .init(attributes: self.attributedStringValue.fontAttributes(in: range))
                self.updateSharedToolbarWindow(traits: traits)

                InlineToolbarWindow.shared.anchorTo(rect: rect, verticalOffset: 4)
                self.window?.addChildWindow(InlineToolbarWindow.shared, ordered: .above)

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
            } else {
                InlineToolbarWindow.shared.orderOut(nil)
            }
        }


    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
