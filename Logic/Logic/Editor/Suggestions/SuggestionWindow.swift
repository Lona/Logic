//
//  SuggestionWindow.swift
//  LogicDesigner
//
//  Created by Devin Abbott on 2/17/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import AppKit

public class SuggestionWindow: NSWindow {
    static var shared = SuggestionWindow()

    convenience init() {
        self.init(
            contentRect: NSRect(origin: .zero, size: SuggestionWindow.defaultWindowSize),
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

        shadowView.boxType = .custom
        shadowView.borderType = .noBorder
        shadowView.contentViewMargins = .zero
        shadowView.fillColor = Colors.suggestionWindowBackground
        shadowView.shadow = shadow
        shadowView.cornerRadius = 4

        let view = NSView()

        view.addSubview(shadowView)
        shadowView.addSubview(suggestionView)

        shadowView.translatesAutoresizingMaskIntoConstraints = false
        shadowView.topAnchor.constraint(equalTo: view.topAnchor, constant: SuggestionWindow.shadowViewMargin).isActive = true
        shadowView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: SuggestionWindow.shadowViewMargin).isActive = true
        shadowView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -SuggestionWindow.shadowViewMargin).isActive = true
        shadowView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -SuggestionWindow.shadowViewMargin).isActive = true

        suggestionView.translatesAutoresizingMaskIntoConstraints = false
        suggestionView.topAnchor.constraint(equalTo: shadowView.topAnchor).isActive = true
        suggestionView.leadingAnchor.constraint(equalTo: shadowView.leadingAnchor).isActive = true
        suggestionView.trailingAnchor.constraint(equalTo: shadowView.trailingAnchor).isActive = true
        suggestionView.bottomAnchor.constraint(equalTo: shadowView.bottomAnchor).isActive = true

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

        let notificationTokens = [
            NotificationCenter.default.addObserver(
                forName: NSWindow.didResignKeyNotification,
                object: self,
                queue: nil,
                using: { [weak self] notification in self?.handleHide() }
            ),
            NotificationCenter.default.addObserver(
                forName: NSWindow.didResignMainNotification,
                object: self,
                queue: nil,
                using: { [weak self] notification in self?.handleHide() }
            )
        ]

        subscriptions.append({
            notificationTokens.forEach {
                NotificationCenter.default.removeObserver($0)
            }
        })
    }

    deinit {
        subscriptions.forEach { subscription in subscription() }
    }

    private var subscriptions: [() -> Void] = []

    var shadowView = NSBox()

    var suggestionView = SuggestionView()

    private func handleHide() {
        self.onRequestHide?()
    }

    // MARK: Public

    public var onRequestHide: (() -> Void)?

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

    public var showsDropdown: Bool {
        get { return suggestionView.showsDropdown }
        set { suggestionView.showsDropdown = newValue }
    }

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

    public func anchorTo(rect: NSRect, verticalOffset: CGFloat = 0) {
        var contentRect = NSRect(
            origin: NSPoint(x: rect.minX, y: rect.minY - SuggestionWindow.defaultContentViewSize.height - verticalOffset),
            size: SuggestionWindow.defaultWindowSize)

        if let visibleFrame = NSScreen.main?.visibleFrame {
            if contentRect.maxX > visibleFrame.maxX {
                let horizontalShrinkSize = min(
                    contentRect.maxX - visibleFrame.maxX, SuggestionWindow.allowedShrinkingSize.width)

                contentRect.size.width = contentRect.width - horizontalShrinkSize + 16
                contentRect.origin.x = min(contentRect.minX, visibleFrame.maxX - contentRect.width + 16)
            }

            if contentRect.minY < visibleFrame.minY {
                let verticalShrinkSize = visibleFrame.minY - contentRect.minY
                if verticalShrinkSize < SuggestionWindow.allowedShrinkingSize.height {
                    contentRect.size.height = contentRect.height - verticalShrinkSize
                    contentRect.origin.y += verticalShrinkSize
                } else {
                    contentRect.origin.y = rect.maxY + verticalOffset
                }
            }
        }

        setContentSize(contentRect.size)
        setFrameOrigin(contentRect.origin)
    }

    public static var defaultWindowSize = CGSize(width: 610, height: 380)

    public static var allowedShrinkingSize = CGSize(width: 180, height: 200)

    public static var defaultContentViewSize: CGSize {
        return CGSize(
            width: defaultWindowSize.width - shadowViewMargin * 2,
            height: defaultWindowSize.height - shadowViewMargin * 2)
    }

    private static var shadowViewMargin: CGFloat = 12

    // MARK: Overrides

    public override var canBecomeKey: Bool {
        return true
    }

    // Offset the origin to account for the shadow view's margin
    public override func setFrameOrigin(_ point: NSPoint) {
        let offsetOrigin = NSPoint(x: point.x - SuggestionWindow.shadowViewMargin, y: point.y - SuggestionWindow.shadowViewMargin)
        super.setFrameOrigin(offsetOrigin)
    }
}
