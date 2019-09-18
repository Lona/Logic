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
            contentRect: NSRect(origin: .zero, size: .zero),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false)

        let window = self
        window.backgroundColor = NSColor.clear
        window.isOpaque = false

        shadowView.boxType = .custom
        shadowView.borderType = .noBorder
        shadowView.contentViewMargins = .zero
        shadowView.fillColor = Colors.suggestionWindowBackground
        shadowView.shadow = OverlayWindow.shadow
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

        suggestionView.showsSeachBar = true
        suggestionView.suggestionListWidth = 200
        suggestionView.showsSuggestionDetails = true
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

        suggestionView.onPressFilterRecommended = {
            self.onChangeSuggestionFilter?(.recommended)
        }

        suggestionView.onPressFilterAll = {
            self.onChangeSuggestionFilter?(.all)
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

    public var defaultWindowSize = CGSize(width: 610, height: 380)

    public var allowedShrinkingSize = CGSize(width: 180, height: 200)

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

    public var showsSearchBar: Bool {
        get { return suggestionView.showsSeachBar }
        set { suggestionView.showsSeachBar = newValue }
    }

    public var showsSuggestionDetails: Bool {
        get { return suggestionView.showsSuggestionDetails }
        set { suggestionView.showsSuggestionDetails = newValue }
    }

    // MARK: Filter bar

    public var suggestionFilter: SuggestionView.SuggestionFilter {
        get { return suggestionView.suggestionFilter }
        set { suggestionView.suggestionFilter = newValue }
    }

    public var onChangeSuggestionFilter: ((SuggestionView.SuggestionFilter) -> Void)?

    public var showsFilterBar: Bool {
        get { return suggestionView.showsFilterBar }
        set { suggestionView.showsFilterBar = newValue }
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
        set {
            var keyEquivalents = Array<String>(repeating: "", count: newValue.count)
            if newValue.count >= 2 {
                keyEquivalents[newValue.count - 2] = "⌘"
            }
            suggestionView.dropdownKeyEquivalents = keyEquivalents
            suggestionView.dropdownValues = newValue
        }
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

    public override var acceptsFirstResponder: Bool {
        return showsSearchBar
    }

    public func focusSearchField() {
        makeKey()
        makeFirstResponder(suggestionView.searchInput)

        let selectablePairs = self.suggestionItems.enumerated().filter { $0.element.isSelectable }

        selectedIndex = selectablePairs.first?.offset
    }

    public func anchorTo(rect: NSRect, verticalOffset: CGFloat = 0) {
        var contentRect = NSRect(
            origin: NSPoint(x: rect.minX, y: rect.minY - defaultContentViewSize.height - verticalOffset),
            size: defaultWindowSize)

        if let visibleFrame = NSScreen.main?.visibleFrame {
            if contentRect.maxX > visibleFrame.maxX {
                let horizontalShrinkSize = min(
                    contentRect.maxX - visibleFrame.maxX, allowedShrinkingSize.width)

                contentRect.size.width = contentRect.width - horizontalShrinkSize + 16
                contentRect.origin.x = min(contentRect.minX, visibleFrame.maxX - contentRect.width + 16)
            }

            if contentRect.minY < visibleFrame.minY {
                let verticalShrinkSize = visibleFrame.minY - contentRect.minY
                if verticalShrinkSize < allowedShrinkingSize.height {
                    contentRect.size.height = contentRect.height - verticalShrinkSize
                    contentRect.origin.y += verticalShrinkSize
                } else {
                    contentRect.origin.y = rect.maxY + verticalOffset
                }
            }
        }

        if !showsSuggestionDetails {
            suggestionView.suggestionListWidth = defaultContentViewSize.width
        }

        setContentSize(contentRect.size)
        setFrameOrigin(contentRect.origin)
    }

    public func anchorHorizontallyTo(rect: NSRect, horizontalOffset: CGFloat = 0) {
        var contentRect = NSRect(
            origin: NSPoint(
                x: rect.minX - defaultContentViewSize.width - horizontalOffset,
                y: rect.midY - defaultContentViewSize.height / 2
            ),
            size: defaultWindowSize)

        if let visibleFrame = NSScreen.main?.visibleFrame {
            if contentRect.minX < visibleFrame.minX {
                contentRect.origin.x = visibleFrame.minX
            }

            if contentRect.minY < visibleFrame.minY {
                let verticalShrinkSize = visibleFrame.minY - contentRect.minY
                if verticalShrinkSize < allowedShrinkingSize.height {
                    contentRect.size.height = contentRect.height - verticalShrinkSize
                    contentRect.origin.y += verticalShrinkSize
                } else {
                    contentRect.origin.y = rect.maxY + horizontalOffset
                }
            }
        }

        if !showsSuggestionDetails {
            suggestionView.suggestionListWidth = defaultContentViewSize.width
        }

        setContentSize(contentRect.size)
        setFrameOrigin(contentRect.origin)
    }

    public var defaultContentViewSize: CGSize {
        return CGSize(
            width: defaultWindowSize.width - SuggestionWindow.shadowViewMargin * 2,
            height: defaultWindowSize.height - SuggestionWindow.shadowViewMargin * 2)
    }

    private static var shadowViewMargin: CGFloat = 12

    // MARK: Overrides

    public override var canBecomeKey: Bool {
        return showsSearchBar
    }

    // Offset the origin to account for the shadow view's margin
    public override func setFrameOrigin(_ point: NSPoint) {
        let offsetOrigin = NSPoint(x: point.x - SuggestionWindow.shadowViewMargin, y: point.y - SuggestionWindow.shadowViewMargin)
        super.setFrameOrigin(offsetOrigin)
    }
}
