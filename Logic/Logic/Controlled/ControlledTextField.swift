//
//  ControlledTextField.swift
//  ControlledComponents
//
//  Created by Devin Abbott on 8/27/18.
//  Copyright © 2018 BitDisco, Inc. All rights reserved.
//

import AppKit
import Foundation

// MARK: - ControlledTextField

open class ControlledTextField: NSTextField, NSControlTextEditingDelegate {

    private struct InternalState {
        var textValue: NSAttributedString
        var selectedRange: NSRange
    }

    // MARK: Lifecycle

    public convenience init() {
        self.init(frame: .zero)
    }

    override public init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: Public

    public var onChangeTextValue: ((NSAttributedString) -> Void)?
    public var onChangeSelectedRange: ((NSRange) -> Void)?
    public var onSubmit: (() -> Void)?
    public var onPressEscape: (() -> Void)?

    public var textValue: NSAttributedString = .init() {
        didSet {
            textDidChangeInCallback = true

            previousState.textValue = textValue
            if currentState.textValue != textValue {
                currentState.textValue = textValue
            }
        }
    }

    public var handlesSubmit: Bool = true
    public var handlesEscape: Bool = true

    // MARK: Private

    private var textDidChangeInCallback = false

    private var currentState: InternalState {
        get {
            return InternalState(textValue: attributedStringValue, selectedRange: selectedRange)
        }
        set {
            selectedRange = newValue.selectedRange
            attributedStringValue = newValue.textValue
        }
    }

    // The text and selection values prior to a change
    private var previousState = InternalState(textValue: .init(), selectedRange: NSRange(location: 0, length: 0))

    public var selectedRange: NSRange {
        get { return currentEditor()?.selectedRange ?? NSRange(location: 0, length: 0) }
        set { currentEditor()?.selectedRange = newValue }
    }

    private func setUpSelectionObserver(for editor: NSText) {
        NotificationCenter.default.addObserver(
            forName: NSTextView.didChangeSelectionNotification,
            object: editor,
            queue: nil,
            using: { notification in
                guard let object = notification.object,
                    (object as? NSTextView) === self.currentEditor(),
                    self.attributedStringValue == self.previousState.textValue
                    else { return }
                if self.previousState.selectedRange != self.currentState.selectedRange {
                    self.previousState.selectedRange = self.currentState.selectedRange

                    if let currentEditor = self.currentEditor() {
                        self.onChangeSelectedRange?(currentEditor.selectedRange)
                    }
                }
        })
    }

    open override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()

        if result {
            if let editor = currentEditor() {
                setUpSelectionObserver(for: editor)
            }
        }

        return result
    }
}

// MARK: - NSTextFieldDelegate

extension ControlledTextField: NSTextFieldDelegate {
    
    override open func textDidChange(_ notification: Notification) {

        // Take a snapshot, since we want to make sure these values don't change by the time we re-assign them back
        let snapshotState = previousState

        textDidChangeInCallback = false

        onChangeTextValue?(attributedStringValue)

        if textDidChangeInCallback {
            if previousState.selectedRange != currentState.selectedRange {
                onChangeSelectedRange?(selectedRange)
            }
        } else {

            // Undo the user's changes
            previousState = snapshotState
            currentState = snapshotState
        }

        textDidChangeInCallback = false
    }

    open func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if handlesSubmit && commandSelector == #selector(NSResponder.insertNewline(_:)) {
            onSubmit?()
            return true
        } else if handlesEscape && commandSelector == #selector(NSResponder.cancelOperation(_:)) {
            onPressEscape?()
            return true
        }

        return false
    }
}
