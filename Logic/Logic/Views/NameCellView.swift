//
//  NameCellView.swift
//  Logic
//
//  Created by Devin Abbott on 9/24/18.
//  Copyright © 2018 BitDisco, Inc. All rights reserved.
//

import AppKit
import Foundation

class NameCellView: NSTableCellView, Selectable, Hoverable {

    // MARK: Lifecycle

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        setUpViews()
        setUpConstraints()

        update()
    }

    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public

    var onPressPlus: (() -> Void)? { didSet { update() } }

    var onPressMinus: (() -> Void)? { didSet { update() } }

    var onChangeText: ((String) -> Void)? { didSet { update() } }

    var isHovered: Bool = false { didSet { update() } }

    var isSelected: Bool = false { didSet { update() } }

    var textColor: NSColor? { didSet { update() } }

    var textValue: String? { didSet { update() } }

    var placeholderTextValue: String? { didSet { update() } }

    override var textField: NSTextField? {
        get { return _textField }
        set { _textField = newValue ?? _textField }
    }

    // MARK: Private

    private var _textField = NSTextField(labelWithString: "Testing")

    private var plusButton = NSButton(
        image: NSImage(named: NSImage.addTemplateName)!,
        target: nil,
        action: nil)

    private var minusButton = NSButton(
        image: NSImage(named: NSImage.removeTemplateName)!,
        target: nil,
        action: nil)

    @objc func handlePressPlus(_ sender: AnyObject) {
        onPressPlus?()
    }

    @objc func handlePressMinus(_ sender: AnyObject) {
        onPressMinus?()
    }

    func setUpViews() {
        _textField.isEditable = true
        _textField.isEnabled = true
        _textField.delegate = self
        _textField.isBordered = false

        plusButton.target = self
        plusButton.bezelStyle = .inline
        plusButton.action = #selector(handlePressPlus(_:))
        plusButton.image?.size = NSSize(width: 9, height: 9)

        minusButton.target = self
        minusButton.bezelStyle = .inline
        minusButton.action = #selector(handlePressMinus(_:))
        minusButton.image?.size = NSSize(width: 9, height: 9)

        addSubview(_textField)
        addSubview(plusButton)
        addSubview(minusButton)
    }

    func setUpConstraints() {
        translatesAutoresizingMaskIntoConstraints = false
        _textField.translatesAutoresizingMaskIntoConstraints = false
        plusButton.translatesAutoresizingMaskIntoConstraints = false
        minusButton.translatesAutoresizingMaskIntoConstraints = false

        _textField.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        _textField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4).isActive = true
        _textField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -40).isActive = true

        plusButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        plusButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -21).isActive = true
        plusButton.heightAnchor.constraint(equalToConstant: 15).isActive = true
        plusButton.widthAnchor.constraint(equalToConstant: 15).isActive = true

        minusButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        minusButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -2).isActive = true
        minusButton.heightAnchor.constraint(equalToConstant: 15).isActive = true
        minusButton.widthAnchor.constraint(equalToConstant: 15).isActive = true
    }

    func update() {
        let isEditable = onChangeText != nil

        _textField.textColor = isSelected
            ? NSColor.selectedControlTextColor
            : isEditable
            ? (textColor ?? NSColor.controlTextColor)
            : NSColor.disabledControlTextColor
        plusButton.isHidden = !isHovered || onPressPlus == nil
        minusButton.isHidden = !isHovered || onPressMinus == nil
        _textField.isEditable = isEditable
        _textField.isEnabled = isEditable
        _textField.stringValue = textValue ?? ""
        _textField.placeholderString = placeholderTextValue
    }
}

extension NameCellView: NSTextFieldDelegate {
    func controlTextDidEndEditing(_ sender: Notification) {
        onChangeText?(_textField.stringValue)
    }
}
