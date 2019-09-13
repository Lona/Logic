//
//  BlockListView.swift
//  Logic
//
//  Created by Devin Abbott on 9/12/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import AppKit

private extension NSTableColumn {
    convenience init(
        title: String,
        resizingMask: ResizingOptions = .autoresizingMask,
        width: CGFloat? = nil,
        minWidth: CGFloat? = nil,
        maxWidth: CGFloat? = nil) {
        self.init(identifier: NSUserInterfaceItemIdentifier(rawValue: title))
        self.title = title
        self.resizingMask = resizingMask

        if let width = width {
            self.width = width
        }

        if let minWidth = minWidth {
            self.minWidth = minWidth
        }

        if let maxWidth = maxWidth {
            self.maxWidth = maxWidth
        }
    }
}

// MARK: - BlockListView

public class BlockListView: NSBox {

    // MARK: Lifecycle

    public init() {
        super.init(frame: .zero)

        setUpViews()
        setUpConstraints()

        update()

        addTrackingArea(trackingArea)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setUpViews()
        setUpConstraints()

        update()

        addTrackingArea(trackingArea)
    }

    private lazy var trackingArea = NSTrackingArea(
        rect: self.frame,
        options: [.mouseEnteredAndExited, .activeInActiveApp, .mouseMoved, .inVisibleRect],
        owner: self)

    deinit {
        removeTrackingArea(trackingArea)
    }

    // MARK: Public

    private func showToolTip(string: String, at point: NSPoint) {
        guard let window = window else { return }
        let windowPoint = convert(point, to: nil)
        let screenPoint = window.convertPoint(toScreen: windowPoint)

        if window.isKeyWindow {
            TooltipManager.shared.showTooltip(string: string, point: screenPoint, delay: .milliseconds(120))
        }
    }

    public var plusButtonTooltip: String = "**Click** _to add below_"
    public var moreButtonTooltip: String = "**Drag** _to move_\n**Click** _to open menu_"

    public override func mouseMoved(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        let row = tableView.row(at: .init(x: 60, y: convert(point, from: tableView).y))

        if row >= 0 {
            hoveredLine = row
        } else {
            hoveredLine = nil
        }

        if let hoveredLine = hoveredLine {
            let plusRect = plusButtonRect(for: hoveredLine)
            hoveredPlusButton = plusRect.contains(point)

            if hoveredPlusButton {
                showToolTip(
                    string: plusButtonTooltip,
                    at: NSPoint(x: plusRect.midX, y: plusRect.minY - 4)
                )
            }

            let moreRect = moreButtonRect(for: hoveredLine)
            hoveredMoreButton = moreRect.contains(point)

            if hoveredMoreButton {
                showToolTip(
                    string: moreButtonTooltip,
                    at: NSPoint(x: moreRect.midX, y: moreRect.minY - 4)
                )
            }
        } else {
            hoveredPlusButton = false
            hoveredMoreButton = false
        }

        if !hoveredPlusButton && !hoveredMoreButton {
            TooltipManager.shared.hideTooltip()
        }
    }

