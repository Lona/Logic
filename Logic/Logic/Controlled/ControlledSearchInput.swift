//
//  ControlledSearchInput.swift
//  ControlledComponents
//
//  Created by Devin Abbott on 8/27/18.
//  Copyright © 2018 BitDisco, Inc. All rights reserved.
//

import AppKit
import Foundation

// MARK: - ControlledSearchInput

open class ControlledSearchInput: NSTextField, NSControlTextEditingDelegate {

    private struct InternalState {
        var textValue: String
        var selectedRange: NSRange
    }

    // MARK: Lifecycle

    public convenience init() {
        self.init(frame: .zero)
    }

    override public init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        setUpSelectionObserver()
        self.delegate = self
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)

        setUpSelectionObserver()
        self.delegate = self
    }

    // MARK: Public

    public var onChangeTextValue: ((String) -> Void)?
    public var onSubmit: (() -> Void)?
    public var onPressEscape: (() -> Void)?
    public var onPressUpKey: (() -> Void)?
    public var onPressDownKey: (() -> Void)?
    public var onPressTab: (() -> Void)?
    public var onPressShiftTab: (() -> Void)?
    public var onPressCommandUpKey: (() -> Void)?
    public var onPressCommandDownKey: (() -> Void)?

    public var placeholderText: String? {
        get { return placeholderString }
        set { placeholderString = newValue }
    }

    public var textValue: String = "" {
        didSet {
            textDidChangeInCallback = true
            previousState.textValue = textValue

            if oldValue == textValue { return }

            stringValue = textValue
        }
    }

    // MARK: Private

    private var textDidChangeInCallback = false

    private var currentState: InternalState {
        get {
            return InternalState(textValue: stringValue, selectedRange: selectedRange)
        }
        set {
            selectedRange = newValue.selectedRange
            stringValue = newValue.textValue
        }
    }

    // The text and selection values prior to a change
    private var previousState = InternalState(textValue: "", selectedRange: NSRange(location: 0, length: 0))

    private var selectedRange: NSRange {
        get { return currentEditor()?.selectedRange ?? NSRange(location: 0, length: 0) }
        set { currentEditor()?.selectedRange = newValue }
    }

    private func setUpSelectionObserver() {
        NotificationCenter.default.addObserver(
            forName: NSTextView.didChangeSelectionNotification,
            object: self,
            queue: nil,
            using: { notification in
                guard let object = notification.object,
                    (object as? NSTextView) === self.currentEditor(),
                    self.stringValue == self.previousState.textValue
                    else { return }
                self.previousState.selectedRange = self.currentState.selectedRange
        })
    }
}

// MARK: - NSTextFieldDelegate

extension ControlledSearchInput: NSTextFieldDelegate {
    override open func textDidChange(_ notification: Notification) {

        // Take a snapshot, since we want to make sure these values don't change by the time we re-assign them back
        let snapshotState = previousState

        textDidChangeInCallback = false

        onChangeTextValue?(stringValue)

        if !textDidChangeInCallback {

            // Undo the user's changes
            previousState = snapshotState
            currentState = snapshotState
        }

        textDidChangeInCallback = false
    }

    public func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if (commandSelector == #selector(NSResponder.moveToBeginningOfDocument(_:))) {
            onPressCommandUpKey?()
            return true
        } else if (commandSelector == #selector(NSResponder.moveToEndOfDocument(_:))) {
            onPressCommandDownKey?()
            return true
        } else if (commandSelector == #selector(NSResponder.insertTab(_:))) {
            onPressTab?()
            return true
        } else if (commandSelector == #selector(NSResponder.insertBacktab(_:))) {
            onPressShiftTab?()
            return true
        } else if (commandSelector == #selector(NSResponder.insertNewline(_:))) {
            onSubmit?()
            return true
        } else if (commandSelector == #selector(NSResponder.cancelOperation(_:))) {
            onPressEscape?()
            return true
        } else if let onPressUpKey = onPressUpKey, commandSelector == #selector(moveUp(_:)) {
            onPressUpKey()
            return true
        } else if let onPressDownKey = onPressDownKey, commandSelector == #selector(moveDown(_:)) {
            onPressDownKey()
            return true
        }

        return false
    }
}
