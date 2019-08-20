//
//  ControlledDropdown.swift
//  LonaStudio
//
//  Created by Devin Abbott on 12/9/18.
//  Copyright © 2018 Devin Abbott. All rights reserved.
//

import AppKit

// MARK: - ControlledDropdown

public class ControlledDropdown: NSPopUpButton {

    // MARK: Lifecycle

    override init(frame buttonFrame: NSRect, pullsDown flag: Bool) {
        self.parameters = Parameters()

        super.init(frame: buttonFrame, pullsDown: flag)
    }

    public convenience init(_ parameters: Parameters = Parameters()) {
        self.init(frame: .zero, pullsDown: false)

        self.parameters = parameters

        setup()
        update()
    }

    public convenience init(values: [String] = [], selectedIndex: Int) {
        self.init(Parameters(values: values, selectedIndex: selectedIndex))
    }

    public required init?(coder aDecoder: NSCoder) {
        self.parameters = Parameters()

        super.init(coder: aDecoder)

        setup()
        update()
    }

    // MARK: Public

    public var parameters: Parameters {
        didSet {
            update()
        }
    }

    public var selectedIndex: Int {
        get { return parameters.selectedIndex }
        set { parameters.selectedIndex = newValue }
    }

    public var values: [String] {
        get { return parameters.values }
        set { parameters.values = newValue }
    }

    public var keyEquivalents: [String] {
        get { return parameters.keyEquivalents }
        set { parameters.keyEquivalents = newValue }
    }

    public var onChangeIndex: ((Int) -> Void)? {
        get { return parameters.onChangeIndex }
        set { parameters.onChangeIndex = newValue }
    }

    public var onHighlightIndex: ((Int?) -> Void)? {
        get { return parameters.onHighlightIndex }
        set { parameters.onHighlightIndex = newValue }
    }

    public var onCloseMenu: (() -> Void)? {
        get { return parameters.onCloseMenu }
        set { parameters.onCloseMenu = newValue }
    }

    public var onOpenMenu: (() -> Void)? {
        get { return parameters.onOpenMenu }
        set { parameters.onOpenMenu = newValue }
    }

    // MARK: Private

    /// Extract modifier keys from a keyEquivalent, so that we can encode the shortcut as a string
    private func process(keyEquivalent: String) -> (String, NSEvent.ModifierFlags) {
        if keyEquivalent.contains("⌘") {
            let keys = keyEquivalent.replacingOccurrences(of: "⌘", with: "")
            return (keys, .command)
        } else {
            return (keyEquivalent, [])
        }
    }

    private func update() {
        if itemTitles != parameters.values {
            removeAllItems()

            // Add items without going through NSPopUpButton methods, since those filter duplicates.
            parameters.values.enumerated().forEach { index, value in
                let rawKeyEquivalent = keyEquivalents.count > index ? keyEquivalents[index] : ""
                let (keyEquivalent, modifierMask) = process(keyEquivalent: rawKeyEquivalent)
                let item = NSMenuItem(title: value, action: nil, keyEquivalent: keyEquivalent)
                item.keyEquivalentModifierMask = modifierMask
                menu?.addItem(item)
            }
        }

        if parameters.selectedIndex != indexOfSelectedItem &&
            parameters.selectedIndex < parameters.values.count {
            selectItem(at: parameters.selectedIndex)
        }
    }

    private func setup() {
        action = #selector(handleChange)
        target = self

        menu?.delegate = self

        isBordered = false
        heightAnchor.constraint(equalToConstant: 22).isActive = true
    }

    @objc func handleChange() {
        let newValue = indexOfSelectedItem

        // Don't allow changing to the same value
        if newValue == parameters.selectedIndex { return }

        // Revert the value to before it was toggled
        selectItem(at: parameters.selectedIndex)

        // This view's owner should update the index if needed
        parameters.onChangeIndex?(newValue)
    }
}

// MARK: - Parameters

extension ControlledDropdown {
    public struct Parameters: Equatable {
        public var values: [String]
        public var keyEquivalents: [String]
        public var selectedIndex: Int
        public var onChangeIndex: ((Int) -> Void)?
        public var onHighlightIndex: ((Int?) -> Void)?
        public var onCloseMenu: (() -> Void)?
        public var onOpenMenu: (() -> Void)?

        public init(
            values: [String] = [],
            keyEquivalents: [String] = [],
            selectedIndex: Int = -1,
            onChangeIndex: ((Int) -> Void)? = nil,
            onHighlightIndex: ((Int?) -> Void)? = nil,
            onCloseMenu: (() -> Void)? = nil,
            onOpenMenu: (() -> Void)? = nil
            ) {
            self.values = values
            self.keyEquivalents = keyEquivalents
            self.selectedIndex = selectedIndex
            self.onChangeIndex = onChangeIndex
            self.onHighlightIndex = onHighlightIndex
            self.onCloseMenu = onCloseMenu
            self.onOpenMenu = onOpenMenu
        }

        public static func == (lhs: ControlledDropdown.Parameters, rhs: ControlledDropdown.Parameters) -> Bool {
            return lhs.values == rhs.values && lhs.selectedIndex == rhs.selectedIndex
        }
    }
}

// MARK: - NSMenuDelegate

extension ControlledDropdown: NSMenuDelegate {
    public func menuWillOpen(_ menu: NSMenu) {
        self.onOpenMenu?()
    }

    public func menuDidClose(_ menu: NSMenu) {
        self.onCloseMenu?()
    }

    public func menu(_ menu: NSMenu, willHighlight item: NSMenuItem?) {
        if let item = item {
            self.onHighlightIndex?(menu.index(of: item))
        } else {
            self.onHighlightIndex?(nil)
        }
    }
}
