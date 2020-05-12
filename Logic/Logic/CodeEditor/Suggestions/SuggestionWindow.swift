//
//  SuggestionWindow.swift
//  LogicDesigner
//
//  Created by Devin Abbott on 2/17/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import AppKit

public class SuggestionWindow: NSWindow {

    public struct Style: Equatable {
        var showsSearchBar: Bool = true
        var showsFilterBar: Bool = false
        var showsSuggestionArea: Bool = true
        var showsSuggestionList = true
        var showsSuggestionDetails = true
        var suggestionListWidth: CGFloat = 200
        var defaultContentWidth: CGFloat = 586

        public static var `default` = Style()

        public static var textInput: Style = {
            var style = Style()
            style.showsSearchBar = true
            style.showsFilterBar = false
            style.showsSuggestionArea = false
            style.defaultContentWidth = 376
            return style
        }()

        public static var detail: Style = {
            var style = Style()
            style.showsSearchBar = true
            style.showsFilterBar = false
            style.showsSuggestionArea = true
            style.showsSuggestionList = false
            style.showsSuggestionDetails = true
            style.defaultContentWidth = 376
            return style
        }()

        public static var contextMenu: Style = {
            var style = Style()
            style.showsSearchBar = true
            style.showsFilterBar = false
            style.showsSuggestionArea = true
            style.showsSuggestionList = true
            style.showsSuggestionDetails = false
            style.defaultContentWidth = 256
            return style
        }()

        public static var contextMenuWithoutSearchBar: Style = {
            var style = Style.contextMenu
            style.showsSearchBar = false
            return style
        }()
    }

    public static var contextMenu: SuggestionWindow = {
        let window = SuggestionWindow(style: .contextMenu)
        window.showsSearchBar = false
        window.onRequestHide = {
            window.orderOut(nil)
        }
        return window
    }()

    public static var shared = SuggestionWindow()

    convenience init() {
        self.init(style: .default)
    }

