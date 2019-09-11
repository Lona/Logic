//
//  InlineBlockEditor.swift
//  Logic
//
//  Created by Devin Abbott on 9/10/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

public class InlineBlockEditor: ControlledTextField {
    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        allowsEditingTextAttributes = true

        delegate = self

        isBordered = false

        font = TextStyle(size: 18).nsFont

        onChangeTextValue = { value in
            self.textValue = value
        }

        onChangeSelectedRange = { range in
            Swift.print(range)

            if range.length > 0, let editor = self.currentEditor() as? NSTextView {
                let rect = editor.firstRect(forCharacterRange: range, actualRange: nil)
                Swift.print(rect)

                InlineToolbarWindow.shared.anchorTo(rect: rect, verticalOffset: 4)
                InlineToolbarWindow.shared.orderFront(nil)
            } else {
                InlineToolbarWindow.shared.orderOut(nil)
            }
        }
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var model: [LightMark.InlineElement] = []

    var attributedString: NSAttributedString {
        return model.map { $0.attributedString() }.joined(separator: "")
    }
}
