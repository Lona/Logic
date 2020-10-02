//
//  EditableBlockView.swift
//  Logic
//
//  Created by Devin Abbott on 10/2/20.
//  Copyright © 2020 BitDisco, Inc. All rights reserved.
//

import AppKit

// MARK: - EditableBlockView

public class EditableBlockView: NSView {

    public override var isFlipped: Bool {
        return true
    }

    // MARK: Lifecycle

    public init() {
        super.init(frame: .zero)

        setUpViews()
        setUpConstraints()

        update()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setUpViews()
        setUpConstraints()

        update()
    }

    // MARK: Public

    public var bottomMargin: CGFloat = 0 {
        didSet {
            bottomAnchorConstraint?.constant = -bottomMargin
        }
    }

    public var lineButtonAlignmentHeight: CGFloat = 0 {
        didSet {
            if lineButtonAlignmentHeight != oldValue {
                update()
            }
        }
    }

    public var listDepth: EditableBlockListDepth = .none {
        didSet {
            if listDepth != oldValue {
                update()
            }
        }
    }

    private var leadingMargin: CGFloat = 0 {
        didSet {
            leadingAnchorConstraint?.constant = leadingMargin
            invalidateIntrinsicContentSize()
        }
    }

    public var listItemView: NSView?

    public var contentView: NSView? {
        didSet {
            if contentView == oldValue { return }

            oldValue?.removeFromSuperview()

            if let contentView = contentView {
                overflowMenuContainer.innerContentView = contentView
            }
        }
    }

    public var onOpenOverflowMenu: (() -> Void)?

    public var overflowMenu: (() -> [SuggestionListItem])?

    public var onActivateOverflowMenuItem: ((Int) -> Void)?

    public var onDeleteBlock: (() -> Void)?

    public var overflowMenuButton: OverflowMenuButton {
        return overflowMenuContainer.overflowMenuButton
    }

    public func showOverflowMenu(at screenRect: NSRect) {
        guard let window = self.window else { return }

        let contextMenu = EditableBlockView.contextMenu

        let adjustedRect = NSRect(
            x: screenRect.midX - contextMenu.defaultContentWidth / 2,
            y: screenRect.maxY,
            width: 0,
            height: 0
        )

        contextMenu.suggestionText = ""
        contextMenu.suggestionItems = self.overflowMenu?() ?? []
        contextMenu.onSelectIndex = { index in
            contextMenu.selectedIndex = index
        }
        contextMenu.onChangeSuggestionText = { text in
            let menu = self.overflowMenu?() ?? []
            contextMenu.suggestionText = text
            contextMenu.suggestionItems = menu.filter { text.isEmpty || $0.title.lowercased().contains(text.lowercased()) }
        }
        contextMenu.onSubmit = { [unowned self] index in
            contextMenu.orderOut(nil)
            self.onActivateOverflowMenuItem?(index)
        }
        contextMenu.onDeleteEmptyInput = { [unowned self] in
            contextMenu.orderOut(nil)
            self.onDeleteBlock?()
        }

        window.addChildWindow(contextMenu, ordered: .above)

        contextMenu.anchorTo(rect: adjustedRect, verticalOffset: -10)
        contextMenu.focusSearchField()

        self.onOpenOverflowMenu?()
    }

    // MARK: Private

    private let overflowMenuContainer = OverflowMenuContainer()

    private var bottomAnchorConstraint: NSLayoutConstraint?

    private var leadingAnchorConstraint: NSLayoutConstraint?

    private func setUpViews() {
        addSubview(overflowMenuContainer)

        overflowMenuContainer.onPressButton = { [unowned self] in
            guard let window = self.window else { return }

            let clickedView = self.overflowMenuContainer.overflowMenuButton
            let windowRect = self.overflowMenuContainer.convert(clickedView.frame, to: nil)
            let screenRect = window.convertToScreen(windowRect)

            self.showOverflowMenu(at: screenRect)
        }

    }

    private func setUpConstraints() {
        translatesAutoresizingMaskIntoConstraints = false
        overflowMenuContainer.translatesAutoresizingMaskIntoConstraints = false

        overflowMenuContainer.topAnchor.constraint(equalTo: topAnchor).isActive = true
        overflowMenuContainer.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true

        bottomAnchorConstraint = overflowMenuContainer.bottomAnchor.constraint(equalTo: bottomAnchor)
        bottomAnchorConstraint?.isActive = true

        leadingAnchorConstraint = overflowMenuContainer.leadingAnchor.constraint(equalTo: leadingAnchor)
        leadingAnchorConstraint?.isActive = true
    }

    private func update() {
        leadingMargin = listDepth.margin

        listItemView?.removeFromSuperview()

        switch listDepth {
        case .indented:
            break
        case .unordered:
            let bulletSize: CGFloat = 6
            let bulletRect: NSRect = .init(
                x: floor(listDepth.margin - EditableBlockListDepth.indentWidth + 6),
                y: floor((lineButtonAlignmentHeight - bulletSize) / 2) + 2,
                width: bulletSize,
                height: bulletSize
            )

            let bulletView = NSBox(frame: bulletRect)
            bulletView.boxType = .custom
            bulletView.fillColor = NSColor.textColor.withAlphaComponent(0.8)
            bulletView.borderType = .noBorder
            bulletView.cornerRadius = bulletSize / 2
            addSubview(bulletView)

            listItemView = bulletView
        case .ordered(_, let index):
            let bulletSize: CGFloat = 14
            let bulletRect: NSRect = .init(
                x: floor(listDepth.margin - EditableBlockListDepth.indentWidth + 3),
                y: floor((lineButtonAlignmentHeight - bulletSize) / 2) + 2,
                width: EditableBlockListDepth.indentWidth,
                height: bulletSize
            )
            let string = String(describing: index) + "."
            let attributedString = TextStyle(weight: .bold, color: NSColor.textColor.withAlphaComponent(0.8)).apply(to: string)
            let bulletView = NSTextField(labelWithAttributedString: attributedString)
            bulletView.frame.origin = bulletRect.origin
            addSubview(bulletView)

            listItemView = bulletView
        }
    }

    public override var intrinsicContentSize: NSSize {
        guard let contentView = contentView else { return super.intrinsicContentSize }

        let contentSize = contentView.intrinsicContentSize

        return .init(width: contentSize.width + leadingMargin, height: contentSize.height + bottomMargin)
    }

    public override func invalidateIntrinsicContentSize() {
        contentView?.invalidateIntrinsicContentSize()

        super.invalidateIntrinsicContentSize()
    }
}

// MARK: - Context Menu

extension EditableBlockView {

    public static var contextMenu: SuggestionWindow = {
        let suggestionWindow = SuggestionWindow()

        suggestionWindow.showsSearchBar = true
        suggestionWindow.showsSuggestionDetails = false
        suggestionWindow.defaultContentWidth = 236
        suggestionWindow.placeholderText = "Filter actions..."

        suggestionWindow.onRequestHide = {
            suggestionWindow.orderOut(nil)
        }

        suggestionWindow.onPressEscapeKey = {
            suggestionWindow.orderOut(nil)
        }

        return suggestionWindow
    }()
}