    convenience init(style: Style) {
        self.init(
            contentRect: NSRect(origin: .zero, size: .zero),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false)

        self.style = style

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

        suggestionView.searchInput.isBordered = false
        suggestionView.searchInput.focusRingType = .none
        suggestionView.searchInput.font = NSFont.systemFont(ofSize: 18, weight: .light)
        suggestionView.searchInput.onPressDeleteField = { [unowned self] in
            self.onDeleteEmptyInput?()
        }
        suggestionView.onPressToken = { [unowned self] in
            self.onDeleteEmptyInput?()
        }

        suggestionView.onSubmit = {
            self.onPressEnter?()

            if let selectedIndex = self.selectedIndex {
                self.onSubmit?(selectedIndex)
            } else if self.canSubmitWithoutSelectedIndex {
                self.onSubmit?(-1)
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

        suggestionView.onPressOverflowMenu = { [unowned self] in
            let rect = self.suggestionView.overflowMenuBounds
            let windowRect = self.suggestionView.convert(rect, to: nil)
            let screenRect = self.convertToScreen(windowRect)

            self.onPressOverflowMenu?(screenRect)
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

    lazy var proxySearchField = ControlledSearchInput(frame: .zero)

    private func handleHide() {
        if parent != nil || shouldHideWithoutCheckingParentWindow {
            self.onRequestHide?()
        }
    }

    // MARK: Public

    // The easiest way to keep track of whether a window is visible is by checking
    // if it has a parent. However, sometimes we use windows without ever adding them to a
    // parent (i.e. a top-level window), so we expose this option.
    //
    // Hiding the window ourselves will still trigger the notification and `handleHide`,
    // so we could be prepared to see `onRequestHide` called multiple times.
    public var shouldHideWithoutCheckingParentWindow: Bool = false

    public var style: Style = Style() {
        didSet {
            suggestionView.showsSearchBar = style.showsSearchBar
            suggestionView.showsFilterBar = style.showsFilterBar
            suggestionView.showsSuggestionArea = style.showsSuggestionArea
            suggestionView.showsSuggestionList = style.showsSuggestionList
            suggestionView.showsSuggestionDetails = style.showsSuggestionDetails
            suggestionView.suggestionListWidth = style.suggestionListWidth

            updateProxySearchField()
        }
    }

    private var computedHeight: CGFloat {
        var height: CGFloat = 0

        if showsSearchBar {
            height += 32

            if showsSuggestionArea {
                height += 1 // Divider
            }
        }

        if showsSuggestionArea {
            if suggestionView.showsSuggestionDetails {
                height = 380
            } else if suggestionView.showsSuggestionList {
                height += min(suggestionItems.map { $0.height }.reduce(0, +), 400)
            }
        }

        if showsFilterBar {
            height += 1 // Divider
            height += 16
        }

        return height
    }

    public var defaultContentWidth: CGFloat {
        get { return style.defaultContentWidth }
        set { style.defaultContentWidth = newValue }
    }

    public var defaultContentSize: NSSize {
        get { return .init(width: style.defaultContentWidth, height: computedHeight) }
    }

    public var allowedShrinkingSize = NSSize(width: 180, height: 200)

    /**
     The entered text can be submitted without any valid suggestion selected.

     When the text input view is displayed without suggestions, there's no need to have suggestions be selected at all.
     */
    public var canSubmitWithoutSelectedIndex = false

    public var onRequestHide: (() -> Void)?

    public var onSubmit: ((Int) -> Void)?

    public var onPressEnter: (() -> Void)?

    public var onSelectIndex: ((Int?) -> Void)?

    public var selectedIndex: Int? {
        get { return suggestionView.selectedIndex }
        set { suggestionView.selectedIndex = newValue }
    }

    public var onDeleteEmptyInput: (() -> Void)?

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

    public var onPressOverflowMenu: ((NSRect) -> Void)?

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

    public var tokenText: String? {
        get { return suggestionView.tokenText }
        set { suggestionView.tokenText = newValue }
    }

    public var onChangeSuggestionText: ((String) -> Void)? {
        get { return suggestionView.onChangeSearchText }
        set { suggestionView.onChangeSearchText = newValue }
    }

    public var showsSearchBar: Bool {
        get { return style.showsSearchBar }
        set { style.showsSearchBar = newValue }
    }

    public var acceptsKeyboardInputWithHiddenSearchBar: Bool = true {
        didSet {
            updateProxySearchField()
        }
    }

    private func updateProxySearchField() {
        if !showsSearchBar && acceptsKeyboardInputWithHiddenSearchBar {
            contentView?.addSubview(proxySearchField)

            proxySearchField.onPressDownKey = { [unowned self] in
                self.suggestionView.searchInput.onPressDownKey?()
            }

            proxySearchField.onPressUpKey = { [unowned self] in
                self.suggestionView.searchInput.onPressUpKey?()
            }

            proxySearchField.onSubmit = { [unowned self] in
                self.suggestionView.searchInput.onSubmit?()
            }

            proxySearchField.onPressEscape = { [unowned self] in
                self.suggestionView.searchInput.onPressEscape?()
            }

            proxySearchField.onPressTab = { [unowned self] in
                self.suggestionView.searchInput.onPressTab?()
            }

            proxySearchField.onPressShiftTab = { [unowned self] in
                self.suggestionView.searchInput.onPressShiftTab?()
            }

            proxySearchField.onPressDeleteField = { [unowned self] in
                self.suggestionView.searchInput.onPressDeleteField?()
            }
        } else {
            proxySearchField.removeFromSuperview()
        }
    }

    public var showsSuggestionDetails: Bool {
        get { return style.showsSuggestionDetails }
        set { style.showsSuggestionDetails = newValue }
    }

    public var showsSuggestionList: Bool {
        get { return style.showsSuggestionList }
        set { style.showsSuggestionList = newValue }
    }

    public var showsSuggestionArea: Bool {
        get { return suggestionView.showsSuggestionArea }
        set { suggestionView.showsSuggestionArea = newValue }
    }

    public var showsOverflowMenu: Bool {
        get { return suggestionView.showsOverflowMenu }
        set { suggestionView.showsOverflowMenu = newValue }
    }

    // MARK: Filter bar

    public var suggestionFilter: SuggestionView.SuggestionFilter {
        get { return suggestionView.suggestionFilter }
        set { suggestionView.suggestionFilter = newValue }
    }

    public var onChangeSuggestionFilter: ((SuggestionView.SuggestionFilter) -> Void)?

    public var showsFilterBar: Bool {
        get { return style.showsFilterBar }
        set { style.showsFilterBar = newValue }
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
        return showsSearchBar || acceptsKeyboardInputWithHiddenSearchBar
    }

    public func focusSearchField() {
        makeKey()
        makeFirstResponder(showsSearchBar ? suggestionView.searchInput : proxySearchField)

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
            style.suggestionListWidth = defaultContentViewSize.width
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
            style.suggestionListWidth = defaultContentViewSize.width
        }

        setContentSize(contentRect.size)
        setFrameOrigin(contentRect.origin)
    }

    public var defaultContentViewSize: CGSize {
        return defaultContentSize
    }

    public var defaultWindowSize: CGSize {
        return CGSize(
            width: defaultContentSize.width + SuggestionWindow.shadowViewMargin * 2,
            height: defaultContentSize.height + SuggestionWindow.shadowViewMargin * 2)
    }

    private static var shadowViewMargin: CGFloat = 12

    // MARK: Overrides

    // If an overlay window becomes main, the previous main window will lose focus. When this happen,
    // the toolbar looks inactive visually, which may not be what we want. However, if an overlay window
    // can't become main, we have no way of knowing when it becomes hidden
//    public override var canBecomeMain: Bool {
//        return true
//    }

    public override var canBecomeKey: Bool {
        return showsSearchBar || acceptsKeyboardInputWithHiddenSearchBar
    }

    // Offset the origin to account for the shadow view's margin
    public override func setFrameOrigin(_ point: NSPoint) {
        let offsetOrigin = NSPoint(x: point.x - SuggestionWindow.shadowViewMargin, y: point.y - SuggestionWindow.shadowViewMargin)
        super.setFrameOrigin(offsetOrigin)
    }

    private var _isMovableByWindowBackground: Bool = false

    public override var isMovableByWindowBackground: Bool {
        get { return _isMovableByWindowBackground }
        set { _isMovableByWindowBackground = newValue }
    }
}