    public override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)

        if let hoveredLine = hoveredLine {
            if plusButtonRect(for: hoveredLine).contains(point) {
                var clone = blocks
                clone.insert(.init(.text(.init())), at: hoveredLine + 1)
                onChangeBlocks?(clone)
            }

            if moreButtonRect(for: hoveredLine).contains(point) {
                Swift.print("Clicked more")
            }
        }
    }

    public var blocks: [BlockEditor.Block] = [] {
        didSet {
            update()
        }
    }

    public var onChangeBlocks: (([BlockEditor.Block]) -> Void)?

    public var selectedIndex: Int? {
        didSet {
            if let selectedIndex = selectedIndex {
                tableView.selectRowIndexes(IndexSet(integer: selectedIndex), byExtendingSelection: false)

                // Check that the view is currently visible, otherwise it will scroll to the bottom
                if visibleRect != .zero {
                    tableView.scrollRowToVisible(selectedIndex)
                }

                var reloadIndexSet = IndexSet(integer: selectedIndex)

                if let oldValue = oldValue {
                    reloadIndexSet.insert(oldValue)
                }

                tableView.reloadData(forRowIndexes: reloadIndexSet, columnIndexes: IndexSet(integer: 0))
            } else {
                tableView.selectRowIndexes(IndexSet(), byExtendingSelection: false)
            }
        }
    }

    public var onSelectIndex: ((Int?) -> Void)?
    public var onActivateIndex: ((Int) -> Void)?

    // MARK: Private

    private var tableView = BlockListTableView()
    private let scrollView = NSScrollView()
    private let tableColumn = NSTableColumn(title: "Suggestions", minWidth: 100)

    private var hoveredLine: Int? {
        didSet {
            if oldValue != hoveredLine {
                needsDisplay = true
//                if let row = hoveredLine {
//                    toolbarView.isHidden = false
//
//                    let rect = convert(tableView.rect(ofRow: row), from: tableView)
//                    toolbarView.frame.origin = .init(x: 20, y: rect.minY)
//                } else {
//                    toolbarView.isHidden = true
//                }
            }
        }
    }

    private func setUpViews() {
        boxType = .custom
        borderType = .noBorder
        contentViewMargins = .zero
        fillColor = Colors.suggestionListBackground

        tableView.usesAutomaticRowHeights = true
        tableView.addTableColumn(tableColumn)
        tableView.intercellSpacing = NSSize.zero
        tableView.headerView = nil
        tableView.dataSource = self
        tableView.delegate = self
        tableView.target = self
        tableView.backgroundColor = .clear
        tableView.selectionHighlightStyle = .none

        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        scrollView.documentView = tableView

        scrollView.automaticallyAdjustsContentInsets = false
        scrollView.contentInsets = .init(top: 20, left: 60, bottom: 20, right: 60)
        scrollView.scrollerInsets = .init(top: -20, left: -60, bottom: -20, right: -60)

        addSubview(scrollView)

        tableView.reloadData()
        tableView.sizeToFit()

        tableView.intercellSpacing = .init(width: 0, height: 6)
    }

    private func setUpConstraints() {
        translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        scrollView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
    }

    private func update() {
        blocks.forEach { block in
            block.updateView()
        }

//        tableView.reloadData()
        tableView.sizeToFit()
    }

    override public var acceptsFirstResponder: Bool {
        return false
    }

    public override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        if let hoveredLine = hoveredLine {
            let rect = plusButtonRect(for: hoveredLine)
            let backgroundPath = NSBezierPath(roundedRect: rect, xRadius: 4, yRadius: 4)

            if hoveredPlusButton {
                Colors.divider.set()
                backgroundPath.fill()
            }

            let path = NSBezierPath(plusWithin: rect, lineWidth: 1, margin: .init(width: 3, height: 3))
            Colors.textComment.setStroke()
            path.stroke()
        }

        if let hoveredLine = hoveredLine {
            let rect = moreButtonRect(for: hoveredLine)
            let backgroundPath = NSBezierPath(roundedRect: rect, xRadius: 4, yRadius: 4)

            if hoveredMoreButton {
                Colors.divider.set()
                backgroundPath.fill()
            }

            let path = NSBezierPath(hamburgerWithin: rect, thickness: 1, margin: .init(width: 4, height: 5))
            Colors.textComment.setStroke()
            path.stroke()
        }
    }

    public let lineButtonSize = NSSize(width: 19, height: 19)
    public let lineButtonMargin: CGFloat = 2

    private var hoveredPlusButton: Bool = false {
        didSet {
            if oldValue != hoveredPlusButton {
                needsDisplay = true
//                update()
            }
        }
    }

    private var hoveredMoreButton: Bool = false {
        didSet {
            if oldValue != hoveredMoreButton {
                needsDisplay = true
//                update()
            }
        }
    }

    private func plusButtonRect(for line: Int) -> CGRect {
        let rowRect = convert(tableView.rect(ofRow: line), from: tableView)

        let rect = NSRect(
            x: 60 - lineButtonSize.width - lineButtonMargin,
            y: rowRect.minY + 5,
            width: lineButtonSize.width,
            height: lineButtonSize.height)

        return rect
    }

    private func moreButtonRect(for line: Int) -> CGRect {
        let rowRect = convert(tableView.rect(ofRow: line), from: tableView)

        let rect = NSRect(
            x: 60 - lineButtonSize.width * 2 - lineButtonMargin * 2,
            y: rowRect.minY + 5,
            width: lineButtonSize.width,
            height: lineButtonSize.height)

        return rect
    }
}

// MARK: - Delegate

extension BlockListView: NSTableViewDelegate {
    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let item = blocks[row]

        switch item.content {
        case .text(let value):
            let view = item.view as! InlineBlockEditor
            view.textValue = value
            view.onChangeTextValue = { [unowned self] newValue in

                self.blocks[row] = .init(id: item.id, content: .text(newValue))

//                view.textValue = newValue
//                self.tableView.noteHeightOfRows(withIndexesChanged: .init(integer: row))
            }
            return view
        }
    }
}

// MARK: - Data source

extension BlockListView: NSTableViewDataSource {
    public func numberOfRows(in tableView: NSTableView) -> Int {
        return blocks.count
    }

    //    public func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
    //        return items[row].height
    //    }
}

// MARK: - BlockListTableView

class BlockListTableView: NSTableView {
    override var acceptsFirstResponder: Bool {
        return false
    }

    // Allows clicking into NSTextFields directly (otherwise the NSTableView captures the first click)
    override func validateProposedFirstResponder(_ responder: NSResponder, for event: NSEvent?) -> Bool {
        return true
    }
}
