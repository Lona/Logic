//
//  TextView.swift
//  ControlledComponents
//
//  Created by Devin Abbott on 9/14/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import AppKit

// MARK: - AttributedTextInput

open class AttributedTextView: NSTextView {

    fileprivate struct InternalState {
        var textValue: NSAttributedString
        var selectedRange: NSRange
    }

    // MARK: Lifecycle

    public convenience init() {
        self.init(frame: .zero)
    }

    public override init(frame frameRect: NSRect, textContainer container: NSTextContainer?) {
        super.init(frame: frameRect, textContainer: container)
        sharedInit()
    }

    override public init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        sharedInit()
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        sharedInit()
    }

    open func sharedInit() {
        delegate = self
        setUpSelectionObserver()
    }

    // MARK: Public

    public var onDidChangeText: (() -> Void)?
    public var onChangeSelectedRange: ((NSRange) -> Void)?
    public var onChangeTextValue: ((NSAttributedString) -> Void)?
    public var onSubmit: (() -> Void)?
    public var onPressEscape: (() -> Void)?

    private var currentlyChangingText = false

    private var _textValue: NSAttributedString = .init() {
        didSet {
            if currentlyHandlingTextChange {
                pendingTextChange = textValue
                return
            }

            if attributedString() != textValue {
                let previousSelection = selectedRanges
                let sameString = attributedString().string == textValue.string

                currentlyChangingText = true

                textStorage?.setAttributedString(textValue)

                if sameString {
                    setSelectedRanges(previousSelection, affinity: .downstream, stillSelecting: false)
                }

                currentlyChangingText = false
            }
        }
    }

    public var textValue: NSAttributedString {
        get { return _textValue }
        set {
            _textValue = prepareTextValue(newValue)
        }
    }

    open func handleChangeTextValue(_ value: NSAttributedString) {
        onChangeTextValue?(value)
    }

    open func prepareTextValue(_ value: NSAttributedString) -> NSAttributedString {
        return value
    }

    // MARK: Private

    private var currentlyHandlingTextChange = false

    private var pendingTextChange: NSAttributedString? = nil

    private func setUpSelectionObserver() {
        NotificationCenter.default.addObserver(
            forName: NSTextView.didChangeSelectionNotification,
            object: self,
            queue: nil,
            using: ({ [weak self] notification in
                guard let self = self,
                    let object = notification.object as? NSTextView,
                    object === self else { return }

                if !self.currentlyChangingText {
                    self.onChangeSelectedRange?(self.selectedRange())
                }
            })
        )
    }
}

// MARK: - NSTextViewDelegate

extension AttributedTextView: NSTextViewDelegate {
    open override func shouldChangeText(in affectedCharRange: NSRange, replacementString: String?) -> Bool {
        let newValue = NSMutableAttributedString(attributedString: attributedString())
        if let replacementString = replacementString {
            newValue.replaceCharacters(in: affectedCharRange, with: replacementString)
        }

        pendingTextChange = nil

        currentlyHandlingTextChange = true

        handleChangeTextValue(newValue)

        currentlyHandlingTextChange = false

        if let pendingValue = pendingTextChange {
            if newValue.string == pendingValue.string {
                return true
            } else {
                textValue = pendingValue
            }
        }

        return false
    }

    open override func didChangeText() {
        super.didChangeText()

        onDidChangeText?()
    }

    open override func doCommand(by selector: Selector) {
        if selector == #selector(NSResponder.insertNewline(_:)) {
            onSubmit?()
            return
        } else if selector == #selector(NSResponder.cancelOperation(_:)) {
            onPressEscape?()
            return
        }

        return super.doCommand(by: selector)
    }
}
