//
//  SuggestionWindow.swift
//  LogicDesigner
//
//  Created by Devin Abbott on 2/17/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import AppKit

public class SuggestionWindow: NSWindow {
    convenience init() {
        self.init(
            contentRect: NSRect(x: 0, y: 0, width: 610, height: 380),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false)

        let window = self
        window.backgroundColor = NSColor.clear
        window.isOpaque = false

        let shadow = NSShadow()
        shadow.shadowBlurRadius = 4
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.4)
        shadow.shadowOffset = NSSize(width: 0, height: -2)

        let box = NSBox()
        box.boxType = .custom
        box.borderType = .noBorder
        box.contentViewMargins = .zero
        box.fillColor = .white
        box.shadow = shadow
        box.cornerRadius = 4

        let view = NSView()

        view.addSubview(box)
        box.addSubview(suggestionView)

        box.translatesAutoresizingMaskIntoConstraints = false
        box.topAnchor.constraint(equalTo: view.topAnchor, constant: 12).isActive = true
        box.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12).isActive = true
        box.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12).isActive = true
        box.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -12).isActive = true

        suggestionView.translatesAutoresizingMaskIntoConstraints = false
        suggestionView.topAnchor.constraint(equalTo: box.topAnchor).isActive = true
        suggestionView.leadingAnchor.constraint(equalTo: box.leadingAnchor).isActive = true
        suggestionView.trailingAnchor.constraint(equalTo: box.trailingAnchor).isActive = true
        suggestionView.bottomAnchor.constraint(equalTo: box.bottomAnchor).isActive = true

        self.contentBox = box

        suggestionView.searchInput.isBordered = false
        suggestionView.searchInput.focusRingType = .none
        suggestionView.searchInput.font = NSFont.systemFont(ofSize: 18, weight: .light)

        suggestionView.onSubmit = {
            if let selectedIndex = self.selectedIndex {
                self.onSubmit?(selectedIndex)
            }
        }

        suggestionView.onActivateIndex = { index in
            self.onSubmit?(index)
        }

        suggestionView.onSelectIndex = { selectedIndex in
            self.onSelectIndex?(selectedIndex)
        }

        suggestionView.onPressDownKey = {
            let selectablePairs = self.suggestionItems.enumerated().filter { $0.element.isSelectable }

            if let filteredIndex = selectablePairs.firstIndex(where: { index, item in
                return self.selectedIndex == index
            }) {
                let nextFilteredIndex = min(filteredIndex + 1, selectablePairs.count - 1)
                let nextIndex = selectablePairs[nextFilteredIndex].offset

                self.onSelectIndex?(nextIndex)
            } else if let first = selectablePairs.first {
                self.onSelectIndex?(first.offset)
            } else {
                self.onSelectIndex?(nil)
            }
        }

        suggestionView.onPressUpKey = {
            let selectablePairs = self.suggestionItems.enumerated().filter { $0.element.isSelectable }

            if let filteredIndex = selectablePairs.firstIndex(where: { index, item in
                return self.selectedIndex == index
            }) {
                let nextFilteredIndex = max(filteredIndex - 1, 0)
                let nextIndex = selectablePairs[nextFilteredIndex].offset
                self.onSelectIndex?(nextIndex)
            } else if let last = selectablePairs.last {
                self.onSelectIndex?(last.offset)
            } else {
                self.onSelectIndex?(nil)
            }
        }

        suggestionView.onCloseDropdown = {
            self.onHighlightDropdownIndex?(nil)
        }

        suggestionView.onPressCommandUpKey = {
            if self.dropdownIndex - 1 >= 0 {
                self.onSelectDropdownIndex?(self.dropdownIndex - 1)
            }
        }

        window.contentView = view
    }

    var contentBox: NSView?

    var suggestionView = SuggestionView()

    // MARK: Public

    public var onSubmit: ((Int) -> Void)?

    public var onSelectIndex: ((Int?) -> Void)?

    public var selectedIndex: Int? {
        get { return suggestionView.selectedIndex }
        set { suggestionView.selectedIndex = newValue }
    }

    public var onPressEscapeKey: (() -> Void)? {
        get { return suggestionView.onPressEscapeKey }
        set { suggestionView.onPressEscapeKey = newValue }
    }

    public var onPressTabKey: (() -> Void)? {
        get { return suggestionView.onPressTabKey }
        set { suggestionView.onPressTabKey = newValue }
    }

    public var onPressShiftTabKey: (() -> Void)? {
        get { return suggestionView.onPressShiftTabKey }
        set { suggestionView.onPressShiftTabKey = newValue }
    }

    public var suggestionItems: [SuggestionListItem] {
        get { return suggestionView.suggestionList.items }
        set { suggestionView.suggestionList.items = newValue }
    }

    public var suggestionText: String {
        get { return suggestionView.searchText }
        set { suggestionView.searchText = newValue }
    }

    public var placeholderText: String? {
        get { return suggestionView.placeholderText }
        set { suggestionView.placeholderText = newValue }
    }

    public var onChangeSuggestionText: ((String) -> Void)? {
        get { return suggestionView.onChangeSearchText }
        set { suggestionView.onChangeSearchText = newValue }
    }

    // MARK: Dropdown

    public var dropdownIndex: Int {
        get { return suggestionView.dropdownIndex }
        set { suggestionView.dropdownIndex = newValue }
    }

    public var dropdownValues: [String] {
        get { return suggestionView.dropdownValues }
        set { suggestionView.dropdownValues = newValue }
    }

    public var onSelectDropdownIndex: ((Int) -> Void)? {
        get { return suggestionView.onSelectDropdownIndex }
        set { suggestionView.onSelectDropdownIndex = newValue }
    }

    public var onHighlightDropdownIndex: ((Int?) -> Void)? {
        get { return suggestionView.onHighlightDropdownIndex }
        set { suggestionView.onHighlightDropdownIndex = newValue }
    }

    // MARK: Detail view

    public var detailView: CustomDetailView {
        get { return suggestionView.detailView }
        set { suggestionView.detailView = newValue }
    }

    // MARK: Focus

    public func focusSearchField() {
        makeKey()
        makeFirstResponder(suggestionView.searchInput)

        let selectablePairs = self.suggestionItems.enumerated().filter { $0.element.isSelectable }

        selectedIndex = selectablePairs.first?.offset
    }

    public func anchorTo(rect: NSRect) {
        let margin: CGFloat = 2.0
        let textInset: CGFloat = 12.0
        if let contentBox = contentBox {
            let origin = NSPoint(
                x: rect.minX - textInset + LogicElementEditor.textPadding.width,
                y: rect.minY - contentBox.frame.height - margin)
            setFrameOrigin(origin)
        }
    }

    // MARK: Overrides

    public override var canBecomeKey: Bool {
        return true
    }

    public override func setFrameOrigin(_ point: NSPoint) {
        super.setFrameOrigin(NSPoint(x: point.x - 12, y: point.y - 12))
    }
}
